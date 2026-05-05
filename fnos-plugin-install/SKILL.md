---
name: fnos-plugin-install
description: "飞牛 fnOS + OpenClaw 插件安装与修复助手。当用户说「安装飞书插件」「重装微信插件」「飞书机器人不能用了」「微信通道坏了」时触发。全自动完成，无需用户操作。"
---

# fnos-plugin-install

## 执行原则

**AI Agent 直接执行所有操作，不要告诉用户要做什么，执行完只告知结果。**

## 环境路径

- APPHOME: `/vol1/@apphome/trim.openclaw`
- NPM_PREFIX: `/vol1/@apphome/trim.openclaw/data/home/.openclaw/npm`
- EXT_DIR: `/vol1/@apphome/trim.openclaw/data/openclaw/node_modules/openclaw/dist/extensions`
- NPM_BIN: `/vol1/@appcenter/nodejs_v22/bin/npm`

## 插件列表

| 插件 | npm 包名 | 扩展目录名 |
|------|---------|-----------|
| 飞书 | `@openclaw/feishu` | `feishu` |
| 微信 | `@tencent-weixin/openclaw-weixin` | `openclaw-weixin` |

## 安装命令

```bash
# 1. 安装飞书
mkdir -p "$NPM_PREFIX"
NPM_BIN="/vol1/@appcenter/nodejs_v22/bin/npm"
$NPM_BIN install "@openclaw/feishu" --prefix "$NPM_PREFIX" --registry https://registry.npmmirror.com

# 2. 安装微信
$NPM_BIN install "@tencent-weixin/openclaw-weixin" --prefix "$NPM_PREFIX" --registry https://registry.npmmirror.com

# 3. 复制到扩展目录
EXT_DIR="/vol1/@apphome/trim.openclaw/data/openclaw/node_modules/openclaw/dist/extensions"
mkdir -p "$EXT_DIR"
[ -d "$NPM_PREFIX/node_modules/@openclaw/feishu" ] && cp -a "$NPM_PREFIX/node_modules/@openclaw/feishu" "$EXT_DIR/feishu"
[ -d "$NPM_PREFIX/node_modules/@tencent-weixin/openclaw-weixin" ] && cp -a "$NPM_PREFIX/node_modules/@tencent-weixin/openclaw-weixin" "$EXT_DIR/openclaw-weixin"

# 4. 重启网关
systemctl --user restart openclaw-gateway 2>/dev/null || sudo systemctl --user restart openclaw-gateway 2>/dev/null || true
```

## 执行方式

收到用户安装请求后：
1. 检测插件状态
2. 执行安装命令
3. 重启网关
4. 告知用户完成（不要描述步骤）
