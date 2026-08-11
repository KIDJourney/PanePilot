# PanePilot PRD

本文档维护 PanePilot 当前产品定义、功能范围和实现进展。

## 产品定位

PanePilot 是一个现代 Swift 版 macOS 菜单栏窗口管理器。它复刻 Spectacle 的核心价值：用户不用鼠标，通过全局快捷键快速移动、缩放和整理当前聚焦窗口。

## 目标用户

| 用户 | 需求 |
|---|---|
| macOS 重度键盘用户 | 希望用快捷键完成半屏、四角、全屏、居中和跨屏移动 |
| Spectacle 老用户 | 希望获得类似默认快捷键，但能在新 macOS 和 Apple Silicon 上维护下去 |
| 开源维护者 | 希望项目结构简单，可自动构建、测试、打包和发布 |

## 核心问题

1. Spectacle 已不再活跃维护，旧 Objective-C/Carthage 工程不适合直接延续。
2. 新 macOS 对辅助功能权限、签名、公证和自动化发布有更明确要求。
3. 窗口管理工具必须可靠处理多显示器、可见区域、菜单栏/Dock 和撤销重做。
4. 每次代码变更都需要自动化打包，避免本地手工构建造成 release 漂移。

## 当前版本范围

| 功能 | 定义 | 当前进展 |
|---|---|---|
| 菜单栏 App | 无 Dock 图标，通过状态栏菜单提供命令入口 | 已完成初版 |
| 全局快捷键 | 使用 Spectacle 风格默认快捷键触发窗口操作 | 已完成初版 |
| 窗口布局 | 支持居中、最大化、半屏、四角、三分屏、放大缩小 | 已完成初版 |
| 多显示器移动 | 在显示器之间移动窗口并保持相对位置 | 已完成初版 |
| 撤销 / 重做 | 记录窗口移动历史并恢复 | 已完成初版 |
| 本地打包 | 生成 ad-hoc signed `.app` 和 zip 包 | 已完成初版 |
| GitHub CI | 每次 push / PR 自动验证、构建、测试、打包 artifact | 已完成初版 |
| GitHub Release | 本地 release 脚本生成签名公证 DMG 并上传 GitHub Release | 已完成初版 |

## 当前不做

| 范围 | 说明 |
|---|---|
| 拖拽吸附 | 第一版聚焦快捷键窗口管理，不追 Rectangle 的 snap areas |
| 偏好设置 UI | 第一版固定默认快捷键，后续再做可编辑快捷键 |
| GitHub Actions 签名发布 | 当前正式发布依赖本机 Developer ID 证书；CI 只做 ad-hoc artifact |
| App Store 发布 | 窗口管理工具依赖 Accessibility 权限，当前目标是 GitHub Release |

## 用户故事

1. 作为 Spectacle 老用户，我希望沿用熟悉快捷键，把窗口移动到半屏、四角或全屏。
2. 作为多显示器用户，我希望能用快捷键把当前窗口移动到下一块显示器。
3. 作为键盘用户，我希望窗口操作可撤销，误触后能快速恢复。
4. 作为维护者，我希望每次代码变更都自动生成可下载构建产物。
5. 作为发布者，我希望一条命令生成签名、公证、可通过 Gatekeeper 的 GitHub Release。

## 后续需求池

| 需求 | 状态 | 定义 |
|---|---|---|
| 快捷键偏好设置 | 未开始 | 提供 UI 修改或禁用默认快捷键 |
| Developer ID 发布 | 已完成初版 | 复用本机 Developer ID 证书、notarytool 和 stapler，生成可正式分发 DMG |
| Universal binary | 未开始 | 如需要同时覆盖 Intel Mac，增加 x86_64 构建或 universal packaging |
| 窗口约束适配 | 未开始 | 对 Terminal 等有最小尺寸/网格约束的 App 做更细的 best-effort 调整 |
