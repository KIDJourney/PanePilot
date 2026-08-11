# Decisions

本文档记录影响未来工作的设计决策。新增重大决策时，按模板追加到最上方或创建独立 ADR 文件。

## DEC-0003: 用 GitHub Actions 自动打包和发布

| 字段 | 内容 |
|---|---|
| 日期 | 2026-08-11 |
| 状态 | 已接受 |
| 背景 | 项目需要 GitHub Release，且每次代码变更都需要自动化打包 |
| 决策 | push / PR 运行 CI 并上传 app zip artifact；推送 `v*` tag 自动创建 GitHub Release |
| 理由 | 让普通变更也有可下载构建产物，同时把正式 release 固定到不可变 tag |
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
