# AGENTS.md — AI Workspace 项目指南

给未来的 Codex / Claude / Cursor / Copilot 会话：先读这份，再动手。根目录入口只保留稳定规则和索引；长期上下文、产品事实、设计/UI、技术方案、测试方案和验证证据都维护在 `docs/`。

## 项目定位

PanePilot 是一个现代 Swift 版 macOS 菜单栏窗口管理器，目标是复刻 Spectacle 的核心键盘窗口布局体验，并适配 Apple Silicon、新 macOS、GitHub Actions 自动打包和 GitHub Release 发布。

## 权威文档

| 场景 | 先读文档 |
|---|---|
| 理解项目全貌 | `README.md`、`docs/README.md` |
| 写产品需求、改功能范围 | `docs/product/README.md`、`docs/product/prd.md` |
| 做设计、交互或 UI | `docs/design/README.md`、`docs/design/ui-guidelines.md` |
| 做架构或技术实现 | `docs/tech/README.md`、`docs/tech/architecture.md` |
| 做打包、CI 或 Release | `docs/tech/operations.md`、`.github/workflows/` |
| 写测试方案或验收标准 | `docs/test/README.md`、`docs/test/test-plan.md` |
| 按业务场景验证结果 | `docs/verification/README.md`、`docs/verification/scenarios.md` |
| 恢复 agent 工作上下文 | `docs/agent/context.md`、`docs/agent/decisions.md` |
| 新建文档 | `docs/templates/` 下对应模板 |

## 当前信息架构

```text
docs/
  README.md                 # 文档系统入口和维护规则
  product/                  # 产品文档：愿景、PRD、范围、用户故事
  design/                   # 设计文档：体验、交互、UI、组件、视觉
  tech/                     # 技术文档：架构、模块、接口、数据、运维
  test/                     # 测试文档：测试策略、测试用例、回归要求
  verification/             # 验证文档：业务场景、验证方法、证据、结论
  agent/                    # agent 知识：上下文、决策、术语、交接
  templates/                # PRD、设计、技术、测试、验证、决策模板
scripts/
  validate-docs.sh          # 最小文档结构和链接验证
```

## 工作流

1. 先根据任务类型读取对应文档，不要全量扫描无关上下文。
2. 修改任何文件前，先读取该文件现有内容和同目录 README。
3. 产品范围变化先更新 `docs/product/`，再实现。
4. 设计、交互、UI、组件状态或视觉规范变化同步更新 `docs/design/`。
5. 架构、接口、数据、依赖或部署变化同步更新 `docs/tech/`。
6. 测试策略、测试用例和回归要求同步更新 `docs/test/`。
7. 业务场景验证方法、证据、结果和阻塞点同步更新 `docs/verification/`。
8. 会影响后续 agent 判断的经验、约束、决策，记录到 `docs/agent/`。
9. 完成前运行 `make validate-docs`，并在回复中说明验证结果。

## 文档维护边界

- `AGENTS.md` 只放高频入口、权威索引和稳定规则，不堆长篇背景。
- `CLAUDE.md` 是指向 `AGENTS.md` 的软链接，避免双写漂移。
- `docs/product/` 只写用户价值、范围、需求和产品边界，不写实现细节。
- `docs/design/` 只写体验目标、信息架构、交互、UI 状态、组件和视觉规则。
- `docs/tech/` 只写技术事实、设计选择、接口、数据、运行方式和技术风险。
- `docs/test/` 只写测试策略、测试用例、自动化覆盖和回归要求。
- `docs/verification/` 只写面向业务场景的验证方法、证据、结论、阻塞点和未覆盖项。
- `docs/agent/` 只写会跨会话复用的上下文，不记录临时聊天流水。

## 常用命令

```bash
swift build
swift test
make package
make validate-docs
tree -a -L 3 -I '.git|node_modules|dist|build' .
rg "TODO|待确认|阻塞" docs
```

## 发布完成门禁

- GitHub Actions 上传的 ad-hoc zip artifact 只是每次变更的 CI 预览产物，不等同于 GitHub Release。
- 任务明确要求“发布”或“Release”时，必须按 `docs/tech/operations.md` 依次执行 `make release-tag TAG=vx.y.z`、`make verify-release TAG=vx.y.z` 和 `make launch-release TAG=vx.y.z`。
- 只有远端 tag 与目标 commit 一致、`gh release view` 可见正式 DMG 和 sha256、下载校验与最终 DMG 启动验证全部通过后，才可以报告 Release 已完成。

## Git 规则

- 提交前先看 `git status --short --untracked-files=all`。
- 不把无关文档重排、格式化和需求变更混进同一个 commit。
- 约定式 commit：`<type>(<scope>): <subject>`。
- 不使用 `git reset --hard`、`git checkout --`、`push --force` 等破坏性命令，除非用户明确要求。
