# Verification Log

本文档维护最近验证状态、证据和风险。

## 最近验证

| 日期 | 场景 | 变更 | 验证 | 结果 |
|---|---|---|---|---|
| 2026-08-14 | Chrome 最大化后右半屏闪动修复 | AX frame 写入从 `Position -> Size` 改为 `Size -> Position -> Size`；写入期间临时关闭并恢复应用的 `AXEnhancedUserInterface`；增加写入顺序单测和隔离 Chrome 回归 | `swift build`、`swift test`（15 tests）、`make verify-chrome-transition`、`make verify-window-move`、`make local-check`（含 `make validate-docs`、本地 package 和 `codesign --verify --deep --strict`） | 通过；隔离 Chrome 在最大化后直接稳定到 Right Half，命令返回后只观察到右半屏 frame；AppKit 夹具移动通过；本地生成 `PanePilot-v0.1.5-local-482e5de75f6f-macos-arm64.zip` 且签名检查通过 |
| 2026-08-13 | 构建与打包迁移到本地 | 删除 GitHub Actions workflow，增加版本化 pre-commit hook 和本地变更门禁；同步项目规则、决策、架构、测试与运维文档 | `make install-hooks`、`make local-check`、`git config --get core.hooksPath`、`make validate-docs`、`codesign --verify --deep --strict` | 通过；本机完成文档校验、build、14 tests、ad-hoc app/zip 打包和签名检查，预览包按 `PanePilot-v<version>-local-<content-hash>-macos-arm64.zip` 留在 `dist/`；GitHub 只托管源码、tag 和本机生成的正式 Release 资产 |
| 2026-08-13 | 每日自更新、快捷键录制和登录项布局 | 每天中午检查 latest Release 并在确认后安全替换；录制期间注销全局热键；登录项说明和操作按钮改为稳定约束；增强窗口夹具前台激活 | `swift build`、`swift test`（14 tests）、`make validate-docs`、`make verify-hotkey-dispatch`、`make verify-shortcut-recording`、`make verify-window-move`（连续两次）、`make verify-update-helper`、`make verify-login-item`、`make package`、`codesign --verify --deep --strict`；GitHub latest API 资产契约；打包 App 从 `0.1.0` 检出 `v0.1.4` 的原生更新提示并选择 `Later`；登录项待批准状态下 680 x 640 与 620 x 520 截图走查 | 通过；提示显示版本、release notes 和 `Install Update` / `Later` / `View Release`，选择稍后不会安装；录制期间输入未触发动作且结束后恢复，窗口移动和登录项系统注册通过，替换助手成功路径会清理暂存、模拟新版启动失败会恢复旧 App；两种设置窗口尺寸均无漂移或重叠；正式 Release 和旧版到新版的在线自升级仍按发布门禁执行 |
| 2026-08-13 | 外接屏半屏宽度修复 | Cocoa 到 AX 坐标转换只以主显示器顶部作为全局坐标基准；布局显示器按窗口重叠面积选择并以最近屏兜底 | `swift test`（10 tests）；新增“2560 宽外接屏位于 1440 宽主屏上方”的坐标转换，以及窗口分别位于主屏和外接屏时的 Left Half 双向回归用例 | 合成多显示器回归通过：主屏窗口目标宽度为 720 pt，外接屏窗口目标宽度为 1280 pt；布局始终使用当前窗口所在显示器，不以主显示器作为目标；当前系统只枚举到一块活动屏，真实双屏桌面待最终使用场景确认 |
| 2026-08-13 | 登录时启动 | 使用 `SMAppService.mainApp` 增加设置开关、待批准系统设置入口、失败状态保真、隔离真实系统测试，并同步中英文 README 和设置截图 | `make validate-docs`、`swift build`、`swift test`（7 tests）、`make verify-login-item`、浅色/深色/最小尺寸真实 AppKit 截图、`make package`、`codesign --verify --deep --strict`、arm64 和 Info.plist 检查；另尝试 `make verify-hotkey-dispatch`、`make verify-window-move` | 登录项真实注册状态为 enabled、注销回到 not registered，测试登录项和临时钥匙串已清理；设置窗口三种快照无溢出，ad-hoc 包签名有效；热键和窗口移动回归因 `NSWorkspace` 当前前台仍为 `loginwindow` 被环境门禁拒绝，本次未重复证明这两项既有能力 |
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
