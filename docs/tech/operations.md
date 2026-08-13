# Operations

本文档维护本地操作、自动化打包和发布流程。项目不使用 GitHub Actions 或其他 GitHub 托管构建能力。

## 本地命令

```bash
swift build
swift test
make validate-docs
make install-hooks
make local-check
make app
make package
make verify-shortcut-recording
make verify-update-helper
make verify-login-item
make release-tag TAG=v0.1.1
make verify-release TAG=v0.1.1
make launch-release TAG=v0.1.1
open dist/PanePilot.app
```

## 打包

`Scripts/build-app.sh` 生成 `dist/PanePilot.app`，并用 ad-hoc signature 做本地快速产物。可通过环境变量覆盖版本：

```bash
VERSION=0.1.0 BUILD=1 make app
VERSION=0.1.0 BUILD=1 make package
```

`Scripts/package-app.sh` 会生成：

```text
dist/PanePilot-v0.1.5-local-<content-hash>-macos-arm64.zip
```

默认版本取最近的正式 tag，`local-<content-hash>` 标识当前工作区内容（包含已跟踪改动和未跟踪文件），避免不同代码变更覆盖同名预览包。可通过 `VERSION`、`BUILD` 和 `ARTIFACT_LABEL` 显式覆盖。

`make verify-login-item` 使用隔离 bundle ID 构建 Developer ID 签名测试 App，并通过 LaunchServices 真实验证 `SMAppService.mainApp` 的注册和注销。该命令需要已解锁的用户桌面，以及本机签名目录中的 Developer ID 测试证书；测试结束会删除测试 App、登录项和临时钥匙串。

`make verify-shortcut-recording` 在真实桌面注入两次全局快捷键，验证录制期间不会分发窗口动作、退出录制后恢复分发。`make verify-update-helper` 在临时目录执行替换助手，验证新版本替换、备份和临时文件清理；正式更新链的签名、公证和 Gatekeeper 仍由 Release 验证覆盖。

## 本地提交门禁

```bash
make install-hooks
make local-check
```

`make install-hooks` 将仓库的 `core.hooksPath` 设为 `.githooks`。之后每次 `git commit` 都会先执行 `Scripts/local-change-check.sh`：文档验证、Swift build、Swift tests、ad-hoc app/zip 打包，以及最终 app 签名检查。预览产物留在 `dist/`，不提交到 git，也不上传 GitHub artifact。

## 发布

```bash
make release-tag TAG=v0.1.1
make verify-release TAG=v0.1.1
make launch-release TAG=v0.1.1
```

正式 GitHub Release 走本地脚本，GitHub 不参与构建。`Scripts/release-local.sh` 会：

1. 使用 `Scripts/build-app.sh` 生成 app bundle。
2. 用 Developer ID Application 证书重新签名 `.app`，开启 hardened runtime。
3. 提交 `.app` 到 Apple notarization，staple 后做 Gatekeeper 校验。
4. 生成带 `/Applications` 快捷方式的 DMG。
5. 签名、公证、staple DMG，并用 `spctl --type open` 校验。
6. 生成 sha256，创建或更新 GitHub Release。

默认优先使用 `panepilot-notary` keychain profile；如果不存在，则复用已验证的 `speakmore-notary` profile。也可以显式设置 `APPLE_ID`、`APPLE_APP_SPECIFIC_PASSWORD` 和 `APPLE_TEAM_ID`。

## 文档验证

`scripts/validate-docs.sh` 当前做三类检查：

1. 关键入口文件是否存在。
2. 关键目录是否存在。
3. Markdown 相对链接是否能解析到本地文件。

## 正式分发待办

1. 如需覆盖 Intel Mac，在本机构建 x86_64 或 universal binary 产物。
