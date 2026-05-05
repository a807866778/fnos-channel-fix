# fnos-channel-fix

> 飞牛 fnOS + OpenClaw 插件安装与修复工具包

[![GitHub stars](https://img.shields.io/github/stars/a807866778/fnos-channel-fix?style=flat)](https://github.com/a807866778/fnos-channel-fix/stargazers)

---

## 工作流程

```
用户升级/降级 OpenClaw
       ↓
插件可能出现版本不兼容
       ↓
触发 fnos-plugin-install skill（自然语言）
       ↓
自动诊断 + 修复/降级插件 → 完成
```

---

## 第一步：安装 Skill 到你的 OpenClaw

> 不需要 SSH！只需要把下面这段话发给你的 OpenClaw，AI Agent 会自动完成安装。

```
请帮我安装 fnos-channel-fix skill：
https://github.com/a807866778/fnos-channel-fix

安装完成后告诉我结果。
```

OpenClaw 会自动执行 `npx -y skills add` 命令完成安装。
安装完成后，直接说自然语言来管理插件。

| 你说 | OpenClaw 自动做 |
|------|--------------|
| "帮我装飞书插件" | 检测 → npm 安装 → 重启 → 验证 |
| "帮我装微信插件" | 检测 → npm 安装 → 重启 → 验证 |
| "我的飞书机器人不能用了" | 诊断 → 修复/重装 → 验证 |
| "升级飞书插件" | 检测版本 → 升级 → 验证 |

---

## 第二步：升级 OpenClaw 主体（需要 SSH 手动操作）

> upgrade_openclaw.sh 是 bash 脚本，不是 skill，需要 SSH 执行。

```bash
# SSH 登录 fnOS，执行这条命令（一键下载+运行）
curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/install.sh -o /tmp/install.sh && chmod +x /tmp/install.sh && sudo bash /tmp/install.sh
```

或者分步执行：

```bash
# 1. SSH 登录 fnOS
ssh 你的用户名@fnOS的IP

# 2. 下载安装工具
curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/install.sh -o /tmp/install.sh
chmod +x /tmp/install.sh

# 3. 运行（自动下载脚本并以 root 执行）
bash /tmp/install.sh
```

安装工具会自动把最新版的 `upgrade_openclaw.sh` 下载到 `/tmp/`，然后以 root 执行。

---

## 前提条件

- 飞牛 fnOS 系统
- OpenClaw 已安装并运行
- fnOS 能访问 GitHub
- SSH 连接 fnOS 执行一次 skill 安装（仅首次）

---

## 插件版本参考

| 插件 | npm 包名 | 最新版本 |
|------|---------|---------|
| 飞书 | `@openclaw/feishu` | 2026.5.3 |
| 微信 | `@tencent-weixin/openclaw-weixin` | 2.4.1 |

> 获取最新版本：`npm view @openclaw/feishu version`

---

## 目录结构

```
fnos-channel-fix/
├── fnos-channel-fix.skill     # Skill 包（OpenClaw 直接识别安装）
├── SKILL.md                   # Skill 逻辑说明（给 AI Agent 看的）
├── fnos-plugin-install/       # 插件安装子模块
│   └── SKILL.md
├── upgrade_openclaw.sh        # OpenClaw 主体升级脚本（需要 root）
├── install.sh                 # 下载+执行工具（下载脚本并运行）
├── README.md                  # 本文件
├── FORUM_POST.md             # 论坛发帖模板
└── references/
    └── troubleshooting.md    # 故障排查详解
```

---

## 常见问题

**Q: skill 安装需要 SSH，那不是还是要用命令行？**

A: 是的，但只需要执行一次 `npx -y skills add ...` 命令。装好之后所有插件管理都通过自然语言完成，**不需要再 SSH**。

**Q: 升级 OpenClaw 后插件还能用吗？**

A: 可以正常使用。但如果遇到插件问题（版本不兼容、加载失败等），直接说"飞书机器人不能用了"，skill 会自动修复。

**Q: 安装失败了怎么办？**

A: 确保 fnOS 能访问 GitHub。也可以通过 SSH 手动管理插件，参考 `references/troubleshooting.md`。

---

## 社区与支持

- GitHub Issues：https://github.com/a807866778/fnos-channel-fix/issues
- fnOS 社区论坛：https://club.fnnas.com/

---

## 免责说明

本工具免费开源，使用前请务必确认配置已备份。作者不对因使用本工具造成的任何数据损失负责。
