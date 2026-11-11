# ─────────────────────────────────────────────────────────────
# Arman VPN Core — Docker 镜像
# 官方没有 Docker 支持，这里把官方预编译二进制装进容器。
# 需要的权限：NET_ADMIN + /dev/net/tun（VPN 隧道用）
# ─────────────────────────────────────────────────────────────

FROM debian:bookworm-slim

# 版本和架构（build 时可覆盖）
ARG VERSION=1.0.18
# amd64 | arm64 | armv7
ARG ARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive

# 装最小依赖：ca-certificates（HTTPS 下载）、curl（健康检查）、iproute2（TUN 设备）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iproute2 \
        && \
    rm -rf /var/lib/apt/lists/*

# 下载官方预编译 core 二进制
# tar 包结构：arman-vpn-core-linux-amd64/arman-vpn-core
RUN mkdir -p /opt/arman-vpn/user-data && \
    curl -fsSL -o /tmp/core.tar.gz \
        "https://github.com/armanlife/arman-vpn-client/releases/download/v${VERSION}/arman-vpn-core-${VERSION}-linux-${ARCH}.tar.gz" && \
    tar xzf /tmp/core.tar.gz -C /tmp/ && \
    cp /tmp/arman-vpn-core-linux-${ARCH}/arman-vpn-core /opt/arman-vpn/arman-vpn-core && \
    chmod +x /opt/arman-vpn/arman-vpn-core && \
    rm -rf /tmp/*

# 入口脚本
COPY entrypoint.sh /opt/arman-vpn/entrypoint.sh
RUN chmod +x /opt/arman-vpn/entrypoint.sh

# 面板 10820，代理 SOCKS5/HTTP 10810
EXPOSE 10820 10810

# 数据持久化
VOLUME ["/opt/arman-vpn/user-data"]

WORKDIR /opt/arman-vpn

ENTRYPOINT ["/opt/arman-vpn/entrypoint.sh"]
