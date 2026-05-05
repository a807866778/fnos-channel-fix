#!/bin/bash
# ==============================================================
# 飞牛 OpenClaw | 一键安装工具
# ==============================================================
# 使用方法：
#   sudo -i
#   curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/upgrade_openclaw.sh -o ~/upgrade_openclaw.sh
#   chmod +x ~/upgrade_openclaw.sh
#   bash ~/upgrade_openclaw.sh
# ==============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

info() { echo -e "${BLUE}◈${NC} $1"; }
warn() { echo -e "${YELLOW}▲${NC} $1"; }
error() { echo -e "${RED}✖${NC} $1"; }
ok() { echo -e "${GREEN}✔${NC} $1"; }

GITHUB_RAW="https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main"

# 检测 root
check_root() {
 if [ "$(id -u)" -ne 0 ]; then
 echo ""
 error "请先执行 sudo -i 切换到管理员模式！"
 echo ""
 echo -e "${CYAN}步骤：${NC}"
 echo -e " 1. 输入 ${YELLOW}sudo -i${NC} 回车"
 echo -e " 2. 输入密码回车"
 echo -e " 3. 重新执行本脚本"
 echo ""
 exit 1
 fi
}

show_title() {
 clear
 echo ""
 echo -e "${BOLD}${MAGENTA} 飞牛 OpenClaw 一键升级工具${NC}"
 echo ""
}

main() {
 show_title
 check_root

 echo ""
 info "下载升级脚本..."
 if ! curl --fail --silent --show-error -L "$GITHUB_RAW/upgrade_openclaw.sh" -o ~/upgrade_openclaw.sh 2>/dev/null; then
 error "下载失败，请检查网络"
 exit 1
 fi
 chmod +x ~/upgrade_openclaw.sh
 ok "下载完成 → ~/upgrade_openclaw.sh"
 echo ""
 info "启动升级脚本..."
 echo ""
 bash ~/upgrade_openclaw.sh "$@"
}

main "$@"
