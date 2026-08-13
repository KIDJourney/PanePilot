# Architecture

本文档维护 PanePilot 当前技术架构和边界。

## 当前架构

PanePilot 是一个 Swift Package 组织的 macOS App。核心布局计算在 `PanePilotCore`，AppKit、Carbon hotkey 和 Accessibility 适配在 `PanePilot` executable target。

```text
Global hotkey / Status menu
  -> WindowCommander
     -> AccessibilityWindowClient
        -> frontmost app AX focused/main window
        -> system-wide focused window fallback
        -> NSScreen visible frames
     -> PanePilotCore.LayoutEngine
        -> target CGRect
     -> AXUIElement position / size write

Settings > Launch at Login
  -> LoginItemController
     -> SMAppService.mainApp
     -> LoginItemStatusPolicy
        -> enabled / disabled / requires approval / error presentation
```

## 模块职责

| 路径 | 职责 |
|---|---|
| `Sources/PanePilotCore/WindowAction.swift` | 窗口动作枚举和菜单标题 |
| `Sources/PanePilotCore/LayoutEngine.swift` | 纯几何布局计算，可单测 |
| `Sources/PanePilotCore/LoginItemStatusPolicy.swift` | 把系统登录项状态转换成可单测的开关、提示和操作状态 |
| `Sources/PanePilot/main.swift` | AppKit app 入口，设置 accessory activation policy |
| `Sources/PanePilot/AppDelegate.swift` | 图形状态栏入口、分组原生菜单、命令绑定、启动时注册快捷键 |
| `Sources/PanePilot/HotKeyManager.swift` | Carbon `RegisterEventHotKey` 全局快捷键 |
| `Sources/PanePilot/ShortcutStore.swift` | 用户快捷键覆盖、禁用状态和默认值合并 |
| `Sources/PanePilot/LoginItemController.swift` | 通过 `SMAppService.mainApp` 注册或注销主 App 登录项，并提供隔离的真实系统自动化入口 |
| `Sources/PanePilot/PreferencesWindowController.swift` | 登录项开关、分组快捷键设置、逐行录制/清除、冲突检查和截图自动化 |
| `Sources/PanePilot/AccessibilityWindowClient.swift` | Accessibility 权限、聚焦窗口读取和窗口位置写入 |
| `Sources/PanePilot/WindowCommander.swift` | 命令编排、撤销/重做历史 |
| `Sources/PanePilot/AutomationWindowMoveTest.swift` | 本地真实桌面窗口移动自动化入口 |
| `Resources/AppIcon.png` | 透明 1024 px AppIcon 源图 |
| `Scripts/build-app.sh` | release build、从源图生成 ICNS、bundle Info.plist、ad-hoc signing |
| `Scripts/package-app.sh` | 生成 GitHub artifact / release zip |
| `Scripts/release-local.sh` | Developer ID 签名、公证、staple、DMG 和 GitHub Release 上传 |
| `Scripts/release-tag.sh` | 高层正式发布入口，可复用 notary profile |
| `Scripts/verify-release.sh` | 下载 GitHub Release DMG 并校验 sha256、公证和 Gatekeeper |
| `Scripts/launch-release-app.sh` | 从最终 DMG 启动 App 并验证进程存活 |
| `.github/workflows/ci.yml` | push / PR 自动验证、构建、测试、打包 |

## 坐标系统

Accessibility API 使用全局左上角坐标；`NSScreen` 使用 Cocoa 坐标。`AccessibilityWindowClient` 把 `NSScreen.visibleFrame` 转换成 Accessibility 坐标后传给 `LayoutEngine`，避免布局层依赖 AppKit。

聚焦窗口读取优先使用 `NSWorkspace.shared.frontmostApplication` 对应进程的 `AXFocusedWindow` / `AXMainWindow`。这是为新 macOS 上 system-wide `AXFocusedWindow` 可能返回 `kAXErrorCannotComplete` 的情况做的主路径修复；system-wide focused window 仅作为 fallback。

## 权限和发布

PanePilot 需要 macOS Accessibility 权限才能控制其他 App 的窗口。登录时启动使用 macOS 13+ 的 `SMAppService.mainApp`，不安装辅助程序；系统返回 `requiresApproval` 时由用户在“系统设置 > 通用 > 登录项与扩展”中批准。当前本地和 CI 快速产物使用 ad-hoc signing，仅用于开发和预览；登录项真实系统测试和正式 GitHub Release 使用 Developer ID 签名，Release 还会完成公证和 stapling。

## CI / Release

CI 运行在 `macos-26`，这是 GitHub hosted runners 的标准 Apple Silicon macOS 26 label。项目使用 Swift 6.2 且目标是现代 Apple Silicon macOS。普通代码变更通过 `ci.yml` 上传 ad-hoc zip artifact；正式 GitHub Release 由本地 `make release-tag TAG=vx.y.z` 创建签名公证 DMG。

## 技术风险

1. 某些 App 对窗口最小尺寸或网格尺寸有约束，最终窗口尺寸可能与目标布局不同。
2. 当前正式 release 依赖本机 Developer ID 证书和 notarytool profile；证书或 Apple 凭证失效会阻塞发布。
3. 当前只发布 Apple Silicon DMG；如需要 Intel Mac，需要增加 x86_64 或 universal 构建策略。
4. 真实窗口移动自动化必须在已解锁、活跃用户桌面运行；锁屏或 `loginwindow` 前台时无法验证用户窗口。
