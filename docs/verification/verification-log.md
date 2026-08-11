# Verification Log

本文档维护最近验证状态、证据和风险。

## 最近验证

| 日期 | 场景 | 变更 | 验证 | 结果 |
|---|---|---|---|---|
| 2026-08-11 | AI Workspace 初始化 | 复制 `AGENTS.md`、`docs/`、`scripts/validate-docs.sh`，保留已有 `README.md` 和 `Makefile` | 初始化器自动运行 `./scripts/validate-docs.sh` | 通过，输出 `docs validation passed (31 markdown files)` |
| 2026-08-11 | Developer ID Release 脚本 | 参考 SpeakMore 增加本地 Developer ID signed、notarized、stapled DMG 发布链路，并移除 tag 上自动发布 ad-hoc zip 的 workflow | 待执行：`swift test`、`make validate-docs`、`make release-tag TAG=v0.1.1`、`make verify-release TAG=v0.1.1`、`make launch-release TAG=v0.1.1` | 待验证 |
| 2026-08-11 | 自动打包和旧 ad-hoc Release | 新增 `ci.yml`、旧 `release.yml`、`package-app.sh`，扩展 Makefile | 本地：`make validate-docs`、`swift test`、`make package`；远端：CI run `31478395654`、Release run `31478418091` | 通过；GitHub Release `v0.1.0` 已发布，asset 为 ad-hoc signed `PanePilot-v0.1.0-macos-arm64.zip`；后续正式分发改走 Developer ID DMG |
| 2026-08-10 | 本地初版实现 | 新建 Swift Package、菜单栏 App、窗口布局、打包脚本 | `swift build`、`swift test`、`make app`、`codesign --verify --deep --strict`、`file dist/PanePilot.app/Contents/MacOS/PanePilot` | 通过；本地产物为 arm64 Mach-O，ad-hoc signature 有效 |

## 当前风险

1. 自动化测试尚未覆盖真实 Accessibility 权限和桌面窗口移动，只覆盖纯布局逻辑和打包流程。

## 未覆盖项

- Intel Mac 或 universal binary。
- 真实多显示器桌面手工验收证据。
