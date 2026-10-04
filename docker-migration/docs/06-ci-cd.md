# 06 · CI/CD：GitHub Actions 自动化与发布回滚

> 承接 `03-build-and-push.md` 与 `04-deploy.md`：把手动的「本地 build-push.sh + 服务器 deploy-server.sh」
> 升级成「**push 即校验、打 tag 即发布、一键回滚**」。
>
> 完整工作流见 `examples/ci.yml`、`examples/cd.yml`、`examples/remote-deploy.sh`。

## 1. 流水线总览

```
                ┌── push / PR → main ──────────────▶ CI    ：后端 mvn verify + 前端 typecheck&build（质量门禁）
GitHub ─────────┤
                ├── push tag v* ──────────────────▶ CD·build-push ：构建 → 推镜像(:svc + :svc-<tag>) → 部署 → 冒烟
                │
                └── 手动 dispatch + version ───────▶ CD·promote    ：把 :svc-<ver> 提升为 :svc → 部署 → 冒烟（回滚/定点发布）
                                                                     │
                                                  受限 SSH（forced command）│
                                                                     ▼
                                                          服务器：compose pull && up -d
```

| 触发 | 做什么 | 需要哪些 Secret |
|---|---|---|
| `push` / `pull_request` → main | **CI**：跑测试与构建，不部署 | 无 |
| `push` tag `v*` | **CD**：构建推镜像 → 部署 → 冒烟 | 仓库凭据 + 部署 SSH |
| 手动 Run workflow + `version` | **CD**：把指定版本重新提升为当前 tag → 部署 → 冒烟 | 同上 |

> **建议分步上线**：先只做 CI（零凭据、零风险，立刻拿到"编译/类型错误在提交阶段暴露"），
> 稳定后再加 CD；回滚能力随 CD 一起来。

## 2. CI：先把门禁立起来

要点（片段见 `examples/ci.yml`）：

- **不需要 mvn wrapper**：`actions/setup-java` 自带 `mvn`；`cache: maven` 会自动匹配 `**/pom.xml`，子目录工程也能缓存。
- **前端缓存要显式指路**：`cache: npm` + `cache-dependency-path: <前端目录>/package-lock.json`。
- **子目录工程**用 `defaults.run.working-directory`，避免每个 `run` 都 `cd`。
- `permissions: contents: read`（最小权限）+ `concurrency` 取消冗余运行。
- 构建命令别用「本地一键脚本」：脚本里的交互式 `docker login` / 提示会**在 CI 里卡死**（见 05 #12 一类问题）；
  CI 里每条命令都写成非交互形式（`docker login --password-stdin`）。

## 3. CD：打 tag 即发布

### 3.1 构建与推送

- 必带 `--provenance=false --sbom=false`，否则私有仓库拒收 attestation（05 #1）。
- **同时推两个 tag**：
  - 可变「当前」tag（`:backend` / `:frontend`）——服务器 `compose pull` 认它；
  - 不可变「版本」tag（`:backend-v1.2.3`，取自 `github.ref_name`）——**这是回滚的凭据**。
- 推送前先 `docker login --username=<user> --password-stdin <registry>`（非交互）。

### 3.2 部署

- **用系统 `ssh` 即可**，不必引第三方 action：少一层供应链风险，也避开第三方 action 对 pty / sftp 的行为要求。
- SSH 私钥用 **base64** 存 Secret（见 §4）。
- 服务器侧只跑一个**受限入口脚本**（见 §5），CI 传的命令会被 forced command 忽略。
- **冒烟**：重试若干次**业务接口**（返回 200），不要只 `curl -I` 首页——首页 200 不代表后端/DB 正常。

## 4. 密钥怎么放：base64，别放多行 PEM

- **现象**：Actions 里 `ssh -i key` 报 `Load key "…": error in libcrypto` + `Permission denied (publickey)`。
- **根因**：多行 PEM 经编辑器 / 复制粘贴后**换行被删或结构被改**，`ssh` 解析失败。
- **修复**：Secret 存**单行 base64**，workflow 里解码并立刻校验：

```bash
printf '%s' "$DEPLOY_SSH_KEY_B64" | base64 -d > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key
ssh-keygen -lf ~/.ssh/deploy_key          # 打印指纹，坏了一眼可见
```

生成：`base64 -w0 私钥文件`（macOS：`base64 -i 文件`）。
兜底：若坚持存 PEM，workflow 里 `printf '%s\n' "$KEY" | tr -d '\r' > key` 去掉 CRLF。

## 5. 受限 deploy key：把 CI 私钥的爆炸半径压到最小

CI 里放一把能登服务器的私钥，是整条链路**最大的风险点**。做法是给 CI **单独一把** key，并在服务器侧锁死它。

### 5.1 服务器：authorized_keys 加选项

```
command="/home/<user>/deploy/remote-deploy.sh",restrict ssh-ed25519 AAAA... gh-actions-deploy
```

