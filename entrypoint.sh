#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Arman VPN Core 容器入口脚本
#
# 首次启动：用 -setup-server 生成面板登录并开放到 0.0.0.0
# 后续启动：直接跑代理服务
# ─────────────────────────────────────────────────────────────
set -euo pipefail

BIN="/opt/arman-vpn/arman-vpn-core"
DATA_DIR="/opt/arman-vpn/user-data"
CONFIG="$DATA_DIR/config.json"

# 面板用户名，可通过环境变量覆盖；默认 admin
PANEL_USER="${PANEL_USER:-admin}"

# ── 首次启动：没有 config.json 就初始化 ──
if [ ! -f "$CONFIG" ]; then
    echo "============================================"
    echo "  首次启动，正在初始化 Arman VPN..."
    echo "============================================"

    # -setup-server 会：
    #   1. 把面板监听从 127.0.0.1 改到 0.0.0.0（对外可访问）
    #   2. 设置面板登录用户名和随机密码
    #   3. 设置代理的随机用户名和密码
    #   4. 打印所有凭据到 stdout，然后退出
    "$BIN" -setup-server "$PANEL_USER" -data-dir "$DATA_DIR" -plain 2>&1 || true

    echo "============================================"
    echo "  初始化完成，启动代理服务..."
    echo "============================================"
fi

# ── 正常启动：运行代理 + Web 面板 ──
# -plain  : 日志打到 stdout（Docker logs 可见）
# -verbose: 可选，打开调试日志
exec "$BIN" -data-dir "$DATA_DIR" -plain ${VERBOSE:+-verbose}
