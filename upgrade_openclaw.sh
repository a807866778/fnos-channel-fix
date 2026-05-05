#!/bin/bash
# ==============================================================
# 飞牛 OpenClaw | 一键升降级工具 v11.0.0（社区插件保护版）
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
NPM_PREFIX=""
CURRENT_VER=""
TARGET_VER=""
APPDEST=""
BUILTIN_PLUGINS="browser device-pair file-transfer memory-core phone-control talk-voice"

# ==============================================================
init_log() {
 mkdir -p "$LOG_DIR"
 LOG="${LOG_DIR}/upgrade_${NOW_STR}.log"
 touch "$LOG"
 # 用 tee 不通过 exec，避免 set -e 下进程替换失败导致脚本退出
 log() { echo -e "${GREEN}●${NC} $1" | tee -a "$LOG"; }
 info() { echo -e "${BLUE}◈${NC} $1" | tee -a "$LOG"; }
 warn() { echo -e "${YELLOW}▲${NC} $1" | tee -a "$LOG"; }
 error() { echo -e "${RED}✖${NC} $1" | tee -a "$LOG"; }
 ok() { echo -e "${GREEN}✔${NC} $1" | tee -a "$LOG"; }
 line() { echo -e "${GRAY}────────────────────────────────────────────────────${NC}" | tee -a "$LOG"; }
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
 [ -z "$APPHOME" ] && { error "未找到 OpenClaw 目录"; exit 1; }

 APPDEST="$(dirname "$APPHOME")/@appdest/trim.openclaw"
 OPENCLAW_DIR="$APPHOME/data/openclaw"
 DATA_DIR="$APPHOME/data"
 PKG_DIR="$OPENCLAW_DIR/node_modules/openclaw"
 NPM_PREFIX="$DATA_DIR/home/.openclaw/npm"

 BUN_CMD=$(command -v bun 2>/dev/null || true)
 [ -z "$BUN_CMD" ] && [ -f "$APPDEST/bunjs/bin/bun" ] && BUN_CMD="$APPDEST/bunjs/bin/bun"
 [ -z "$BUN_CMD" ] && for vol in /vol1 /vol2 /vol3 /vol4 /vol11 /vol12; do
 if [ -f "$vol/@appcenter/bunjs/bin/bun" ]; then
 BUN_CMD="$vol/@appcenter/bunjs/bin/bun"
 break
 fi
 done

 if [ -f "$PKG_DIR/package.json" ]; then
 CURRENT_VER=$(python3 -c "import json; print(json.load(open('$PKG_DIR/package.json')).get('version','未知'))" 2>/dev/null || echo "未知")
 fi
 [ -z "$CURRENT_VER" ] && CURRENT_VER="未知"
}