- `command=`：**无论客户端请求什么命令，都只执行这一个脚本**（客户端命令只作为 `SSH_ORIGINAL_COMMAND` 提供，脚本可选择性使用）。
- `restrict`：一次禁掉 pty / 端口转发 / agent 转发 / X11 / user-rc（OpenSSH 7.2+）。
- 被指向的脚本**固定白名单、不接受任意参数**，内部只调 `sudo -n <绝对路径命令>`。

### 5.2 sudo：只授权两条、参数逐字一致

```sudoers
<user> ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env pull
<user> ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env up -d
```

⚠️ **sudo 对命令参数做字面字符串比对，不做路径归一化**：
脚本里若写 `-f docker-compose.prod.yml`（相对），与上面登记的 `-f /opt/myapp/docker-compose.prod.yml`（绝对）
**不匹配** → `sudo -n` 报 `a password is required`，且极难察觉。**脚本里一律写绝对路径**。
（sudoers 里**不要用 `*` 通配**，可被参数注入绕过。）

### 5.3 验证是否真的锁住了

```bash
ssh -i <key> <user>@<host> id     # 若不回 uid、而是执行了部署脚本 → command= 生效
```

### 5.4 两个别踩的坑

- `from="IP"` 白名单对 **GitHub 托管 runner 无效**（出口 IP 动态）；
- **公开仓库严禁 self-hosted runner**（fork PR 可执行任意代码 = 把服务器交出去）。

## 6. 发布回滚：为什么放在 CI 侧

**做法**：手动触发 CD，输入 `version`；`promote` job 在 CI 上（有仓库凭据）把
`:backend-<ver>` / `:frontend-<ver>` 重新 `pull → tag → push` 成 `:backend` / `:frontend`，再触发服务器 `pull + up -d`。

**为什么不让服务器自己改 `.env` 里的镜像 tag 来选版本？**——因为那等于给运维账号「指定任意镜像」的能力，
配上 NOPASSWD 的 `compose up -d`，就是一条**免密提权到 root** 的路子。回滚选版本这件事放到 CI 侧做，
服务器仍然只认一个固定的 `.env`，**权限面不扩大**：

| 方案 | 服务器权限需求 | 风险 |
|---|---|---|
| 服务器改 `.env` 选镜像 tag | `<user>` 需可写 `.env`（含密钥文件） | ⚠️ 可指定任意镜像 → 免密提权到 root |
| **CI 侧 promote 版本镜像（本手册）** | 服务器**零权限变更** | 版本选择被限制在"仓库里已存在的 tag" |

> 注意 `promote` 会让「当前」tag 指回旧构建——这是有意的：`:svc` 表示**当前部署的那一版**，
> `:svc-<ver>` 是不可变历史。正常发版时打新 tag 会自动把 `:svc` 指回最新。

## 7. 运维 Runbook

```bash
# 正常发版
git tag v1.2.3 && git push origin v1.2.3          # 触发 CD：构建 → 推镜像 → 部署 → 冒烟

# 回滚 / 定点发布
# GitHub → Actions → CD → Run workflow → version: v1.2.2

# 看当前部署版本
grep -E '^(BACKEND|FRONTEND)_IMAGE=' /opt/myapp/.env

# 查状态 / 日志
sudo docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env ps
sudo docker compose -f /opt/myapp/docker-compose.prod.yml --env-file /opt/myapp/.env logs -f --tail=100
```

## 8. 本章坑位

| # | 现象 | 根因 | 修复 |
|---|---|---|---|
| 1 | `sudo -n` 报 `a password is required` | sudoers 参数**逐字**比对，脚本用了相对路径 | 脚本内与 sudoers 全部用**绝对路径**；`sudo -n -l` 核对 |
| 2 | `Load key: error in libcrypto` | 多行 PEM 被粘贴/编辑器改坏 | Secret 存 **base64**，workflow 里 `base64 -d` + `ssh-keygen -lf` 自检 |
| 3 | 查 Actions 报 `403 rate limit exceeded` | **匿名** GitHub API 限流 60/小时，高频轮询会打满 | 轮询间隔 ≥60s，或用 `GITHUB_TOKEN`（5000/h） |
| 4 | 想看 job 日志却 403 | public 仓库的 **job 日志 API 仍需鉴权** | 网页登录查看，或用 token |
| 5 | 给运维账号开了配置写权限 | 「能改镜像引用 + NOPASSWD compose up」= 免密提权 | 版本选择放 CI 侧，服务器不放开写权限（§6） |

## 9. 安全清单

- [ ] deploy key **独立**（专用于 CI），不复用个人/运维密钥；
- [ ] `authorized_keys` 该条目带 `command=` + `restrict`；
- [ ] sudoers 仅两条精确规则、**无通配符**；
- [ ] 私钥**只存 CI Secret**（base64），服务器上不落地；轮换后有删除旧公钥的流程；
- [ ] 所有 Secret 走仓库/环境 Secret，**绝不写进 workflow 文件**；
- [ ] CD 使用 `environment:`，必要时加「人工批准」保护规则；
- [ ] 定期轮换 deploy key 与仓库密码。
