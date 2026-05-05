---
name: fnos-plugin-install
description: 飞牛 fnOS OpenClaw 飞书/微信插件安装与重装引导。触发词：「安装飞书插件」「重装微信插件」「安装插件」「插件问题」「飞书通道」「微信通道」「feishu」「weixin」「openclaw weixin」「openclaw feishu」。功能：诊断当前插件状态 → 给出安装/重装/修复步骤 → 引导用户操作。
---

# 飞牛 fnOS OpenClaw 插件安装指南

> 本文档面向 **飞牛 fnOS + OpenClaw** 用户，特别适合不熟悉命令行的普通用户。
> 插件安装**在飞牛网页管理界面操作**，不需要进小黑框（SSH）。

---

## 目录

1. [插件是什么？](#1-插件是什么)
2. [飞书插件安装/重装](#2-飞书插件安装重装)
3. [微信插件安装/重装](#3-微信插件安装重装)
4. [常见问题](#4-常见问题)
5. [手动命令参考](#5-手动命令参考)

---

## 1. 插件是什么？

OpenClaw 的插件决定了它能连接哪些聊天平台：

| 插件 | 支持的平台 | 是否需要 |
|------|-----------|---------|
| **飞书插件** | 飞书 | ✅ 推荐安装 |
| **微信插件** | 企业微信/微信 | 可选 |

插件安装在 **飞牛管理页面** → **应用中心** → **OpenClaw** 配置页，不需要 SSH。

---

## 2. 飞书插件安装/重装

### 什么情况下需要重装？

- 飞书机器人完全无响应
- 发送消息没有反应
- 飞书授权过期了
- 想升级到更新版本

### 操作步骤

#### 方式一：网页管理界面（推荐新手）

**Step 1.** 打开飞牛管理页面，登录

**Step 2.** 进入 **应用中心** → **OpenClaw** → **插件配置**

**Step 3.** 找到 **飞书/Lark** 插件，点击 **重新安装**

**Step 4.** 页面会提示在飞书中重新授权，复制机器人发送的验证码

---

#### 方式二：SSH 命令（适合有技术基础的用户）

如果你习惯用命令行，按以下步骤操作：

```bash
# 1. 连接到 fnOS（用 PuTTY 或 Windows Terminal）
ssh fnos用户名@fnos机器IP
# 例如：ssh admin@192.168.1.100

# 2. 切换到 root
sudo -i

# 3. 进入 OpenClaw 目录
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm

# 4. 卸载旧版飞书插件（如果需要重装）
rm -rf node_modules/@openclaw/feishu

# 5. 安装最新版飞书插件
npm install @openclaw/feishu --registry https://registry.npmmirror.com

# 6. 重启 OpenClaw
systemctl --user restart openclaw-gateway
```

---

### 飞书授权步骤

重装后需要在飞书里完成授权：

1. 打开飞书，进入你的机器人对话
2. 发送命令：`/feishu auth`
3. 机器人会回复一个链接，点击并完成飞书授权
4. 授权成功后，发一条测试消息给机器人确认可用

---

## 3. 微信插件安装/重装

### 什么情况下需要重装？

- 微信通道完全无法使用
- 扫码后依然无法收发消息
- 想升级到更新版本

### 操作步骤（网页管理界面）

**Step 1.** 飞牛管理页面 → **应用中心** → **OpenClaw** → **插件配置**

**Step 2.** 找到 **微信** 插件，点击 **安装**（如果没有）或 **重新安装**

**Step 3.** 按照页面提示，在企业微信后台完成验证

---

### 微信插件命令安装

```bash
# 1. SSH 连接到 fnOS
ssh fnos用户名@fnos机器IP

# 2. 切换 root
sudo -i

# 3. 进入插件目录
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm

# 4. 安装微信插件
npm install @tencent-weixin/openclaw-weixin --registry https://registry.npmmirror.com

# 5. 重启 OpenClaw
systemctl --user restart openclaw-gateway
```

---

## 4. 常见问题

### Q1: 插件显示已安装但无法使用？

**答：** 先尝试**重启 OpenClaw**：
- 飞牛管理页面 → 应用中心 → OpenClaw → 点「重启」
- 等待 30 秒后再试

### Q2: 飞书机器人没有任何反应？

**答：** 按顺序排查：
1. 飞书机器人是否被停用？→ 在飞书管理后台确认机器人状态
2. OpenClaw 是否在运行？→ 飞牛管理页面确认应用状态
3. 飞书授权是否过期？→ 重新发送 `/feishu auth` 授权

### Q3: 微信扫码后还是不行？

**答：** 尝试重新扫码：
1. 飞牛管理页面 → OpenClaw → 微信通道配置
2. 点击「重新扫码」
3. 用企业微信扫码确认

### Q4: 升级 OpenClaw 后插件还能用吗？

**答：** 可以。升级 OpenClaw 主体不会影响插件配置，插件数据会保留。
但如果升级后遇到插件问题，参考本文档重装对应插件即可。

### Q5: 不确定当前插件版本？

**答：** 在 OpenClaw 运行状态下，发送 `/feishu auth` 可以查看飞书插件状态。
或者 SSH 进系统后查看：
```bash
cat /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm/node_modules/@openclaw/feishu/package.json | grep version
```

### Q6: 插件安装失败了怎么办？

**答：** 
1. 确认网络连接（fnOS 能访问 npm 镜像）
2. 确认存储空间充足
3. 查看错误日志：`journalctl --user -u openclaw-gateway -n 50`
4. 如果还是失败，尝试重启 fnOS 后再装

---

## 5. 手动命令参考

以下是完整的手动安装/重装命令，仅供有经验的用户参考。

### 查看当前插件状态

```bash
# 查看飞书插件版本
cat /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm/node_modules/@openclaw/feishu/package.json | grep '"version"'

# 查看微信插件版本
cat /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm/node_modules/@tencent-weixin/openclaw-weixin/package.json | grep '"version"'

# 查看 OpenClaw 版本
cat /vol1/@apphome/trim.openclaw/data/openclaw/node_modules/openclaw/package.json | grep '"version"'
```

### 完全重装飞书插件

```bash
# 进入目录
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm

# 卸载旧版
rm -rf node_modules/@openclaw/feishu

# 清除缓存
npm cache clean --force

# 重新安装
npm install @openclaw/feishu --registry https://registry.npmmirror.com

# 重启
systemctl --user restart openclaw-gateway
```

### 完全重装微信插件

```bash
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm
rm -rf node_modules/@tencent-weixin/openclaw-weixin
npm install @tencent-weixin/openclaw-weixin --registry https://registry.npmmirror.com
systemctl --user restart openclaw-gateway
```

### 查看运行日志

```bash
# 实时查看 OpenClaw 日志
journalctl --user -u openclaw-gateway -f

# 最近 100 行日志
journalctl --user -u openclaw-gateway -n 100
```

---

## 插件版本说明

| 插件 | npm 包名 | 当前推荐版本 |
|------|---------|------------|
| 飞书 | `@openclaw/feishu` | 2026.5.3 |
| 微信 | `@tencent-weixin/openclaw-weixin` | 2.4.1 |

> ⚠️ 以上为 2026 年 5 月信息，实际请以 npm 官方最新为准。

---

## 技术支持

遇到问题可以在 fnOS 社区论坛发帖，或提交 GitHub Issue：
- GitHub 仓库：https://github.com/a807866778/fnos-channel-fix