# ==============================================================
# 检测用户类型
# ==============================================================
detect_user_type() {
 local ext_dir="$PKG_DIR/dist/extensions"
 if [ ! -d "$ext_dir" ] || [ -z "$(ls -A "$ext_dir" 2>/dev/null)" ]; then
 echo "fresh"
 return
 fi
 local community_count=0
 for plugin_dir in "$ext_dir"/*; do
 [ -d "$plugin_dir" ] || continue
 local name=$(basename "$plugin_dir")
 echo "$BUILTIN_PLUGINS" | grep -qw "$name" && continue
 [ -f "$plugin_dir/openclaw.plugin.json" ] && community_count=$((community_count + 1))
 done
 [ $community_count -gt 0 ] && echo "existing" || echo "fresh"
}

# ==============================================================
fetch_npm_latest() {
 local LATEST=""
 LATEST=$(curl -s --max-time 5 "https://registry.npmmirror.com/openclaw/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)
 [ -z "$LATEST" ] && LATEST=$(curl -s --max-time 5 "https://registry.npmjs.org/openclaw/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)
 [ -z "$LATEST" ] && { warn "无法获取最新版本，使用 2026.4.11"; LATEST="2026.4.11"; }
 echo "$LATEST"
}

# ==============================================================
stop_openclaw() {
 log "停止 OpenClaw..."
 # 先尝试 systemctl 停止
 systemctl --user stop openclaw-gateway 2>/dev/null || true
 sleep 2
 # 强制 kill 所有相关进程
 pkill -9 -u trim.openclaw -f "bun.*openclaw\|openclaw.*gateway" 2>/dev/null || true
 pkill -9 -u trim.openclaw -f "bun" 2>/dev/null || true
 sleep 2
 ok "已停止"
}

# ==============================================================
full_backup() {
 local backup_dir="${SCRIPT_DIR}/openclaw_fullbackup_${NOW_STR}"
 mkdir -p "$backup_dir"
 cp -a --no-preserve=mode,ownership "$DATA_DIR" "$backup_dir/" 2>/dev/null || cp -a "$DATA_DIR" "$backup_dir/"
 ok "全量备份完成 → $backup_dir"
}

# ==============================================================
install_plugin_to_extensions() {
 local pkg="$1"
 local name="$2"
 local ext_dir="$PKG_DIR/dist/extensions"
 local backup_dir=""

 mkdir -p "$ext_dir"

 if [ -d "$ext_dir/$name" ]; then
   # 已存在 → 检查版本
   local existing_ver=$(python3 -c "import json; print(json.load(open('$ext_dir/$name/package.json')).get('version','0'))" 2>/dev/null || echo "0")

   # 获取 npm 最新版本（优先 npmmirror，降级到 npmjs）
   local latest_ver=$(curl -s --max-time 5 "https://registry.npmmirror.com/$pkg/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)
   [ -z "$latest_ver" ] && latest_ver=$(curl -s --max-time 5 "https://registry.npmjs.org/$pkg/latest" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || true)

   info "已有 $name (v$existing_ver)，最新 v$latest_ver"

   if [ "$existing_ver" = "$latest_ver" ] || [ -z "$latest_ver" ]; then
     info "版本一致，跳过: $name"
     return 0
   fi

   # 版本不同 → 备份配置 → 卸载旧插件
   info "版本不同，开始更新: $name"
   backup_dir="/tmp/backup_${name}_$(date +%s)"
   mkdir -p "$backup_dir"

   # 备份用户配置（插件自己的 config/token/db 等用户数据文件）
   for cfg_file in "$ext_dir/$name"/*.json "$ext_dir/$name"/*.db "$ext_dir/$name"/*.sqlite "$ext_dir/$name"/*.token "$ext_dir/$name"/data/*; do
     [ -f "$cfg_file" ] && cp -a "$cfg_file" "$backup_dir/" 2>/dev/null || true
   done
   info "配置已备份到 $backup_dir"

   # 卸载旧插件
   rm -rf "$ext_dir/$name"
   info "已卸载旧版: $name"
 fi

 # 飞书官方插件用 npx 安装，其他用 npm
 if echo "$pkg" | grep -q "larksuite"; then
   info "安装 $pkg (npx 方式)..."
   cd /tmp && npx -y "$pkg" install >/dev/null 2>&1 && cd -
   local src_dir="/tmp/node_modules/$pkg"
 else
   info "安装 $pkg (npm 方式)..."
   mkdir -p "$NPM_PREFIX"
   npm install "$pkg" --prefix "$NPM_PREFIX" --registry https://registry.npmmirror.com >/dev/null 2>&1
   local src_dir="$NPM_PREFIX/node_modules/$pkg"
 fi

 if [ -d "$src_dir" ]; then
   cp -a "$src_dir" "$ext_dir/$name"
   chown -R root:root "$ext_dir/$name"

   # 恢复用户配置
   if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
     info "恢复配置: $name"
     for bak_file in "$backup_dir"/*; do
       [ -f "$bak_file" ] && cp -f "$bak_file" "$ext_dir/$name/" 2>/dev/null || true
     done
     rm -rf "$backup_dir"
   fi

   ok "已安装: $name"
 else
   warn "安装失败: $pkg"
 fi
}

# ==============================================================
install_community_plugins() {
 install_plugin_to_extensions "@larksuite/openclaw-lark"         "openclaw-lark"
 install_plugin_to_extensions "@tencent-weixin/openclaw-weixin" "openclaw-weixin"
}

# ==============================================================
fix_weixin_config() {
 local cfg="$DATA_DIR/home/.openclaw/openclaw.json"
 [ ! -f "$cfg" ] && return
 local state=$(python3 -c "
import json
try:
 w = json.load(open('$cfg')).get('channels',{}).get('openclaw-weixin')
 print('ok' if w and w != {} else ('empty' if w == {} else 'missing'))
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
refresh_registry() {
 info "刷新插件注册表..."
 openclaw plugins registry --refresh >/dev/null 2>&1 && ok "注册表已刷新" || warn "注册表刷新失败"
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
 if curl --fail --silent --show-error "$mirror" -o "$tgzd" 2>/dev/null; then
 local size=$(stat -c%s "$tgzd" 2>/dev/null || stat -f%z "$tgzd" 2>/dev/null)
 [ "$size" -gt 1000 ] && ok "下载完成" && return 0
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

 local custom_skills_backup="/tmp/openclaw_custom_skills_$$"
 mkdir -p "$custom_skills_backup"
 [ -d "$PKG_DIR/skills" ] && cp -a "$PKG_DIR/skills" "$custom_skills_backup/"
 log "替换主程序..."
 rm -rf "$PKG_DIR"
 mkdir -p "$PKG_DIR"
 tar -xzf "/tmp/openclaw-${TARGET_VER}.tgz" --strip-components=1 -C "$PKG_DIR"
 rm -f "/tmp/openclaw-${TARGET_VER}.tgz"
 [ -d "$custom_skills_backup/skills" ] && cp -a "$custom_skills_backup/skills/"* "$PKG_DIR/skills/" 2>/dev/null || true
 rm -rf "$custom_skills_backup"
 ok "主程序替换完成"

 log "安装依赖..."
 "$BUN_CMD" install --registry https://registry.npmmirror.com >/dev/null 2>&1 && ok "依赖安装完成" || warn "依赖安装完成（有警告可忽略）"

 log "安装社区插件..."
 install_community_plugins

 fix_weixin_config
 refresh_registry

 sudo chown -R trim.openclaw:trim.openclaw "$DATA_DIR" >/dev/null 2>&1 || true

 rm -rf /tmp/openclaw-*.tgz /tmp/openclaw-* 2>/dev/null || true
 ok "升级完成！"
}

# ==============================================================
show_title() {
 clear
 echo ""
 echo -e "${BOLD}${MAGENTA} 飞牛 OpenClaw | 一键升降级 v11.0.0${NC}"
 echo -e "${GRAY} 社区插件保护版 | github.com/a807866778/fnos-channel-fix${NC}"
 echo ""
}

show_help() {
 show_title
 echo -e "${WHITE}使用方法：${NC}"
 echo ""
 echo -e " ${CYAN}bash $0${NC} ｜ 交互式一键升级（直接回车升级到最新稳定版）"
 echo -e " ${CYAN}bash $0 latest${NC} ｜ 升级到最新版本（含预发布）"
 echo -e " ${CYAN}bash $0 2026.4.5${NC} ｜ 指定版本升级"
 echo -e " ${CYAN}bash $0 --verify${NC} ｜ 查看当前版本"
 echo -e " ${CYAN}bash $0 --restore${NC} ｜ 恢复备份"
 echo -e " ${CYAN}bash $0 --help${NC} ｜ 查看帮助"
 echo ""
 echo -e "${YELLOW}功能说明：${NC}"
 echo -e " • 自动识别老用户/新用户"
 echo -e " • 自动全量备份系统"
 echo -e " • 保护社区插件不丢失"
 echo -e " • 自动修复微信通道空配置陷阱"
 line
}

# ==============================================================
# ==============================================================
# 恢复备份
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
 local date=$(basename "$backup" | sed 's/openclaw_fullbackup_//')
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
 echo -e "${WHITE}备份内容：${NC}"
 ls "$selected"
 echo ""
 printf "${RED}确认恢复此备份？数据将被覆盖！(yes)：${NC}"
 read CONFIRM
 [[ "$CONFIRM" != "yes" ]] && error "已取消" && exit 0

 log "正在恢复备份..."
 stop_openclaw
 sleep 2
 cp -a --no-preserve=mode,ownership "$selected/data" "$DATA_DIR/" 2>/dev/null || true
 ok "备份已恢复"
 log "启动 OpenClaw..."
 systemctl --user start openclaw-gateway 2>/dev/null || true
 echo ""
 ok "恢复完成，请在飞牛管理界面重启 OpenClaw"
}

main() {
 local TARGET_NUM=""

 case "${1:-}" in
 --verify)
 init_log
 show_title
 detect_env
 echo "当前版本：$CURRENT_VER"
 line
 exit 0
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

 local user_type=$(detect_user_type)
 local user_desc="全新环境"
 [ "$user_type" = "existing" ] && user_desc="旧环境"

 echo ""
 echo -e "${WHITE}【当前信息】${NC}"
 echo -e " 当前版本：${GREEN}${CURRENT_VER}${NC}"
 echo -e " 用户类型：${GREEN}${user_desc}${NC}"
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

 # 如果目标版本等于当前版本，提示确认
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
 echo -e "${YELLOW}后续操作：${NC}"
 echo -e " 1. 飞牛应用管理 → 重新启用 OpenClaw"
 echo -e " 2. 等待30秒后验证：${CYAN}openclaw channels list${NC}"
 echo -e " 3. ${RED}微信需重新扫码${NC}：飞牛应用管理 → OpenClaw → 微信通道"
 echo -e " 4. ${RED}飞书需重新授权${NC}：在飞书中发送 ${CYAN}/feishu auth${NC}"
 line
}

main "$@"
