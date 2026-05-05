# 详细原理与调试参考

## OpenClaw 通道启动流程

1. `collectConfiguredChannelIds` 收集所有通道 ID，来源：
   - `channels.*` 配置（需要 `hasMeaningfulChannelConfig` 返回 true）
   - 环境变量（`FEISHU_*`、`WEIXIN_*`）
   - 持久化凭证（`~/.openclaw/<channel-id>/accounts/`）

2. `collectBundledChannelOwnerPluginIds` 根据通道 ID 查找对应的 bundled 插件，插件必须在 `openclaw/dist/extensions/` 目录中。

3. 通道通过 `api.registerChannel()` 注册到网关。

## hasMeaningfulChannelConfig 源码

```typescript
function hasMeaningfulChannelConfig(value) {
    if (!isRecord(value)) return false;
    return Object.keys(value).some((key) => key !== "enabled");
}
```

判定逻辑：
- `{}` → false（无任何 key）
- `{enabled: true}` → false（只有 enabled）
- `{accounts: {}}` → true（有 accounts key）
- `{appId: "xxx"}` → true（有 appId key）

这就是为什么 `channels.openclaw-weixin: {}` 会被网关忽略。

## fnOS 插件安装路径

fnOS 管理服务器（`server/index.js`）拦截了 `plugins install` 命令，对社区插件：
- 飞书 `@openclaw/feishu` → 安装到 `~/.bun-home/.cache/openclaw@版本号/extensions/feishu/`
- 微信 `@tencent-weixin/openclaw-weixin` → 同上

而不是 bundled extensions 目录 `openclaw/dist/extensions/`。

## 路径安全校验

管理服务器以 root 运行时，加载插件时做路径安全检查：
- 插件 module path 必须在允许的插件根目录下
- symlink 指向 `~/.openclaw/npm/` 被判定为"路径逃逸"，插件被静默跳过

**注意**：这里报错的是管理服务器，不是网关本身。管理服务器的检查结果不影响网关是否加载插件，真正拦截网关加载的是 bundled plugins 列表机制。

## 调试命令

```bash
# 查看所有发现的插件
openclaw plugins list

# 查看插件详情
openclaw plugins inspect openclaw-weixin
openclaw plugins inspect feishu

# 刷新插件注册表
openclaw plugins registry --refresh --json | python3 -m json.tool | grep -A5 '"feishu"'

# 查看网关启动日志（找 starting channels and sidecars）
grep "starting channels" /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 查看外部连接（飞书连接字节跳动服务器）
ss -tp | grep openclaw | grep -v "127.0.0.1"

# 查看微信凭证是否存成功
ls ~/.openclaw/openclaw-weixin/accounts/
cat ~/.openclaw/openclaw-weixin/accounts/*.json

# 查看飞书凭证
ls ~/.openclaw/accounts/
```

## 重启被阻塞的处理

网关在有活跃 session 时会延迟重启（ coalescing 机制），如果需要立即重启：

```bash
# 找到网关进程
pgrep -f "openclaw$"

# 强制 kill（SIGKILL 绕过 SIGUSR1 优雅重启）
kill -9 <pid>
```

## 飞书 WebSocket 连接说明

飞书通道使用 WebSocket 长连接接收消息，外部连接 IP 属于字节跳动（ByteDance）。如果：

- `ss -tp` 看到 openclaw 进程连接到外部 HTTPS/WSS 服务器 → 飞书在线
- 无外部连接，只有 127.0.0.1 本地连接 → 飞书未启动

微信使用 getUpdates 长轮询，不需要外部连接（微信服务器主动连接进来）。
