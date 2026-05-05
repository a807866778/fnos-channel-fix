> **来源**：基于飞牛社区论坛帖子（https://club.fnnas.com/forum.php?mod=viewthread&tid=61202）改造

💡 前言：OpenClaw 升级后飞书/微信机器人不回复？升级后通道全部消失？本工具一个脚本搞定，自动识别老用户/新用户，自动备份/保护社区插件，零门槛！

## 📌 脚本核心优势

- **一个脚本**：集升级 + 备份 + 插件保护 + 通道修复于一身
- **智能识别**：自动判断老用户/新用户，老用户先清旧版再装新版，新用户直接安装
- **自动备份**：升级前全量备份系统，插件独立备份
- **修复配置**：自动修复微信空配置陷阱

## 🔧 适用人群

- 飞牛 NAS 用户，想安全升级 OpenClaw
- 升级后发现飞书/微信通道不通
- 想保护社区插件不被删除

## 📝 必看前置说明

- 微信需要重新扫码登录（飞牛应用管理 → OpenClaw → 微信通道 → 扫码）
- 飞书凭证已保留，一般无需重新配置
- 升级完成后建议重启一次 OpenClaw

## 🔧 操作步骤

### 1. SSH 登录 NAS，执行以下命令

```bash
sudo -i
curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/upgrade_openclaw.sh -o ~/upgrade_openclaw.sh
chmod +x ~/upgrade_openclaw.sh
bash ~/upgrade_openclaw.sh
```

### 2. 交互操作

- 直接回车：升级到最新稳定版
- 输入版本号：指定版本升级（如 2026.4.5）
- 跟着提示操作即可

## 🔍 常用命令

```bash
# 查看当前版本
bash ~/upgrade_openclaw.sh --verify

# 查看帮助
bash ~/upgrade_openclaw.sh --help
```

## ⚠️ 注意事项

- 升级前会自动全量备份，备份文件保存在脚本同目录
- 微信扫码后凭证保存在 `~/.openclaw/openclaw-weixin/accounts/`，不要删除
- 重要数据建议额外手动备份

## 📥 脚本源码

~~~bash
sudo -i
curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/upgrade_openclaw.sh -o ~/upgrade_openclaw.sh
chmod +x ~/upgrade_openclaw.sh
bash ~/upgrade_openclaw.sh
~~~

完整源码仓库：https://github.com/a807866778/fnos-channel-fix

## 💖 结尾

如果脚本对您有用请帮顶一下原帖 🙏

交流反馈：https://github.com/a807866778/fnos-channel-fix/issues
