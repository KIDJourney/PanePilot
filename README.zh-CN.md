<p align="center">
  <img src="Resources/AppIcon.png" width="144" alt="PanePilot 应用图标">
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

# PanePilot

用键盘整理 macOS 窗口，让双手留在正在做的事情上。

PanePilot 是一款面向 Apple 芯片 Mac 的轻量菜单栏工具。它通过全局快捷键，把当前聚焦窗口移动到半屏、角落、三分屏、其他显示器或居中位置；如果布局还需要再调整，也可以通过撤销和重做回到最近的排列状态。

[下载最新签名版本](https://github.com/KIDJourney/PanePilot/releases/latest) | macOS 14 或更高版本 | Apple 芯片

## 适合这些场景

### 一边写代码，一边看结果

把编辑器放在左侧，把浏览器、模拟器或终端放在右侧。需要同时参考第三个窗口时，可以把其中一个窗口快速移到角落，不必反复拖动边框。

### 查资料时不丢失上下文

让笔记占据一半屏幕，在另一半或三分屏位置切换资料。进入专注阅读或写作时，再把文档居中或最大化。

### 在多显示器之间演示和工作

把当前窗口发送到上一台或下一台显示器，并尽量保持它原来的相对大小和位置。PanePilot 会遵守每块屏幕的可用区域，包括菜单栏和 Dock 占用的空间。

### 放心尝试不同布局

循环切换三分屏、放大或缩小窗口，再使用撤销和重做浏览最近的 PanePilot 操作，不需要手动还原每一步。

## 快速开始

1. 从 [GitHub Releases](https://github.com/KIDJourney/PanePilot/releases/latest) 下载最新 DMG。
2. 把 PanePilot 拖入“应用程序”并打开。
3. 在“系统设置 > 隐私与安全性 > 辅助功能”中允许 PanePilot。
4. 点击菜单栏中的 PanePilot 图标，或直接使用全局快捷键。

希望每次开机后都能直接使用 PanePilot，可打开 **Settings...** 并启用 **Launch at Login**。如果 macOS 要求确认，PanePilot 会提供“登录项”系统设置的直达入口。

公开发布的版本会先使用 Developer ID 证书签名，再通过 Apple 公证并完成 stapling 后上传。

## 布局与快捷键

| 任务 | 动作 | 默认快捷键 |
| --- | --- | --- |
| 专注 | 居中 | Option-Command-C |
| 专注 | 最大化 | Option-Command-F |
| 分屏 | 左半屏 / 右半屏 | Option-Command-左 / 右方向键 |
| 分屏 | 上半屏 / 下半屏 | Option-Command-上 / 下方向键 |
| 平铺 | 左上角 / 右上角 | Control-Command-左 / 右方向键 |
| 平铺 | 左下角 / 右下角 | Control-Shift-Command-左 / 右方向键 |
| 循环 | 下一个 / 上一个三分屏 | Control-Option-右 / 左方向键 |
| 缩放 | 放大 / 缩小 | Control-Option-Shift-右 / 左方向键 |
| 显示器 | 下一台 / 上一台显示器 | Control-Option-Command-右 / 左方向键 |
| 历史 | 撤销 / 重做 | Option-Command-Z / Option-Shift-Command-Z |

打开菜单栏图标并选择 **Settings...**，即可设置登录时启动、录制新的快捷键、禁用单个动作或恢复全部默认值。修改会立即生效。

## 隐私与权限

PanePilot 完全在本机工作，不需要账号或网络连接。由于整理窗口需要通过 macOS Accessibility API 控制其他应用的聚焦窗口，因此必须授予辅助功能权限。

## 从源码构建

PanePilot 使用 Swift 6.2，支持 macOS 14 或更高版本。

```sh
swift build
swift test
make validate-docs
make verify-hotkey-dispatch
make verify-window-move
make package
open dist/PanePilot.app
```

桌面自动化检查需要 Mac 处于解锁状态，并且有活跃的用户桌面。`make package` 生成用于开发预览的 ad-hoc 签名产物；公开 GitHub Release 使用 [AGENTS.md](AGENTS.md) 中约定的 Developer ID 签名与公证流程。

## 鸣谢

- [Spectacle](https://github.com/eczarny/spectacle) 建立了直接、键盘优先的窗口管理方式，也是 PanePilot 最初的灵感来源。
- [Rectangle](https://github.com/rxhanson/Rectangle) 延续了开源 macOS 窗口管理工具的传统，并为现代系统支持范围提供了参考。
