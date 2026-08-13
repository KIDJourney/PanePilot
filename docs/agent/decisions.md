# Decisions

本文档记录影响未来工作的设计决策。新增重大决策时，按模板追加到最上方或创建独立 ADR 文件。

## DEC-0005: 自更新只安装同签名身份的正式 GitHub Release

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-13 |
| 状态 | 已接受 |
| 背景 | 用户需要每天发现新版并在确认后自升级，同时公开产物已有 Developer ID 签名、公证和 sha256 |
| 决策 | 每天中午查询 latest Release；用户确认后校验 sha256、公证、Gatekeeper、bundle 元数据、signing identifier 和 Team ID，再由外部助手分阶段替换并支持启动失败回滚 |
| 理由 | 复用现有正式发布信任链，避免将未签名、异签名或损坏资产覆盖已安装 App |
| 影响 | Release 必须继续同时上传精确命名的 DMG 和 `.sha256`；签名身份变化需要显式迁移方案，不能由更新器静默接受 |

## DEC-0004: 正式 Release 使用本地 Developer ID 签名和公证

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-11 |
| 状态 | 已接受 |
| 背景 | GitHub Actions 的 ad-hoc zip 不能作为公开分发包；用户要求参考 SpeakMore 给 PanePilot 做 Apple 签名 |
| 决策 | 普通 CI 继续上传 ad-hoc artifact；正式 GitHub Release 由本机 `make release-tag TAG=vx.y.z` 创建 Developer ID signed、notarized、stapled DMG |
| 理由 | 本机已有 Developer ID 证书和 notarytool profile，能立即产出 Gatekeeper accepted 包；避免 tag workflow 误发未签名 zip |
| 影响 | 推 tag 不再自动发布；正式发版必须走本地 release 脚本并记录验证结果 |

## DEC-0003: 用 GitHub Actions 自动打包每次代码变更

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-11 |
| 状态 | 已接受 |
| 背景 | 项目需要 GitHub Release，且每次代码变更都需要自动化打包 |
| 决策 | push / PR 运行 CI 并上传 app zip artifact；正式 release 另走 Developer ID 本地发布脚本 |
| 理由 | 让普通变更也有可下载构建产物，同时避免把 ad-hoc CI 产物当作正式分发 |
| 影响 | 修改代码、打包脚本或 workflow 后必须关注 GitHub Actions 结果 |

## DEC-0002: 初版使用 Swift Package + AppKit，而不是迁移旧 Xcode 工程

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-10 |
| 状态 | 已接受 |
| 背景 | Spectacle 原项目已停止维护，Objective-C/Carthage 工程不适合直接延续 |
| 决策 | 从零实现 Swift 6.2 Swift Package，核心布局逻辑拆到 `PanePilotCore` |
| 理由 | 结构更小，便于测试和 GitHub Actions 自动构建 |
| 影响 | 不直接复用旧 Spectacle 代码；后续功能以 PanePilot 架构演进 |

## DEC-0001: 长期知识放在 `docs/`，入口放在 `AGENTS.md`

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-11 |
| 状态 | 已接受 |
| 背景 | 需要让未来 agent 快速理解产品、技术、测试、验证和发布状态 |
| 决策 | 使用根目录 `AGENTS.md` 作为统一入口，使用 `docs/` 作为长期知识库 |
| 理由 | `AGENTS.md` 是轻量跨工具入口；`docs/` 对人类和 agent 都直观 |
| 影响 | 后续新增长期事实优先写入 `docs/`；`AGENTS.md` 只维护索引和稳定规则 |
