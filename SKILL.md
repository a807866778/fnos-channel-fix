# fnos-channel-fix

> **来源说明**：
> - 原始脚本来自飞牛社区论坛帖子：https://club.fnnas.com/forum.php?mod=viewthread&tid=61202
> - 改造新增：社区插件保护、安装、恢复备份等功能
> - 飞书插件：`@openclaw/feishu`（npm）
> - 微信插件：`@tencent-weixin/openclaw-weixin`（npm）

修复 fnOS OpenClaw 升级后飞书/微信通道失效的问题。

## 功能概览

| 功能 | 说明 |
|------|------|
| 一键升级 | 自动备份 + 保护社区插件 + 修复微信配置 |
| 恢复备份 | 从备份中恢复数据 |
| 通道修复 | 安装/重装飞书、微信插件 |
| 版本检测 | 自动识别旧环境/全新环境 |

## 一键安装

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

# 查看帮助
bash upgrade_openclaw.sh --help
```

## 升级后操作

1. 飞牛应用管理 → 重启 OpenClaw
2. 等待 30 秒后验证：`openclaw channels list`
3. **微信**：重新扫码（飞牛应用管理 → OpenClaw → 微信通道）
4. **飞书**：在飞书中发送 `/feishu auth`

## 遇到问题时的处理

### 飞书/微信插件未安装或通道不显示

```bash
# 查看当前插件状态
openclaw plugins list

# 查看通道状态
openclaw channels list

# 查看 gateway 日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

### 插件已安装但通道不回复

```bash
# 检查插件是否有错误
openclaw plugins inspect feishu
openclaw plugins inspect openclaw-weixin

# 检查微信配置是否为空（导致通道被跳过）
openclaw config get channels.openclaw-weixin
# 如果输出 {}，需要修复：
openclaw config set channels.openclaw-weixin '{"accounts":{}}' --json
```

### 升级后想回退

```bash
# 列出备份并恢复
bash upgrade_openclaw.sh --restore
```

## 技术背景

| 问题 | 原因 | 解决 |
|------|------|------|
| 飞书插件 loaded 但不回复 | npm 缓存和 bundled extensions 冲突 | 清理 npm 缓存，复制到 extensions |
| 微信空配置 `{}` 被跳过 | `hasMeaningfulChannelConfig({})` 返回 false | 设置 `{"accounts":{}}` |
| 插件 ownership 报错 | fnOS 安全策略要求 root:root | `chown -R root:root` 修复权限 |
| 升级后插件丢失 | 升级脚本清空 node_modules | 升级前备份插件 |

## 相关链接

- 飞牛社区原帖：https://club.fnnas.com/forum.php?mod=viewthread&tid=61202
- GitHub 仓库：https://github.com/a807866778/fnos-channel-fix
