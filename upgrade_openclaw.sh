#!/bin/bash
# ==============================================================
# 飞牛 OpenClaw | 一键升级工具 v12.0.0
# ==============================================================
# 功能：升级 OpenClaw 主体版本
# 插件安装请参考 fnos-plugin-install skill
# ==============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOW_STR=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${SCRIPT_DIR}/openclaw_upgrade_logs"

# -------------------------- 色彩 --------------------------
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

# -------------------------- 变量 --------------------------
APPHOME=""
DATA_DIR=""
OPENCLAW_DIR=""
PKG_DIR=""
BUN_CMD=""
CURRENT_VER=""
TARGET_VER=""
APPDEST=""

# ==============================================================
init_log() {
 mkdir -p "$LOG_DIR"
 LOG="${LOG_DIR}/upgrade_${NOW_STR}.log"
 touch "$LOG"
 log()   { echo -e "${GREEN}●${NC} $1" | tee -a "$LOG"; }
 info()  { echo -e "${BLUE}◈${NC} $1" | tee -a "$LOG"; }
 warn()  { echo -e "${YELLOW}▲${NC} $1" | tee -a "$LOG"; }
 error() { echo -e "${RED}✖${NC} $1" | tee -a "$LOG"; }
 ok()    { echo -e "${GREEN}✔${NC} $1" | tee -a "$LOG"; }
 line()  { echo -e "${GRAY}────────────────────────────────────────────────────${NC}" | tee -a "$LOG"; }
 info "日志：$LOG"
}

# ==============================================================
detect_env() {
 for vol in /vol1 /vol2 /vol12 /vol11 /vol3 /vol4; do
   if [ -d "$vol/@apphome/trim.openclaw" ]; then
     APPHOME="$vol/@apphome/trim.openclaw"
     break
   fi
 done
 if [ -z "$APPHOME" ]; then error "未找到 OpenClaw 目录（trim.openclaw）"; exit 1; fi

 APPDEST="$(dirname "$APPHOME")/@appdest/trim.openclaw"
 OPENCLAW_DIR="$APPHOME/data/openclaw"
 DATA_DIR="$APPHOME/data"
 PKG_DIR="$OPENCLAW_DIR/node_modules/openclaw"

 # 查找 bun 二进制（sudo 下 PATH 会被重置，必须用绝对路径）
 BUN_CMD=""
 for vol in /vol1 /vol2 /vol3 /vol4 /vol11 /vol12; do
   if [ -f "$vol/@appcenter/bunjs/bin/bun" ]; then
     BUN_CMD="$vol/@appcenter/bunjs/bin/bun"
     break
   fi
 done
 if [ -z "$BUN_CMD" ] && [ -f "$APPDEST/bunjs/bin/bun" ]; then
   BUN_CMD="$APPDEST/bunjs/bin/bun"
 fi
 if [ -z "$BUN_CMD" ]; then
   BUN_CMD=$(command -v bun 2>/dev/null || true)
 fi

 if [ -f "$PKG_DIR/package.json" ]; then
   CURRENT_VER=$(python3 -c "import json; print(json.load(open('$PKG_DIR/package.json')).get('version','未知'))" 2>/dev/null || echo "未知")
 fi
 CURRENT_VER="${CURRENT_VER:-未知}"
}

