# Arman VPN — Docker 部署

> 官方项目不提供 Docker 支持。这是根据官方预编译二进制和 systemd 安装脚本，
> 自行封装的 Docker 方案。

## 文件说明

| 文件 | 作用 |
|---|---|
| `Dockerfile` | 基于 debian:bookworm-slim，下载官方 core 二进制 |
| `entrypoint.sh` | 首次启动自动初始化面板，之后直接跑代理 |
| `docker-compose.yml` | 编排文件，配置权限/网络/持久化 |

## 快速开始

```bash
# 1. 进入项目目录
cd arman-vpn-docker

# 2. 构建并启动
docker compose up -d --build

# 3. 看初始化日志（首次启动会打印面板用户名和密码）
docker compose logs -f
```

首次启动时，`entrypoint.sh` 会调用 `-setup-server` 自动：
- 把面板监听从 `127.0.0.1` 改为 `0.0.0.0`（容器外可访问）
- 生成面板登录用户名 + 随机密码
- 生成代理登录用户名 + 随机密码

**这些凭据会打印在 `docker compose logs` 的开头**，请记下来。

## 访问

| 服务 | 地址 |
|---|---|
| Web 管理面板 | `http://服务器IP:10820/app/` |
| SOCKS5 代理 | `服务器IP:10810` |
| HTTP 代理 | `服务器IP:10810` |

面板里可以：添加 Firefox 账号、选择服务器、测试延迟、查看日志、配置中继等。

## 网络模式：host

使用 `network_mode: host`，容器直接共享宿主机网络栈：

- 面板 10820、代理 10810 直接绑定宿主机端口，**不需要 ports 映射**
- VPN 隧道路由直接生效在宿主机上，不存在容器内外路由不通的问题
- 健康检查用 `127.0.0.1:10820` 即可访问面板

## 架构选择

默认 `amd64`。如果你是 ARM64 机器（Apple Silicon、树莓派 4/5 等）：

```yaml
# docker-compose.yml 里改一行
args:
  ARCH: arm64
```

## 必需的 Docker 权限

VPN 隧道需要操作内核 TUN 设备，所以容器必须：

```yaml
cap_add:
  - NET_ADMIN        # 创建/操作虚拟网卡
devices:
  - /dev/net/tun     # 透传 TUN 设备
```

**不需要 `--privileged`**，`NET_ADMIN` + `/dev/net/tun` 就够了。

## 数据持久化

账号、设置、登录态存在 Docker volume `arman-vpn-data` 里。
重建容器不会丢数据。要彻底清除：

```bash
docker compose down -v
```

## 常用操作

```bash
# 查看日志
docker compose logs -f

# 重启
docker compose restart

# 停止
docker compose down

# 更新到新版本（改 Dockerfile 里的 VERSION 后）
docker compose up -d --build

# 进容器手动操作（比如添加账号）
docker compose exec arman-vpn /opt/arman-vpn/arman-vpn-core -add-account -data-dir /opt/arman-vpn/user-data
```

## 注意事项

1. **TUN 设备**：宿主机内核必须支持 TUN（绝大多数 Linux 默认支持）。
   如果 `/dev/net/tun` 不存在：`sudo modprobe tun`

2. **防火墙**：确保宿主机放行 10820 和 10810 端口。

3. **451 错误**：如果连接时遇到 `HTTP 451: unavailable_in_region`，
   需要在面板里配置中继服务器（参考 Cloudflare Worker 中继部署文档）。

4. **host 模式下端口冲突**：如果宿主机已有服务占用 10820 或 10810，
   需要先停掉或改 Arman VPN 的监听端口（面板里可改）。
