# fnos-channel-fix

> 飞牛 fnOS + OpenClaw 插件安装与修复工具包

[![GitHub stars](https://img.shields.io/github/stars/a807866778/fnos-channel-fix?style=flat)](https://github.com/a807866778/fnos-channel-fix/stargazers)

---

## 这个工具包有什么用？

装好之后，直接跟 OpenClaw 说人话就能管理飞书/微信插件，**不需要 SSH，不需要进小黑框**。

| 你跟 OpenClaw 说 | OpenClaw 自动做 |
|-----------------|---------------|
| "帮我安装飞书插件" | 检测环境 → npm 安装 → 重启 → 验证 |
| "我的微信机器人坏了" | 诊断问题 → 重装/修复 → 验证 |
| "飞书机器人没反应了" | 检查状态 → 给出解决方法 |

---

## 第一步：先把工具包安装到你的 OpenClaw

> ⚠️ 这一步需要通过 SSH 连接 fnOS 执行**一次**，之后就不需要了。

用 SSH 登录你的 fnOS，执行这条命令：

```bash
npx -y skills add https://github.com/a807866778/fnos-channel-fix --skill
```

等待出现 `✓ done` 即表示安装成功。

![skill 安装示意](https://img.shields.io/badge/-blue?style=for-the-badge)

---

## 第二步：开始使用

安装完成后，直接在 OpenClaw 对话里说人话：

### 安装飞书插件

```
帮我装一下飞书插件
```
或
```
安装飞书插件
```

### 安装微信插件

```
帮我装微信插件
```
或
```
安装微信插件
```

### 修复插件问题

```
我的飞书机器人不能用了
```
```
微信通道坏了，帮我修一下
```
```
飞书机器人没反应了
```

### 升级插件到最新版

```
升级飞书插件到最新版本
```
```
更新微信插件
```

---

## 它是怎么工作的？

当你说「帮我装飞书插件」，OpenClaw 内部发生的事：

```
你发送消息
    ↓
OpenClaw 匹配到 fnos-plugin-install skill
    ↓
Skill 自动检测 fnOS 安装路径
    ↓
执行 npm install @openclaw/feishu（安装到正确目录）
    ↓
复制到 OpenClaw 扩展目录
    ↓
重启 OpenClaw 网关
    ↓
验证结果并告诉你
```

**全程你只需要说话，不需要输入任何命令。**

---

## 前提条件

- 飞牛 fnOS 系统
- OpenClaw 已安装并运行
- fnOS 能访问网络（下载插件用）
- SSH 连接 fnOS 执行一次安装命令（仅首次需要）

---

## OpenClaw 升级脚本（独立使用）

本仓库也包含 OpenClaw 主体升级脚本，安装 skill 后可以这样触发：

```
帮我升级 OpenClaw 到最新版本
```

或手动通过 SSH 升级：

```bash
# 连接到 fnOS
ssh 你的用户名@fnOS的IP

# 下载并运行升级脚本
sudo -i bash <(curl -L https://raw.githubusercontent.com/a807866778/fnos-channel-fix/main/upgrade_openclaw.sh)
```

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
├── fnos-channel-fix.skill     # Skill 安装包（OpenClaw 直接识别）
├── SKILL.md                   # Skill 逻辑说明（给 AI Agent 看的）
├── fnos-plugin-install/       # 插件安装子模块
│   └── SKILL.md
├── upgrade_openclaw.sh        # OpenClaw 主体升级脚本（需要 root）
├── install.sh                 # 一键下载升级脚本的工具
├── README.md                 # 本文件
├── FORUM_POST.md             # 论坛发帖模板
└── references/               # 参考资料
    └── troubleshooting.md    # 故障排查详解
```

---

## 常见问题

**Q: 安装 skill 需要 SSH，那不是还是要用命令行？**

A: 是的，首次安装需要 SSH 执行一次 `npx -y skills add` 命令，这是 OpenClaw 的 skill 安装机制决定的。但这只是**一次性的**，装好之后所有插件管理都可以用自然语言操作，不需要再 SSH。

**Q: 安装 skill 需要多久？**

A: 通常 1-2 分钟，主要时间花在下载 Skill 包上。

**Q: 安装失败了怎么办？**

A: 确保 fnOS 能访问 GitHub（有些网络环境需要代理）。也可以直接通过 SSH 手动管理插件，参考 `references/troubleshooting.md`。

**Q: 升级 OpenClaw 后插件还能用吗？**

A: 可以，升级主体不影响插件。但如果遇到插件问题，重新说一句"帮我重装飞书插件"即可。

**Q: 微信和飞书可以同时安装吗？**

A: 可以，分别说"帮我装飞书插件"和"帮我装微信插件"即可。

---

## 社区与支持

- GitHub Issues：https://github.com/a807866778/fnos-channel-fix/issues
- fnOS 社区论坛：https://club.fnnas.com/

---

## 免责说明

本工具免费开源，使用前请务必确认插件配置已备份。作者不对因使用本工具造成的任何数据损失负责。
