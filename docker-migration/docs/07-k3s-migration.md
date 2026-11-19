# 07 · K3s 迁移：跨云三节点组网与后端上集群

> 承接 `06-ci-cd.md`：把 B 机上的后端容器从 Docker Compose 迁移进三节点 K3s 集群，
> 「GCP master + 两台阿里云 agent」跨云组网。
>
> **入口架构（方案 A）不变**：
>
> B 机的 nginx 容器继续做 TLS 终止与静态资源服务，
>  upstream 从 compose 内网切到 K8s Service 的 externalIP。
> 完整配置与脚本见本仓库 `examples/` 之外的运维侧资产（不公开）。

## 1. 背景与硬约束

| 约束 | 影响 |
|---|---|
| ICP 备案要求 A 记录指向 B 机、80/443 由 B 应答 | **B 的 nginx 容器必须保留**，EIP 不能换 |
| master  GCP（境外） | **业务流量不能落 master**，控制面 |
| 后端用 SQLite（WAL 模式） | 只能 **1 副本 + Recreate**，PVC 必须 RWO 且钉在 B 节点 |
| 2C2G * 2 + 2C4G | 内存预算紧张 |

## 2. 最终拓扑

```
                        ┌────────────────────────┐
  公网 :443/:80  ─────▶ │ B 机 we1l-nginx-1       │  ← compose 保留（备案入口）
                        │  (TLS + SPA + certbot)  │
                        └──────────┬─────────────┘
                                   │ proxy_pass → 10.10.0.1:8080
                        ┌──────────▼─────────────┐
                        │ Service we1l-backend    │  ClusterIP + externalIPs:[10.10.0.1]
                        │  externalIP 10.10.0.1   │  ← 与旧 compose 监听地址一致，
                        └──────────┬─────────────┘     Prometheus/nginx 零改动
                                   │
                        ┌──────────▼─────────────┐
                        │ Pod we1l-backend (B)    │  replicas:1 + Recreate
                        │ PVC → 静态 hostPath PV  │  nodeAffinity 钉 B
                        └────────────────────────┘

  WireGuard 网格（wg0, MTU 1420, /32 AllowedIPs, keepalive 25s）
    master 10.10.0.3 (GCP)  ←→  A 10.10.0.2  ←→  B 10.10.0.1
  flannel 改为 vxlan 跑在 wg0 上（flannel.1 MTU 1370）
```

## 3. 部署流程及复盘

*此迁移的80%工作量在「 agent 加入集群」。*

### 3.1 双 agent 无 server

**现象**：两台 agent 无限重试，`Waiting to retrieve agent configuration; server is not ready`。

**排查手法**（由表及里）：

1. `systemctl status k3s k3s-agent` —— A 反复重启（NRestarts=26），B 卡住不退 

     **表现不一致 = 不是同一个错**；

2. `ss -tn | grep 6443` 采样出站连接 —— 发现两台连的 master 是 GCP 公网 IP，TCP 正常 ESTAB；

     **排除安全组和连接问题**

3. `curl -k https://<master>:6443/ping` 返回 `pong`、`/readyz` 返回 401 —— master 健康、鉴权链路正常，**网络/TLS/URL 全部排除**，问题锁定在「连接后未被接纳」。

**教训**：先看进程行为差异，再采连接，最后才怀疑配置。避免盲目重装。

### 3.2 token 被截断 7 个字符

**现象**：B 报 `failed to retrieve configuration from server: not authorized`（401）。

**定位**：把 token 拆段核对 ——

```
K10<64位CA哈希>::server:<密码段>
```

- 从 master `/cacerts` 实时取 CA 算 SHA-256，与 token 前 64 位**完全一致** 

    **确认 token 来源正确**

- 但密码段只有 **25 位 hex**

    **正常应为 32 位，复制时错误截断 **

**修复**：从同集群机器（A） `k3s-agent.service.env` 里复制完整 token。

**教训**：`K10<sha256>::server:<hex>` 的长度固定（108），需要二次确认。

### 3.3 A 机 cgroup v1（Kubernetes ≥1.35 致命）

**现象**：A 的 agent 每 8 秒退出（exit 0），日志显示已取到配置/containerd 起来了， **kubelet 初始化失败**

**根因**：A 是 Alibaba Cloud Linux 3（al8），`/sys/fs/cgroup` 是 tmpfs（v1 混合态，13 个 v1 挂载）。
K8s 1.31 起 `failCgroupV1` 开关出现，**1.35 起默认 true** —— kubelet 在 v1 节点上直接拒绝启动。

**修复**（UEFI + BLS 引导，不能用 grub2-mkconfig，必须用 grubby）：

```bash
sudo cp -a /boot/loader/entries /root/bls-backup-$(date +%F)
sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1 cgroup_no_v1=all"
sudo grubby --info=ALL | grep -E "^kernel|^args"   # 必须先确认写进去了
sudo reboot
```

验收：`stat -fc %T /sys/fs/cgroup` = `cgroup2fs`；`mount | grep cgroup` 单行；
`cat /sys/fs/cgroup/cgroup.controllers` 含 cpu/io/memory；业务服务all active。

