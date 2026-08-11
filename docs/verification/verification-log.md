# Verification Log

本文档维护最近验证状态、证据和风险。

## 最近验证

| 日期 | 场景 | 变更 | 验证 | 结果 |
|---|---|---|---|---|
| 2026-08-11 | AI Workspace 初始化 | 复制 `AGENTS.md`、`docs/`、`scripts/validate-docs.sh`，保留已有 `README.md` 和 `Makefile` | 初始化器自动运行 `./scripts/validate-docs.sh` | 通过，输出 `docs validation passed (31 markdown files)` |
| 2026-08-11 | 自动打包和 Release | 新增 `ci.yml`、`release.yml`、`package-app.sh`，扩展 Makefile | 待执行：`make validate-docs`、`swift test`、`make package`、GitHub Actions | 待验证 |
| 2026-08-10 | 本地初版实现 | 新建 Swift Package、菜单栏 App、窗口布局、打包脚本 | `swift build`、`swift test`、`make app`、`codesign --verify --deep --strict`、`file dist/PanePilot.app/Contents/MacOS/PanePilot` | 通过；本地产物为 arm64 Mach-O，ad-hoc signature 有效 |

## 当前风险

1. GitHub Actions runner 可用性依赖 GitHub hosted `macos-26-arm64` 镜像。
2. 当前 release zip 是 ad-hoc signed，未做 Developer ID 公证。
3. 自动化测试尚未覆盖真实 Accessibility 权限和桌面窗口移动，只覆盖纯布局逻辑和打包流程。

## 未覆盖项

- Developer ID 签名、公证和 stapling。
- Intel Mac 或 universal binary。
- 真实多显示器桌面手工验收证据。
