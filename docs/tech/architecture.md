# Architecture

本文档维护 PanePilot 当前技术架构和边界。

## 当前架构

PanePilot 是一个 Swift Package 组织的 macOS App。核心布局计算在 `PanePilotCore`，AppKit、Carbon hotkey 和 Accessibility 适配在 `PanePilot` executable target。

```text
Global hotkey / Status menu
  -> WindowCommander
     -> AccessibilityWindowClient
        -> AXUIElement focused window
        -> NSScreen visible frames
     -> PanePilotCore.LayoutEngine
        -> target CGRect
     -> AXUIElement position / size write
```

## 模块职责

| 路径 | 职责 |
|---|---|
| `Sources/PanePilotCore/WindowAction.swift` | 窗口动作枚举和菜单标题 |
| `Sources/PanePilotCore/LayoutEngine.swift` | 纯几何布局计算，可单测 |
| `Sources/PanePilot/main.swift` | AppKit app 入口，设置 accessory activation policy |
| `Sources/PanePilot/AppDelegate.swift` | 状态栏菜单、命令绑定、启动时注册快捷键 |
| `Sources/PanePilot/HotKeyManager.swift` | Carbon `RegisterEventHotKey` 全局快捷键 |
| `Sources/PanePilot/AccessibilityWindowClient.swift` | Accessibility 权限、聚焦窗口读取和窗口位置写入 |
| `Sources/PanePilot/WindowCommander.swift` | 命令编排、撤销/重做历史 |
| `Scripts/build-app.sh` | release build、bundle Info.plist、ad-hoc signing |
| `Scripts/package-app.sh` | 生成 GitHub artifact / release zip |
| `.github/workflows/ci.yml` | push / PR 自动验证、构建、测试、打包 |
| `.github/workflows/release.yml` | tag / 手动触发 GitHub Release |

## 坐标系统

Accessibility API 使用全局左上角坐标；`NSScreen` 使用 Cocoa 坐标。`AccessibilityWindowClient` 把 `NSScreen.visibleFrame` 转换成 Accessibility 坐标后传给 `LayoutEngine`，避免布局层依赖 AppKit。

## 权限和发布

PanePilot 需要 macOS Accessibility 权限才能控制其他 App 的窗口。当前本地和 CI 产物使用 ad-hoc signing，可用于开发和预览。正式分发前需要 Developer ID 签名、公证和 stapling。

## CI / Release

CI 运行在 `macos-26`，这是 GitHub hosted runners 的标准 Apple Silicon macOS 26 label。项目使用 Swift 6.2 且目标是现代 Apple Silicon macOS。普通代码变更通过 `ci.yml` 上传 zip artifact；推送 `v*` tag 通过 `release.yml` 创建 GitHub Release。

## 技术风险

1. 某些 App 对窗口最小尺寸或网格尺寸有约束，最终窗口尺寸可能与目标布局不同。
2. 未配置 Developer ID 前，GitHub Release 产物不是正式公证分发包。
3. 当前只发布 arm64 zip；如需要 Intel Mac，需要增加 x86_64 或 universal 构建策略。
