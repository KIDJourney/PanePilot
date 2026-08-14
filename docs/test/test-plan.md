# Test Plan

本文档维护 PanePilot 当前测试策略和验收口径。

## 测试目标

1. 确认纯布局计算稳定，避免坐标和可见区域回归。
2. 确认 Swift package 可以完全在本机构建。
3. 确认每次提交前都能在本机自动生成 app zip。
4. 确认 AI Workspace 文档结构和链接持续有效。
5. 确认全局快捷键在真实桌面中能触发并移动窗口。
6. 确认登录项状态映射稳定，并能在隔离测试 App 中真实注册和注销。
7. 确认更新调度、版本比较、Release 资产校验和失败回滚稳定。

## 当前覆盖

| 测试 | 覆盖范围 | 命令 |
|---|---|---|
| Swift build | 编译 `PanePilotCore` 和菜单栏 app | `swift build` |
| Swift tests | `LayoutEngine`、多显示器坐标和选屏、登录项状态映射，以及更新版本比较和每日中午调度 | `swift test` |
| App bundle | 生成带 ICNS 的 `.app`、Info.plist 和 ad-hoc signature | `make app` |
| Settings snapshot | 从真实 AppKit content view 渲染设置窗口，检查分组、文本和控件边界 | `PANEPILOT_SNAPSHOT_APPEARANCE=light dist/PanePilot.app/Contents/MacOS/PanePilot --automation-preferences-snapshot /tmp/panepilot-settings.png`（`dark` 覆盖深色模式） |
| Zip package | 在本机生成 ad-hoc 预览 zip | `make package` |
| Hotkey dispatch automation | 构建 release 可执行文件，由独立的 `System Events` 进程注入 `Option-Command-Left`，并断言 Carbon hotkey handler 收到动作 | `make verify-hotkey-dispatch` |
| Shortcut recording automation | 录制期间注入快捷键并断言无动作，结束录制后再次注入并断言恢复分发 | `make verify-shortcut-recording` |
| Window move automation | 构建 release 可执行文件和真实 AppKit 夹具窗口，执行 `WindowCommander` 并断言夹具窗口通过 AX 移动后恢复原位置 | `make verify-window-move` |
| Chrome transition automation | 启动使用临时 profile 的隔离 Chrome，先最大化再移动到右半屏，断言最终落点且命令返回后未出现左半屏 frame | `make verify-chrome-transition` |
| Login item automation | 构建隔离 bundle ID 的 Developer ID 签名测试 App，经 LaunchServices 启动，并断言 `SMAppService.mainApp` 注册和注销后的真实状态 | `make verify-login-item` |
| Update helper automation | 用隔离的假 App 验证分阶段替换、备份与临时文件清理 | `make verify-update-helper` |
| Signed release | 生成 Developer ID signed + notarized DMG 并上传 GitHub Release | `make release-tag TAG=vx.y.z` |
| Release verification | 下载 GitHub Release DMG，校验 sha256、公证和 Gatekeeper | `make verify-release TAG=vx.y.z` |
| Launch verification | 从最终 DMG 启动 App 并确认进程存活 | `make launch-release TAG=vx.y.z` |
| 文档结构检查 | 根目录入口、关键目录、Markdown 链接 | `make validate-docs` |
| Local commit gate | commit 前自动运行文档验证、构建、测试、打包和签名检查 | `make install-hooks`、`make local-check` |

## 手工验收

以下行为需要在真实 macOS 桌面上验证；`make verify-hotkey-dispatch`、`make verify-window-move` 和 `make verify-login-item` 必须在 Mac 已解锁且用户桌面活跃时运行，若当前前台为 `loginwindow` 会直接失败或无法收到全局键盘事件。登录项自动化还需要本机 Developer ID 测试证书：

1. 首次启动能引导到 Accessibility 权限设置。
2. 授权后快捷键能移动当前聚焦窗口。
3. 半屏、四角、全屏、居中、三分屏符合预期。
4. 多显示器移动保持大致相对位置。
5. 撤销 / 重做能恢复最近窗口移动。
6. 状态栏使用图形图标，菜单分组和右侧快捷键列与设置窗口一致。
7. 设置窗口在浅色/深色模式下均无溢出或控件重叠，快捷键按钮可录制并逐项清除。
8. `Launch at Login` 能启用和关闭；待系统批准时显示正确状态并可打开“登录项”设置。
9. 外接屏位于主屏上方、下方或侧边时，在每块屏执行 Left/Right Half，窗口宽度均为该屏可见宽度的一半。
10. 录制快捷键时按现有全局快捷键不会移动任何窗口，保存或取消后全局快捷键恢复。
11. 设置窗口在 680 x 640 和最小 620 x 520 下，登录项说明、开关和系统设置按钮保持稳定且不重叠。
12. 发现更新时只有用户选择 `Install Update` 才下载并替换；校验、签名、Gatekeeper 或启动失败时保留当前版本。
13. Chrome 窗口在 Maximize 后执行 Right Half 时直接稳定到右半屏，不出现可见的左半屏中间态。

## 回归要求

以下变化必须重新执行 `swift test`、`make verify-hotkey-dispatch`、`make verify-shortcut-recording`、`make verify-window-move`、`make verify-update-helper`、`make package` 和 `make validate-docs`：

- 修改 `LayoutEngine` 或窗口动作定义。
- 修改 Accessibility 坐标转换。
- 修改 Accessibility 窗口 frame 写入顺序或应用级 AX 状态处理。
- 修改显示器排序、选屏或跨屏相对位置计算。
- 修改 hotkey 注册。
- 修改登录项注册、状态映射或设置开关。
- 修改更新检查、下载验证或替换助手。
- 修改打包脚本、本地 hook 或本地门禁。
- 新增、移动或删除 Markdown 文件。

正式发布前还必须执行 `make release-tag TAG=vx.y.z`、`make verify-release TAG=vx.y.z` 和 `make launch-release TAG=vx.y.z`。