**tips**：

- `--kubelet-arg=fail-cgroupv1=false` 是短期绕过，不解决根本问题，且该开关后续版本移除。

### 3.4 VPN故障

**现象**：节点 join成功，跨节点 Pod 网络持续中断。

**根因**：master 的 node-ip 是 GCP 私网（10.140.x.x）；

​			A/B 默认取阿里云私网（172.x）；
​			三者互不可达，flannel 的 VXLAN 外层包丢失目标。

**修法**：master 加入 wg0（10.10.0.3）

​			统一 `--node-ip=10.10.0.x --flannel-iface=wg0`。
​			A/B 无固定 ListenPort（NAT 后随机端口），由它们主动拨号 + `PersistentKeepalive 25`，
​			master 侧固定 A/B   Endpoint（它们监听端口固定）。

**MTU 实测**： `ping -M do -s <n>` 逐步探测，1420 通过、1428 失败 → wg0 定 1420，
					   flannel vxlan 自动算出 1370，实测 1370 字节包通过、1378 失败，**无大包黑洞**。

**教训**：`ping` 通只证明 ICMP；要加 `-M do -s` 探确定MTU，否则 VXLAN 分片静默丢弃会让你怀疑人生。

### 3.5 flannel wireguard-native & wg0 端口冲突（ 51820）

**现象**：master 初始确定 `--flannel-backend=wireguard-native`|`flannel-wg` 固定 51820/udp。

**决策**：**两套 WireGuard 赘余**。flannel 退回 vxlan、运行在 wg0 上面：

```
pod → flannel.1 (VXLAN 8472) → wg0 (10.10.0.x) → 对端 wg0 → flannel.1 → pod
```

只有一层加密、无端口冲突、pod 网段不出内网。master 改单元参数：

```
--node-ip=10.10.0.3 --node-external-ip=<GCP公网IP> \
--tls-san=10.10.0.3 --tls-san=<GCP公网IP> \
--flannel-backend=vxlan --flannel-iface=wg0
```

**关键认知**：

​	`--flannel-backend` 是 **server 独有**参数

​	`--flannel-iface` 是 **agent 侧**参数
​	三台各自都要写 `--flannel-iface=wg0`

### 3.6 node-password secret 残留

**现象**：token 修复后 `invalid username/password combination`（注意和 3.2 的 401 **文案不同**）。

**根因**：k3s 的 node password 存在 Secret（`kube-system/node-password-<节点名>`），
			**删除 Node 对象 Secret保留**。agent 本地重新生成了密码，与残留 Secret 对不上。

**修复**：

```bash
kubectl -n kube-system delete secret node-password-<节点名>
# agent 侧清本地状态后重启
sudo systemctl stop k3s-agent && sudo rm -rf /var/lib/rancher/k3s/agent && sudo systemctl start k3s-agent
```

**教训**：两种 401 文案对应两个完全不同的阶段和修复路径

​			`			failed to retrieve configuration` 是 token 层
​			`			invalid username/password combination` 是节点注册层

### 3.7 节点名大小写敏感

**现象**：Pod   Pending，describe  无有用事件。

**根因**：manifest 里 nodeSelector / PV nodeAffinity 写了驼峰 `...4cZ`，
			实际节点名被 k3s 小写化为 `...4cz`。**K8s 标签值区分大小写**。

### 3.8 镜像源不可用

**现象**：Pod   ContainerCreating，事件中 `sandbox image` 拉取超时。

**修复**：agent 节点写 `/etc/rancher/k3s/registries.yaml`（**重启 k3s-agent 生效**）：

```yaml
mirrors:
  docker.io:
    endpoint:
      - "https://docker.m.daocloud.io"
      - "https://docker.1ms.run"
      - "https://docker.xuanyuan.me"
```

**镜像源甄别**：`curl -sI https://<mirror>/v2/` 返回 200 才可用； daocloud/1ms/xuanyuan 三家可用。

### 3.9 systemd ExecStart 多行替换

agent unit 的 `ExecStart` 是 `k3s \` + `agent \` + 若干参数续行。要收敛成单行，
**用 awk 吃续行**（无perl ）：

```bash
awk -v new="$NEW" '
  /^ExecStart=\/usr\/local\/bin\/k3s/ { print new; inblk=1; next }
  inblk==1 { if ($0 ~ /\\[[:space:]]*$/) next; inblk=0 }
  { print }
' unit > unit.new && install -m 644 -o root -g root unit.new unit
```

`sed` 逐行替换会留残余续行（第二行起裸参数，unit 无法拉起）。

## 4. 迁移落地

### 4.1 为什么弃用 local-path 动态供给

`local-path` 的 storageclass 是 **WaitForFirstConsumer**：PV 目录要等 Pod 调度后才创建。
但 SQLite 迁移必须「**先放数据、后起 Pod**」，否则后端会以空库启动并自动建表，产生脏数据。

改用**静态 PV**：`hostPath: /var/lib/rancher/k3s/storage/we1l-backend-data` + `nodeAffinity` 钉 B +
自定义 SC（`volumeBindingMode: Immediate`），PV/PVC 先 Bound，再把备份数据拷进去 `chown 987:987`
（容器内 uid/gid 与原 tomcat 属主对齐）。

### 4.2 Service externalIPs / NodePort

```yaml
spec:
  externalIPs: ["10.10.0.1"]   # 与旧 compose 监听地址完全一致
  ports: [{ port: 8080 }]
