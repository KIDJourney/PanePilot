# Verification Log

本文档维护最近验证状态、证据和风险。

## 最近验证

| 日期 | 场景 | 变更 | 验证 | 结果 |
|---|---|---|---|---|
| 2026-08-11 | AppIcon、状态栏菜单和快捷键设置重设计 | 新增窗格 AppIcon 与 ICNS 构建；状态栏改为图形入口、分组命令和原生快捷键列；设置改为分组逐行录制；README 改为用户场景入口 | `swift build`、`swift test`、`make validate-docs`、`make package`、`codesign --verify --deep --strict`；真实 AppKit 设置截图；System Events 读取打包 App 菜单分组及 Center、Left Half、Next Display、Undo、Settings 键位属性 | 通过；AppIcon 在 64 px 预览仍可辨识，设置窗口无文本或控件重叠，菜单项与快捷键属性正确，zip 包含 `AppIcon.icns`；`make verify-hotkey-dispatch` 和 `make verify-window-move` 已尝试但当前桌面前台为 `loginwindow`，环境门禁返回 10，本次未重复证明真实桌面动作 |
| 2026-08-11 | 快捷键配置和窗口移动修复 | 增加 Preferences 快捷键配置、`ShortcutStore`、frontmost app AX focused/main window 读取、外部进程热键分发和真实 AppKit 夹具窗口动作自动化 | `swift build`、`swift test`、`make verify-hotkey-dispatch`、`make verify-window-move`、`make package`、`make validate-docs`；通过 System Events 验收 Preferences 选择、录制态、无修饰键校验和录制中关闭清理 | 通过；`Option-Command-Left` 已进入 Carbon handler，`WindowCommander` 已把前台夹具窗口移动到左半屏后恢复；Preferences 控件状态、输入校验和关闭后的键盘 monitor 清理符合预期 |
| 2026-08-11 | AI Workspace 初始化 | 复制 `AGENTS.md`、`docs/`、`scripts/validate-docs.sh`，保留已有 `README.md` 和 `Makefile` | 初始化器自动运行 `./scripts/validate-docs.sh` | 通过，输出 `docs validation passed (31 markdown files)` |
| 2026-08-11 | Developer ID Release 脚本 | 参考 SpeakMore 增加本地 Developer ID signed、notarized、stapled DMG 发布链路，并移除 tag 上自动发布 ad-hoc zip 的 workflow | `swift test`、`make validate-docs`、`make release-tag TAG=v0.1.1`、`make verify-release TAG=v0.1.1`、`make launch-release TAG=v0.1.1`；GitHub CI run `31480007926` | 通过；GitHub Release `v0.1.1` 已发布，DMG sha256 为 `a204f52ed14846b87446ecb0ec8c6909613adda25a3fe0a2424bcc9e5fb6824b`，App/DMG 均为 `Notarized Developer ID` |
| 2026-08-11 | 自动打包和旧 ad-hoc Release | 新增 `ci.yml`、旧 `release.yml`、`package-app.sh`，扩展 Makefile | 本地：`make validate-docs`、`swift test`、`make package`；远端：CI run `31478395654`、Release run `31478418091` | 通过；GitHub Release `v0.1.0` 已发布，asset 为 ad-hoc signed `PanePilot-v0.1.0-macos-arm64.zip`；后续正式分发改走 Developer ID DMG |
| 2026-08-10 | 本地初版实现 | 新建 Swift Package、菜单栏 App、窗口布局、打包脚本 | `swift build`、`swift test`、`make app`、`codesign --verify --deep --strict`、`file dist/PanePilot.app/Contents/MacOS/PanePilot` | 通过；本地产物为 arm64 Mach-O，ad-hoc signature 有效 |

## 当前风险

1. 热键注入和真实窗口移动自动化依赖已解锁用户桌面、Accessibility 权限，以及调用方控制 `System Events` 的权限，不能在无 GUI 的 CI runner 中执行。

## 未覆盖项

- Intel Mac 或 universal binary。
- 真实多显示器桌面手工验收证据。
