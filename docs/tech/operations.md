# Operations

本文档维护本地操作、CI、打包和发布流程。

## 本地命令

```bash
swift build
swift test
make validate-docs
make app
make package
open dist/PanePilot.app
```

## 打包

`Scripts/build-app.sh` 生成 `dist/PanePilot.app`，并用 ad-hoc signature 做本地签名。可通过环境变量覆盖版本：

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
| `Release` | push `v*` tag、手动触发 | 文档验证、test、package，并创建 GitHub Release |

## 发布

```bash
git tag v0.1.0
git push origin v0.1.0
```

Release workflow 会使用 tag 版本号写入 bundle version，产出 `PanePilot-vX.Y.Z-macos-arm64.zip` 并发布到 GitHub Releases。

## 文档验证

`scripts/validate-docs.sh` 当前做三类检查：

1. 关键入口文件是否存在。
2. 关键目录是否存在。
3. Markdown 相对链接是否能解析到本地文件。

## 正式分发待办

1. 配置 Developer ID Application 证书。
2. 在 GitHub Actions Secrets 中存放证书、keychain 密码和 Apple notarytool 凭证。
3. 将 ad-hoc signing 替换为 Developer ID signing。
4. 对 zip 或 app 执行 notarization 和 stapling。