# ==============================================================
fetch_npm_latest() {
 local LATEST=""
 LATEST=$(curl -s --max-time 5 "https://registry.npmmirror.com/openclaw/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)
 if [ -z "$LATEST" ]; then
  LATEST=$(curl -s --max-time 5 "https://registry.npmjs.org/openclaw/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)
fi
if [ -z "$LATEST" ]; then
  warn "无法获取最新版本，默认使用 2026.5.4"
  LATEST="2026.5.4"
fi
 echo "$LATEST"
}

# ==============================================================
stop_openclaw() {
 info "停止 OpenClaw..."
 # 通过 systemctl 停止
 systemctl --user stop openclaw-gateway 2>/dev/null || true
 sleep 3
 # 强制结束残留进程（使用绝对路径 killall）
 local KILLALL=$(command -v killall 2>/dev/null || true)
 [ -n "$KILLALL" ] && $KILLALL -9 bun 2>/dev/null || true
 pkill -9 -u trim.openclaw -f "bun.*openclaw" 2>/dev/null || true
 sleep 2
 ok "已停止"
}

# ==============================================================
full_backup() {
 local backup_dir="${SCRIPT_DIR}/openclaw_fullbackup_${NOW_STR}"
 mkdir -p "$backup_dir"
 cp -a --no-preserve=mode,ownership "$DATA_DIR" "$backup_dir/" 2>/dev/null || \
   cp -a "$DATA_DIR" "$backup_dir/"
 ok "全量备份完成 → $backup_dir"
}

# ==============================================================
fix_weixin_config() {
 local cfg="$DATA_DIR/home/.openclaw/openclaw.json"
 [ ! -f "$cfg" ] && return
 local state=$(python3 -c "
import json, sys
try:
    w = json.load(open('$cfg')).get('channels',{}).get('openclaw-weixin')
    if w is None: print('missing')
    elif w == {}: print('empty')
    else: print('ok')
except: print('error')
" 2>/dev/null)
 if [ "$state" = "empty" ]; then
   python3 -c "
import json
c=json.load(open('$cfg'))
c['channels']['openclaw-weixin']={'accounts':{}}
json.dump(c,open('$cfg','w'),indent=2,ensure_ascii=False)
" 2>/dev/null
   warn "已修复微信空配置"
 fi
}

# ==============================================================
download_package() {
 local tgzd="/tmp/openclaw-${TARGET_VER}.tgz"
 rm -f "$tgzd"
 local mirrors=(
   "https://registry.npmmirror.com/openclaw/-/openclaw-${TARGET_VER}.tgz"
   "https://mirrors.cloud.tencent.com/npm/openclaw/-/openclaw-${TARGET_VER}.tgz"
   "https://mirrors.huaweicloud.com/repository/npm/openclaw/-/openclaw-${TARGET_VER}.tgz"
 )
 for mirror in "${mirrors[@]}"; do
   info "尝试下载：$mirror"
   if curl --fail --silent --show-error --max-time 120 "$mirror" -o "$tgzd" 2>/dev/null; then
     local size=$(stat -c%s "$tgzd" 2>/dev/null || stat -f%z "$tgzd" 2>/dev/null)
     if [ "$size" -gt 1000 ]; then
       ok "下载完成 ($(numfmt --to=iec $size 2>/dev/null || echo "${size}B"))"
       return 0
     fi
   fi
   rm -f "$tgzd"
 done
 error "下载失败"
 return 1
}

# ==============================================================
do_upgrade() {
 log "=== 开始升级 OpenClaw ${TARGET_VER} ==="

 printf "${YELLOW}是否全量备份当前数据？(y/N)：${NC}"
 read DO_BACKUP
 [[ "$DO_BACKUP" != "y" && "$DO_BACKUP" != "Y" ]] && info "跳过备份" || full_backup

 stop_openclaw

 local pkjson="$OPENCLAW_DIR/package.json"
 local ver_env="$APPDEST/config/openclaw-version.env"
 [ ! -f "$pkjson" ] && { error "package.json 不存在"; exit 1; }
 sed -i "s/\"openclaw\": \"[0-9.]*\"/\"openclaw\": \"$TARGET_VER\"/" "$pkjson"
 [ -f "$ver_env" ] && sed -i "s/OPENCLAW_VERSION=.*/OPENCLAW_VERSION=$TARGET_VER/" "$ver_env"
 info "版本配置已写入"

 download_package || exit 1

 # 备份自定义 skills
 local custom_skills_backup="/tmp/openclaw_custom_skills_$$"
 mkdir -p "$custom_skills_backup"
 [ -d "$PKG_DIR/skills" ] && cp -a "$PKG_DIR/skills" "$custom_skills_backup/"

 info "替换主程序..."
 rm -rf "$PKG_DIR"
 mkdir -p "$PKG_DIR"
 tar -xzf "/tmp/openclaw-${TARGET_VER}.tgz" --strip-components=1 -C "$PKG_DIR"
 rm -f "/tmp/openclaw-${TARGET_VER}.tgz"

 # 恢复自定义 skills
 if [ -d "$custom_skills_backup/skills" ]; then
   cp -a "$custom_skills_backup/skills/"* "$PKG_DIR/skills/" 2>/dev/null || true
 fi
 rm -rf "$custom_skills_backup"
 ok "主程序替换完成"

 info "安装依赖..."
 "$BUN_CMD" install --registry https://registry.npmmirror.com >/dev/null 2>&1 && \
   ok "依赖安装完成" || warn "依赖安装完成（有警告可忽略）"

 fix_weixin_config

 # 恢复数据目录权限
 sudo chown -R trim.openclaw:trim.openclaw "$DATA_DIR" >/dev/null 2>&1 || true

 rm -rf /tmp/openclaw-*.tgz 2>/dev/null || true
 ok "升级完成！"
}

# ==============================================================
show_title() {
 echo ""
 echo -e "${BOLD}${MAGENTA} 飞牛 OpenClaw | 一键升级 v12.0.0${NC}"
 echo -e "${GRAY} github.com/a807866778/fnos-channel-fix${NC}"
 echo ""
}

show_help() {
 show_title
 echo -e "${WHITE}使用方法：${NC}"
 echo ""
 echo -e " ${CYAN}bash $0${NC}                ｜ 交互式一键升级（直接回车升级到最新稳定版）"
 echo -e " ${CYAN}bash $0 latest${NC}          ｜ 升级到最新版本（含预发布）"
 echo -e " ${CYAN}bash $0 2026.4.5${NC}        ｜ 指定版本升级"
 echo -e " ${CYAN}bash $0 --verify${NC}        ｜ 查看当前版本"
 echo -e " ${CYAN}bash $0 --restore${NC}       ｜ 恢复备份"
 echo -e " ${CYAN}bash $0 --help${NC}         ｜ 查看帮助"
 echo ""
 echo -e "${YELLOW}注意：${NC}"
 echo -e " • 本脚本仅升级 OpenClaw 主体，不包含插件安装"
 echo -e " • 飞书/微信插件安装请参考：fnos-plugin-install skill"
 line
}

# ==============================================================
do_restore() {
 show_title
 echo -e "${WHITE}【恢复备份】${NC}\n"

 local backups=($(ls -t "${SCRIPT_DIR}"/openclaw_fullbackup_* 2>/dev/null))
 if [ ${#backups[@]} -eq 0 ]; then
   error "未找到任何备份文件"
   echo "备份目录：${SCRIPT_DIR}"
   exit 1
 fi

 echo -e "${WHITE}可用备份：${NC}\n"
 local i=1
 for backup in "${backups[@]}"; do
   echo " $i) $(basename "$backup")"
   i=$((i+1))
 done
 echo ""
 printf "${BLUE}选择要恢复的备份编号 [1]：${NC}"
 read pick
 pick="${pick:-1}"
 local selected="${backups[$((pick-1))]}"
 if [ ! -d "$selected" ]; then
   error "无效选择"
   exit 1
 fi

 echo ""
 echo -e "${WHITE}确认恢复此备份？数据将被覆盖！(yes)：${NC}"
 read CONFIRM
 [[ "$CONFIRM" != "yes" ]] && error "已取消" && exit 0

 log "正在恢复备份..."
 stop_openclaw
 sleep 2
 cp -a --no-preserve=mode,ownership "$selected/data" "$DATA_DIR/" 2>/dev/null || true
 ok "备份已恢复，请在飞牛管理界面重启 OpenClaw"
}

# ==============================================================
main() {
 local TARGET_NUM=""

 case "${1:-}" in
 --verify)
   init_log; show_title
   detect_env
   echo -e "当前版本：${GREEN}${CURRENT_VER}${NC}"
   echo -e "应用目录：${GRAY}${APPHOME}${NC}"
   echo -e "Bun路径：${GRAY}${BUN_CMD}${NC}"
   line; exit 0
   ;;
 --help|-h) show_help; exit 0 ;;
 --restore) init_log; show_title; do_restore; exit 0 ;;
 latest)
   TARGET_NUM=$(fetch_npm_latest)
   info "latest → $TARGET_NUM"
   ;;
 *) TARGET_NUM="${1}" ;;
 esac

 init_log
 show_title
 info "探测环境..."
 detect_env
 ok "完成"

 echo ""
 echo -e "${WHITE}【当前信息】${NC}"
 echo -e " 当前版本：${GREEN}${CURRENT_VER}${NC}"
 echo -e " 应用目录：${GRAY}${APPHOME}${NC}"
 echo -e " Bun路径：${GRAY}${BUN_CMD}${NC}"
 line

 echo -e "${WHITE}【版本选择】${NC}"
 local default_ver=$(fetch_npm_latest)
 if [ -z "${TARGET_NUM}" ]; then
   printf "${BLUE}直接回车升级到最新稳定版（%s）：${NC}" "$default_ver"
   read INPUT_VER
   TARGET_NUM="${INPUT_VER:-$default_ver}"
 else
   info "已指定版本：${TARGET_NUM}"
 fi
 TARGET_VER="$TARGET_NUM"
 info "目标版本：${TARGET_VER}"

 if [ "$TARGET_VER" = "$CURRENT_VER" ]; then
   printf "${YELLOW}目标版本与当前版本相同，是否确认升级？(y/N)：${NC}"
   read CONFIRM
   [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && error "已取消" && exit 0
 else
   line
   printf "${YELLOW}确认开始升级？(y/N)：${NC}"
   read CONFIRM
   [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && error "已取消" && exit 0
 fi

 do_upgrade

 line
 echo ""
 echo -e "${BOLD}${GREEN}升级完成${NC}"
 echo ""
 echo -e "${WHITE}目标版本：${GREEN}${TARGET_VER}${NC}"
 echo -e "${WHITE}日志文件：${GRAY}${LOG}${NC}"
 echo ""
 echo -e "${YELLOW}升级完成！${NC}"
 echo ""
 echo -e "升级后插件可能不兼容，无需手动操作，告诉 OpenClaw 就行了："
 echo ""
 echo -e "  在 OpenClaw 里发送："
 echo -e "  ${CYAN}\"我的飞书机器人不能用了，帮我修复一下\""
 echo -e "  或"
 echo -e "  ${CYAN}\"我的微信通道坏了，帮我修复一下\""
 echo ""
 echo -e "OpenClaw 会自动完成插件的修复/重装/授权。"
 line
}

main "$@"
