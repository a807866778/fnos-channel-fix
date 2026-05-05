#!/bin/bash
# ==============================================================
# 飞牛 OpenClaw 升级脚本下载工具
# ==============================================================
# 功能：下载 upgrade_openclaw.sh 到 /tmp 并执行
# 需要 root 权限执行
#
# 使用方法：
#   sudo -i
#   curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/install.sh | bash
#
# 或者分步：
#   sudo -i
#   curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/install.sh -o /tmp/install.sh
#   bash /tmp/install.sh
# ==============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

info()  { echo -e "${BLUE}◈${NC} $1"; }
error() { echo -e "${RED}✖${NC} $1"; }
ok()    { echo -e "${GREEN}✔${NC} $1"; }

GITHUB_RAW="https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main"
DEST="/tmp/upgrade_openclaw.sh"

do_download() {
  echo ""
  info "下载 upgrade_openclaw.sh..."
  if ! curl --fail --silent --show-error -L "$GITHUB_RAW/upgrade_openclaw.sh" -o "$DEST" 2>&1; then
    error "下载失败，请检查网络连接"
    exit 1
  fi
  chmod +x "$DEST"
  ok "下载完成 → $DEST"
}

do_run() {
  echo ""
  info "启动升级脚本..."
  echo ""
  if ! bash "$DEST" "$@"; then
    error "脚本执行失败"
    exit 1
  fi
}

MODE="run"
[ "${1:-}" = "--dl" ] && MODE="dl"

if [ "$MODE" = "dl" ]; then
  do_download
else
  do_download
  do_run "$@"
fi
