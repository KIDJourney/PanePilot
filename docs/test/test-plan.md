# Test Plan

本文档维护 PanePilot 当前测试策略和验收口径。

## 测试目标

1. 确认纯布局计算稳定，避免坐标和可见区域回归。
2. 确认 Swift package 可以在本地和 GitHub Actions 构建。
3. 确认每次代码变更都能自动生成可下载 app zip。
4. 确认 AI Workspace 文档结构和链接持续有效。

## 当前覆盖

| 测试 | 覆盖范围 | 命令 |
|---|---|---|
| Swift build | 编译 `PanePilotCore` 和菜单栏 app | `swift build` |
| Swift tests | `LayoutEngine` 半屏、居中、跨屏行为 | `swift test` |
| App bundle | 生成 `.app`、Info.plist 和 ad-hoc signature | `make app` |
| Zip package | 生成 GitHub CI artifact zip | `make package` |
| Signed release | 生成 Developer ID signed + notarized DMG 并上传 GitHub Release | `make release-tag TAG=vx.y.z` |
| Release verification | 下载 GitHub Release DMG，校验 sha256、公证和 Gatekeeper | `make verify-release TAG=vx.y.z` |
| Launch verification | 从最终 DMG 启动 App 并确认进程存活 | `make launch-release TAG=vx.y.z` |
| 文档结构检查 | 根目录入口、关键目录、Markdown 链接 | `make validate-docs` |
| GitHub CI | push / PR 自动运行验证和打包 | `.github/workflows/ci.yml` |

## 手工验收

以下行为需要在真实 macOS 桌面上验证：

1. 首次启动能引导到 Accessibility 权限设置。
2. 授权后快捷键能移动当前聚焦窗口。
3. 半屏、四角、全屏、居中、三分屏符合预期。
4. 多显示器移动保持大致相对位置。
5. 撤销 / 重做能恢复最近窗口移动。

## 回归要求

以下变化必须重新执行 `swift test`、`make package` 和 `make validate-docs`：

- 修改 `LayoutEngine` 或窗口动作定义。
- 修改 Accessibility 坐标转换。
- 修改 hotkey 注册。
- 修改打包脚本或 GitHub Actions workflow。
- 新增、移动或删除 Markdown 文件。

正式发布前还必须执行 `make release-tag TAG=vx.y.z`、`make verify-release TAG=vx.y.z` 和 `make launch-release TAG=vx.y.z`。