```

效果：Prometheus 抓取地址不改、nginx upstream 只改 scheme 内地址（`backend:8080` → `10.10.0.1:8080`）、
公网不可达（只绑 WireGuard 内网 IP）。

### 4.3 切流与回滚

- 切流：修改nginx conf 的 upstream → `docker exec nginx nginx -t` → `nginx -s reload`（**容器不重建，无证书风险**）；
- 旧容器 `docker compose stop backend` 保留，30 秒可回滚；
- 回滚脚本：恢复 upstream + `up -d backend` + `kubectl scale deploy --replicas=0`。

**顺序要点**：必须先停旧容器再起 Pod（逆序秒级 502），抢占 `10.10.0.1:8080`。

## 5. CD 

原链路 `ssh → forced command → remote-deploy.sh` 保留，只换脚本内部动作：

| 原动作 | 现动作 | 原因 |
|---|---|---|
| `compose pull && up -d`（backend+nginx） | `up -d --no-deps nginx` | `depends_on` 旧 backend 容器捆绑拉起，**抢回 8080** |
| — | `kubectl rollout restart/status deploy/we1l-backend` | backend 由 K8s 接管（`imagePullPolicy: Always`，restart 拉取新镜像） |

- 部署身份：专用 ServiceAccount（仅 ns 内 deployments/pods 的 get/list/watch/patch/update），
  kubeconfig 放 B 机 600 权限，**GitHub Secrets 零新增**；
- sudoers 同步收紧为两条精确规则（`pull nginx` + `up -d --no-deps nginx`），参数逐字匹配；
- 版本选择/回滚仍在 CI 侧（promote 不可变 tag），服务器不放开镜像引用写权限——同 06 §6 的原则。

## 7. 验证清单

- [x] `kubectl get nodes -o wide`：三台 Ready，INTERNAL-IP 全部 10.10.0.x
- [x] 三向 `ping 10.10.0.x` 0% 丢包；VXLAN 内层（VTEP 地址）互 ping 通
- [x] MTU 边界：1370 字节包过、1378 字节包拒
- [x] 站点 200（0.068s，比走 docker bridge 还快）、API 返回迁移前真实数据
- [x] 删 Pod 自愈 30s、PVC 数据不丢、WAL 正常重建
- [x] 模拟 CD 全流程两次通过（含 `--no-deps` 修复后）
- [x] `root@A/B` 均 `Permission denied (publickey)`，普通用户正常

## 8. 本章坑位汇总

| # | 现象 | 根因 | 修复 |
|---|---|---|---|
| 1 | agent 表现不一致（重启 vs 卡死） | 不同的错误（cgroup v1 / token 截断） | 分开修复 |
| 2 | `not authorized`（取配置阶段） | token 密码段被截断 7 字符 | 数位数（108）；从正常节点复制 |
| 3 | `invalid username/password combination` | node-password Secret 残留 | 清理 Secret +  agent 数据目录 |
| 4 | agent 8 秒退出、exit 0 | cgroup v1，K8s ≥1.35 拒绝启动 | grubby   `systemd.unified_cgroup_hierarchy=1 cgroup_no_v1=all` 重启 |
| 5 | 节点能 join  跨节点网络不通 | node-ip 分属不可达私网 | 全部接 wg0，统一 `--node-ip` + `--flannel-iface=wg0` |
| 6 | wg0 起不来 / flannel 无效 | flannel wireguard-native 锁死 51820 | flannel 退 vxlan， wg0 一层加密 |
| 7 | Pod Pending 无事件 | 节点名大小写不匹配 | 节点名统一 |
| 8 | sandbox 镜像拉取超时 | 国内拉不到 docker.io | `registries.yaml` 配镜像源 + 重启 agent |
| 9 | 部署后旧容器抢夺端口 | compose `depends_on` 连带启动 | `up -d --no-deps` |
| 10 | awk 去重无效 | CRLF 行尾 | 先 trim 行尾空白 |

## 9. 回滚

```bash
# 代码版本：GitHub Actions → CD → workflow_dispatch 填版本号（promote :backend 指向旧版）

# 整体退回 compose（B 机）
sudo bash <脚本目录>/rollback-b.sh
kubectl -n we1l scale deploy/we1l-backend --replicas=0
```

旧数据目录 `/opt/<app>/data` 与迁移前备份 `/opt/<app>/backup/pre-k8s-*` 均保留，
回滚保留数据。运行时权威数据在 PV 目录（`/var/lib/rancher/k3s/storage/we1l-backend-data`），
**目录脱离混用**。