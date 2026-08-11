# Agent Context

本文档维护未来 agent 启动时需要快速恢复的当前上下文。

## 当前状态

PanePilot 当前是 v0.1 初版：Swift 6.2、macOS 14+、Apple Silicon 优先、菜单栏 App、Accessibility API 控制聚焦窗口。GitHub 仓库为 `KIDJourney/PanePilot`。

## 默认假设

1. `main` 是发布主线。
2. 每次代码变更都要通过 GitHub Actions 自动构建、测试和打包。
3. Release 通过 `v*` tag 触发，不手工上传本地产物作为常规流程。
4. 当前 CI 产物是 ad-hoc signed arm64 zip，不等同于正式公证分发包。
5. `docs/` 是长期知识库；`AGENTS.md` 是跨 agent 的统一入口。

## 已完成

- 新建 Swift Package 项目。
- 实现菜单栏 App、默认快捷键、Accessibility 窗口移动、撤销/重做。
- 添加 `make app` 和 `make package`。
- 初始化 AI Workspace 文档结构。
- 添加 GitHub Actions CI 和 Release workflow。

## 下一步

1. 后续考虑快捷键偏好设置和 Developer ID 公证发布。
2. 如果要支持 Intel Mac，设计 universal binary 或独立 x86_64 artifact。
3. 增加真实桌面手工验收记录，尤其是 Accessibility 权限和多显示器。
