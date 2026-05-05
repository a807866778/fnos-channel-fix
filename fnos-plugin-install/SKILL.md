---
name: fnos-plugin-install
description: 飞牛 fnOS OpenClaw 飞书/微信插件安装引导。当用户发送「安装飞书插件」「重装微信插件」「飞书通道」「微信通道」「openclaw feishu」「openclaw weixin」或询问插件问题时触发。功能：诊断当前插件状态 → 给出安装/重装步骤 → 提供详细命令和注意事项。
---

# fnos-plugin-install Skill

当用户提到以下关键词时触发本 Skill：
- 「安装飞书插件」「重装飞书」
- 「安装微信插件」「重装微信」
- 「飞书通道」「微信通道」
- 「feishu」「weixin」「openclaw feishu」「openclaw weixin」
- 「插件坏了」「插件不能用」「机器人没反应」

## 核心原则

**不要在 OpenClaw Agent 内执行任何破坏性插件操作**
- 不要执行 `rm -rf` 插件目录
- 不要执行 `npm install` 来安装/重装插件（npm 在沙盒里权限受限）
- **插件安装必须由用户在 fnOS SSH root 会话中手动完成**
- Agent 只负责：诊断问题 → 给出清晰步骤 → 让用户自己执行

## 诊断流程

### Step 1：检查当前插件状态

```bash
# 查看飞书插件版本
cat /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm/node_modules/@openclaw/feishu/package.json 2>/dev/null | grep '"version"'

# 查看微信插件版本
cat /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm/node_modules/@tencent-weixin/openclaw-weixin/package.json 2>/dev/null | grep '"version"'

# 查看 OpenClaw 版本
cat /vol1/@apphome/trim.openclaw/data/openclaw/node_modules/openclaw/package.json 2>/dev/null | grep '"version"'
```

### Step 2：检查飞书认证状态

```bash
# 在 Agent 环境的 workspace 里查询 lark-cli 认证状态
cd /vol1/@apphome/trim.openclaw/data/workspace && node_modules/.bin/lark-cli auth status
```

### Step 3：检查 openclaw.json 配置

```bash
python3 -c "
import json
d = json.load(open('/vol1/@apphome/trim.openclaw/data/home/.openclaw/openclaw.json'))
ch = d.get('channels', {})
print('feishu:', ch.get('feishu', 'NOT CONFIGURED'))
print('openclaw-weixin:', ch.get('openclaw-weixin', 'NOT CONFIGURED'))
"
```

## 输出格式

根据诊断结果，告诉用户：

**如果插件正常：**
> 你的飞书插件版本是 xxx，状态正常。请确认：
> 1. 飞牛管理页面 → OpenClaw 已启用
> 2. 飞书中机器人处于在线状态
> 3. 尝试给机器人发一条消息测试

**如果需要重装飞书：**
> 飞书插件需要重装。请按以下步骤操作：
> 
> **Step 1.** SSH 连接到你的 fnOS：`ssh 你的用户名@fnOS的IP`
> 
> **Step 2.** 切换到 root：`sudo -i`
> 
> **Step 3.** 执行以下命令：
> ```bash
> cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm
> rm -rf node_modules/@openclaw/feishu
> npm install @openclaw/feishu --registry https://registry.npmmirror.com
> systemctl --user restart openclaw-gateway
> ```
> 
> **Step 4.** 在飞书中给机器人发：`/feishu auth` 完成授权

**如果需要重装微信：**
> 微信插件需要重装。请按以下步骤操作：
> 
> **Step 1.** SSH 连接到你的 fnOS：`ssh 你的用户名@fnOS的IP`
> 
> **Step 2.** 切换到 root：`sudo -i`
> 
> **Step 3.** 执行以下命令：
> ```bash
> cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm
> rm -rf node_modules/@tencent-weixin/openclaw-weixin
> npm install @tencent-weixin/openclaw-weixin --registry https://registry.npmmirror.com
> systemctl --user restart openclaw-gateway
> ```
> 
> **Step 4.** 在飞牛管理页面重新扫码配置微信通道

## 插件版本参考

| 插件 | npm 包名 | 当前最新版本 |
|------|---------|------------|
| 飞书 | `@openclaw/feishu` | 2026.5.3 |
| 微信 | `@tencent-weixin/openclaw-weixin` | 2.4.1 |

> 获取最新版本：`npm view @openclaw/feishu version`
