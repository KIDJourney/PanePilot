# Verification Methods

本文档维护可复用验证方法。

## 自动化验证

适用场景：文档结构、链接、格式、单元测试、构建、静态检查。

证据要求：

- 命令。
- 退出结果。
- 关键输出摘要。
- 覆盖范围。

## 手动验收

适用场景：产品流程、复杂交互、权限、真实设备、人工判断质量。

证据要求：

- 环境。
- 操作步骤。
- 实际结果。
- 截图、日志或可复现说明。

## 设计走查

适用场景：UI、交互、视觉、组件状态、响应式、可访问性。

证据要求：

- 覆盖页面或组件。
- 覆盖状态。
- 截图或原型链接。
- 发现的问题和处理结论。

## 端到端验证

适用场景：多个模块串联、用户主路径、发布产物。

证据要求：

- 使用的产物来源。
- 环境和账号状态。
- 主路径步骤。
- 最终可观察结果。
- 未覆盖环节和阻塞点。

### macOS 窗口移动自动化

`make verify-hotkey-dispatch` 由独立的 `System Events` 进程注入按键，用于验证 Carbon 全局快捷键注册和 handler 分发，避免 macOS 丢弃被测进程发给自身的合成全局热键。`make verify-shortcut-recording` 在同一真实分发层验证录制期间全局注册被暂停且结束后恢复。`make verify-window-move` 会创建固定尺寸的真实 AppKit 夹具窗口，用于验证 Accessibility 聚焦窗口读取、`WindowCommander` 和 AX 写入的最终结果；测试退出前恢复原位置，不操作用户窗口。`make verify-chrome-transition` 使用临时 profile 启动隔离 Chrome，验证最大化窗口执行 Right Half 后没有命令返回后的 Left Half AX frame，并在退出时终止测试实例和删除 profile。这些门禁分层覆盖快捷键到窗口动作的完整路径，避免 `System Events` 在前台夹具上继续处理同一个合成按键而覆盖 AX 断言。运行前置条件：

- Mac 已解锁。
- 当前是活跃用户桌面，不是 `loginwindow`。
- 当前可执行文件已获得 Accessibility 权限。
- 运行 `make verify-hotkey-dispatch` 时，当前终端或 Agent 可以通过 `System Events` 发送按键。
- 运行 `make verify-chrome-transition` 时，本机已安装 Google Chrome；测试只操作临时 profile 的隔离窗口。

如果前台是 `loginwindow`，命令应失败并提示先解锁，而不是继续尝试移动窗口。

### 应用内更新

`swift test` 覆盖语义版本比较和每日中午调度；`make verify-update-helper` 覆盖退出后的替换与清理。正式 Release 的 sha256、公证票据、Gatekeeper 和最终启动由 `make verify-release TAG=vx.y.z` 与 `make launch-release TAG=vx.y.z` 验证。更新失败的回滚标准是目标路径恢复旧 App，备份与 staging 不残留。

## 回滚验证

适用场景：发布、迁移、配置变更、数据结构变更。

证据要求：

- 回滚触发条件。
- 回滚步骤。
- 回滚后验证命令或现象。
- 数据恢复边界。
