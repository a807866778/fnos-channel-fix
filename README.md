# fnos-channel-fix

> **来源**：基于飞牛社区论坛帖子（https://club.fnnas.com/forum.php?mod=viewthread&tid=61202）改造，新增社区插件保护、安装、恢复备份功能。

修复 fnOS OpenClaw 升级后飞书/微信通道失效的问题。

## 一键安装（推荐）

```bash
sudo -i
curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

选 4 全部执行（下载脚本 → 修复通道 → 添加 Skill）

## 脚本用法

```bash
# 一键升级（直接回车升最新稳定版）
bash upgrade_openclaw.sh

# 升级到指定版本
bash upgrade_openclaw.sh 2026.5.3

# 升级到最新版本（含预发布）
bash upgrade_openclaw.sh latest

# 恢复备份
bash upgrade_openclaw.sh --restore

# 查看当前版本
bash upgrade_openclaw.sh --verify
```

## 包含内容

| 文件 | 说明 |
|------|------|
| `upgrade_openclaw.sh` | 主脚本：升级 + 备份 + 保护插件 |
| `install.sh` | 一键安装器 |
| `SKILL.md` | OpenClaw Agent Skill |
| `references/troubleshooting.md` | 根因分析与调试 |

## 插件来源

飞书（`feishu`）和微信（`openclaw-weixin`）插件均为 OpenClaw **内置（stock）插件**，位于 OpenClaw 包内部 `dist/extensions/feishu` 和 `dist/extensions/openclaw-weixin`，跟随 OpenClaw 主体版本更新，不单独发版。

- 当前内置版本：**2026.5.3**（与 OpenClaw 主体同步）
- GitHub changelog 最近一次更新（v2026.5.4）中**无飞书/微信插件相关改动**
- 通道失效根因：OpenClaw 升级后内置插件配置未正确迁移，需运行本脚本修复

## 插件来源

飞书和微信插件均通过 npm 安装，来源如下：

| 插件 | npm 包名 | 说明 |
|------|----------|------|
| 飞书 | `@openclaw/feishu` | 官方内置插件 |
| 微信 | `@tencent-weixin/openclaw-weixin` | 腾讯微信官方插件 |

安装由 `upgrade_openclaw.sh` 自动完成（`install_community_plugins` 函数），无需手动操作。

## 升级后操作

1. 飞牛应用管理 → 重启 OpenClaw
2. 等待 30 秒验证：`openclaw channels list`
3. **微信**：重新扫码（飞牛应用管理 → OpenClaw → 微信通道）
4. **飞书**：在飞书中发送 `/feishu auth`

## 遇到问题

### 通道不显示

```bash
openclaw channels list
openclaw plugins list | grep -E "feishu|weixin"
```

### 微信配置为空

```bash
openclaw config get channels.openclaw-weixin
# 如果返回 {}，修复：
openclaw config set channels.openclaw-weixin '{"accounts":{}}' --json
```

### 回退

```bash
bash upgrade_openclaw.sh --restore
```

## 相关链接

- 飞牛社区原帖：https://club.fnnas.com/forum.php?mod=viewthread&tid=61202
- GitHub 仓库：https://github.com/a807866778/fnos-channel-fix
