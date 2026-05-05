# fnos-channel-fix

> 飞牛 fnOS + OpenClaw 一键升级工具 + 插件安装指南

[![GitHub stars](https://img.shields.io/github/stars/a807866778/fnos-channel-fix?style=flat)](https://github.com/a807866778/fnos-channel-fix/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 快速开始

### 第一步：下载升级脚本

在 fnOS 上下载脚本（通过 SSH 连接）：

```bash
# 连接到 fnOS（将 IP 替换为你的机器 IP）
ssh fnos用户名@fnos机器IP

# 下载脚本
cd /tmp
curl -L https://github.com/a807866778/fnos-channel-fix/raw/main/upgrade_openclaw.sh -o upgrade_openclaw.sh
chmod +x upgrade_openclaw.sh
```

### 第二步：运行升级

```bash
# 交互式升级（推荐新手）
sudo -i bash /tmp/upgrade_openclaw.sh

# 或直接指定版本
sudo -i bash /tmp/upgrade_openclaw.sh 2026.5.4
```

---

## 功能说明

本仓库包含两个独立部分：

| 文件 | 作用 |
|------|------|
| `upgrade_openclaw.sh` | 升级 OpenClaw 主体版本（**脚本，需要 root**） |
| `fnos-plugin-install skill` | 飞书/微信插件安装引导（**Skill**） |
| `SKILL.md` | 插件安装详细文档（面向新手用户） |

---

## upgrade_openclaw.sh 脚本

### 功能

- ✅ 自动检测 fnOS OpenClaw 安装路径
- ✅ 智能判断新用户/老用户
- ✅ 全量备份当前数据
- ✅ 下载并升级 OpenClaw 主体
- ✅ 自动修复微信通道空配置陷阱
- ✅ 保留自定义 Skills 不丢失

### 系统要求

- 飞牛 fnOS 系统
- OpenClaw 已安装
- SSH 访问权限（需要能执行 `sudo -i`）

### 使用方法

```bash
# 进入脚本目录
cd /tmp

# 交互式升级（直接回车升级到最新稳定版）
sudo -i bash upgrade_openclaw.sh

# 查看当前版本
sudo -i bash upgrade_openclaw.sh --verify

# 恢复到备份
sudo -i bash upgrade_openclaw.sh --restore
```

### 工作原理

脚本在 OpenClaw 的 **managed-install 目录**内执行 `npm install`，不会污染系统目录，也不会破坏现有配置。

### 故障排除

| 问题 | 解决方法 |
|------|---------|
| 报 `EACCES permission denied` | 确认使用了 `sudo -i` 进入 root 身份 |
| 升级后版本没变 | 等待 30 秒再查，或重启 fnOS |
| 下载慢 | 脚本自动尝试多个镜像（npmmirror / 腾讯 / 华为） |
| 微信通道空了 | 脚本会自动修复，重新扫码即可 |

---

## 插件安装（SKILL.md）

飞书和微信插件的安装、重装、配置，**不在脚本里**，而在 `SKILL.md` 文档中。

### 为什么插件要单独处理？

OpenClaw 升级脚本**不负责插件安装**，原因：

1. 插件安装需要在 OpenClaw 配置页操作，网页端更安全
2. 插件授权（飞书 OAuth）需要用户在浏览器里完成
3. 避免脚本操作失误破坏插件配置

### 快速安装飞书插件

```bash
# 连接到 fnOS 并进入 root
ssh fnos用户名@fnos机器IP
sudo -i

# 安装飞书插件
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm
npm install @openclaw/feishu --registry https://registry.npmmirror.com

# 重启 OpenClaw
systemctl --user restart openclaw-gateway
```

然后在飞书中给机器人发 `/feishu auth` 完成授权。

### 快速安装微信插件

```bash
sudo -i
cd /vol1/@apphome/trim.openclaw/data/home/.openclaw/npm
npm install @tencent-weixin/openclaw-weixin --registry https://registry.npmmirror.com
systemctl --user restart openclaw-gateway
```

详细步骤请阅读 [SKILL.md](./SKILL.md)。

---

## 目录结构

```
fnos-channel-fix/
├── README.md              # 本文件
├── SKILL.md               # 插件安装详细文档（面向新手）
├── fnos-plugin-install/   # 插件安装 Skill（给 AI Agent 看的）
│   └── SKILL.md
├── install.sh             # 一键安装脚本（安装 fnos-plugin-install skill）
├── upgrade_openclaw.sh    # OpenClaw 升级脚本（需要 root）
├── FORUM_POST.md          # 论坛发帖模板
└── references/            # 参考资料
    └── troubleshooting.md  # 故障排查
```

---

## 插件说明

| 插件 | npm 包名 | 官方/社区 | 当前版本 |
|------|---------|---------|---------|
| 飞书 | `@openclaw/feishu` | 社区 | 2026.5.3 |
| 微信 | `@tencent-weixin/openclaw-weixin` | 腾讯官方 | 2.4.1 |

> **注意**：飞书插件 `@openclaw/feishu` 是社区维护版本（非飞书官方），由 `@m1heng` 开发和维护。
> 飞书官方也提供了 `@larksuite/openclaw-lark` 插件，功能类似，可以二选一使用。

---

## 更新日志

### v12.0.0 (2026-05-05)
- 移除插件安装逻辑，脚本专注于 OpenClaw 主体升级
- 插件安装移至独立 SKILL.md 文档
- 优化 sudo 环境变量处理（修复 bun 找不到的问题）
- 修复 download_package 多镜像重试逻辑

### v11.x (2026-05-04)
- 早期版本，插件逻辑与升级脚本混在一起

---

## 贡献指南

欢迎提交 Issue 和 Pull Request！

遇到问题请先：
1. 查看 [SKILL.md](./SKILL.md) 常见问题
2. 查看 [references/troubleshooting.md](./references/troubleshooting.md)
3. 确认 OpenClaw 和 fnOS 版本
4. 提交 Issue 并附上日志

---

## 免责声明

本工具免费开源，使用前**请务必备份数据**。作者不对因使用本工具造成的任何数据损失负责。
