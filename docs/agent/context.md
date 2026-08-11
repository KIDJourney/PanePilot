# Agent Context

本文档维护未来 agent 启动时需要快速恢复的当前上下文。

## 当前状态

PanePilot 当前是 v0.1 初版：Swift 6.2、macOS 14+、Apple Silicon 优先、菜单栏 App、Accessibility API 控制聚焦窗口。GitHub 仓库为 `KIDJourney/PanePilot`。

## 默认假设

1. `main` 是发布主线。
2. 每次代码变更都要通过 GitHub Actions 自动构建、测试和打包。
3. 正式 Release 通过本地 `make release-tag TAG=vx.y.z` 触发，使用 Developer ID 签名、公证和 stapling。
4. 当前 CI 产物是 ad-hoc signed arm64 zip，只是每次变更的预览 artifact，不等同于正式分发包。
5. `docs/` 是长期知识库；`AGENTS.md` 是跨 agent 的统一入口。

## 已完成

- 新建 Swift Package 项目。
- 实现菜单栏 App、默认快捷键、Accessibility 窗口移动、撤销/重做。
- 添加 `make app` 和 `make package`。
- 初始化 AI Workspace 文档结构。
- 添加 GitHub Actions CI。
- 添加 Developer ID signed + notarized GitHub Release 脚本。

## 下一步

1. 如果要支持 Intel Mac，设计 universal binary 或独立 x86_64 artifact。
2. 增加真实桌面手工验收记录，尤其是 Accessibility 权限和多显示器。
