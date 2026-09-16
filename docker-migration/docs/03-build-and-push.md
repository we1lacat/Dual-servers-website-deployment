# 03 · 构建与推送：私有镜像仓库交付链路

> 原则：**不在目标服务器上构建**。开发机（或 CI）build → tag → push，服务器 pull → up。
> 完整脚本见 `examples/build-push.sh`。极大减小服务器构建阶段开销

## 1. 镜像命名规则

```
[registry]/[namespace]/[repo]:[tag]
```

- **registry**：私有仓库地址。阿里云 ACR 个人版形如 `crpi-xxxxxxxx.cn-hangzhou.personal.cr.aliyuncs.com`；自建 Harbor / Docker Hub / GHCR 同理；
- **同一仓库、多个 tag 区分服务**：小项目不必为 backend / frontend 建两个仓库，用 tag 区分即可：

```
<registry>/<ns>/myapp:backend
<registry>/<ns>/myapp:frontend
```

## 2. push  tag

`docker push` 推的是 **tag 里的全名**，不是 `build -t` 的本地名。本地名不带仓库前缀直接 push 必失败：

```bash
docker build -t myapp-backend:local -f backend/Dockerfile backend/
docker tag myapp-backend:local ${REGISTRY}/${NS}/myapp:backend
docker push ${REGISTRY}/${NS}/myapp:backend
```

> tag 只是多一个引用，不占额外空间；同一镜像可按需多打 `:latest`、`:v1.2` 等多个 tag。

## 3. 一键构建推送脚本

见 `examples/build-push.sh`，核心流程：

```
[1/4] docker login（已登录则跳过：检查 ~/.docker/config.json 里有无该 registry）
[2/4] build backend（多阶段 maven，耗时较长）
[3/4] build frontend（node 出 dist 烘焙进 nginx）
[4/4] tag + push 两个镜像
```

两个工程细节：

```bash
# ① 关闭 BuildKit 默认的 provenance/SBOM 证明清单（部分私有仓库不认，见 pitfalls #1）
export BUILDX_NO_DEFAULT_ATTESTATIONS=1
docker build --provenance=false --sbom=false ...

# ② 凭据只在本机 docker login 输入，脚本里不出现任何密码
```

## 4. 登录与凭据

```bash
docker login --username=<registry-user> <registry>
# 密码建议用 Access Token，而不是账号登录密码
```

- 云厂商仓库的「镜像仓库密码」是**开通服务时单独设置的**，不是云账号登录密码；
- 登录态存在本机 `~/.docker/config.json`，脚本复用，密码不进任何文件 / 聊天记录 / 提交历史；
- 公有云仓库推公开 Docker Hub 上的镜像**默认公开**，含内网地址 / 敏感配置的一律走私有仓库。

## 5. 网络注意事项（开发机侧）

- 拉基础镜像 / 依赖走系统代理时，TUN 模式（全局接管）下容器流量自动走代理，Docker 内无需单独配置；
- 若用 HTTP 代理环境变量方式，注意 `docker build` 阶段的 RUN 需要能到达 Maven / npm 源。

## 6. 推送完成的自查

```bash
docker push ${REGISTRY}/${NS}/myapp:backend    # 输出 digest 即成功
# 服务器侧拉取验证（先登录，见 pitfalls #4 的凭据作用域）：
docker pull ${REGISTRY}/${NS}/myapp:backend
```

> 服务器侧 `pull access denied` 大概率不是权限问题，而是 **sudo 凭据作用域**——见 pitfalls #4。
