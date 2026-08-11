# Operations

本文档维护本地操作、CI、打包和发布流程。

## 本地命令

```bash
swift build
swift test
make validate-docs
make app
make package
make release-tag TAG=v0.1.1
make verify-release TAG=v0.1.1
make launch-release TAG=v0.1.1
open dist/PanePilot.app
```

## 打包

`Scripts/build-app.sh` 生成 `dist/PanePilot.app`，并用 ad-hoc signature 做本地/CI 快速产物。可通过环境变量覆盖版本：

```bash
VERSION=0.1.0 BUILD=1 make app
VERSION=0.1.0 BUILD=1 make package
```

`Scripts/package-app.sh` 会生成：

```text
dist/PanePilot-v0.1.0-macos-arm64.zip
```

## GitHub Actions

| Workflow | 触发 | 行为 |
|---|---|---|
| `CI` | push 到 `main`、PR、手动触发 | 文档验证、build、test、package，并上传 zip artifact |

## 发布

```bash
make release-tag TAG=v0.1.1
make verify-release TAG=v0.1.1
make launch-release TAG=v0.1.1
```

正式 GitHub Release 走本地脚本，不走 GitHub runner 的 ad-hoc zip。`Scripts/release-local.sh` 会：

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

1. 如果需要完全 CI 化签名，后续再把 Developer ID 证书和 notarytool 凭证接入 GitHub Actions Secrets。
2. 如需覆盖 Intel Mac，增加 x86_64 或 universal binary artifact。
