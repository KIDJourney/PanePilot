# Design System

本文档维护 PanePilot 已实现的原生 macOS 视觉和组件约束。

## 视觉语言

PanePilot 是高频使用的菜单栏工具，界面应安静、紧凑、可扫描。使用 AppKit 系统字体、动态系统颜色和原生控件，随浅色/深色模式变化；品牌识别集中在石墨色 AppIcon 和克制的绿色状态强调，不扩散成单色主题。

## 组件

| 组件 | 规则 |
|---|---|
| 状态栏图标 | 使用 template SF Symbol，固定方形点击区域，通过 tooltip 提供产品名 |
| 命令菜单 | 直接菜单、原生快捷键列、稳定分组；不把快捷键拼进标题文本 |
| 设置标题区 | 52 pt AppIcon + 20 pt semibold 标题，保持单一信息层级 |
| 登录项设置 | 42 pt 固定主行高，左侧标签、右侧原生 `NSSwitch`；状态说明最多两行，待批准时使用固定 146 pt 的小号系统设置按钮并靠右约束 |
| 设置动作行 | 42 pt 固定行高，动作左对齐；快捷键按钮 142 x 28 pt；清除使用 `xmark.circle.fill` 图标 |
| 分组标题 | 11 pt semibold、secondary label color、全大写 |
| 状态区 | 8 pt 绿色或橙色状态点加简短即时结果，不使用模态成功提示 |
| 恢复命令 | 使用 `arrow.counterclockwise` 图标与文字，放在固定底栏 |

## 颜色和状态

| 状态 | 表现 |
|---|---|
| 正常 | `labelColor` / `secondaryLabelColor` / `windowBackgroundColor` |
| 可操作 | 原生 rounded button 和系统 hover/focus 状态 |
| 录制中 | 快捷键按钮显示 `Type shortcut...`，底部状态点变为 system orange |
| 已保存 | 底部状态点为 system green，并显示最新结果 |
| 已禁用 | 快捷键按钮显示 `Set Shortcut`，清除按钮禁用 |
| 输入冲突 | 系统提示音 + 底部明确指出冲突动作 |
| 登录项待批准 | 开关保持关闭，system orange 说明并显示系统设置入口 |
| 登录项更新失败 | 保留系统真实开关状态，system red 说明且不伪造成功 |
| 检查更新中 | 菜单项显示 `Checking for Updates...` 并暂时禁用，避免重复请求或安装 |

## 可访问性

1. 所有仅图标按钮必须有 accessibility description 和 tooltip。
2. 快捷键同时使用 macOS 熟悉的修饰键符号和菜单系统的语义键位。
3. 布局使用动态系统颜色，不固定浅色或深色背景。
4. 窗口最小尺寸为 620 x 520 pt；内容不足时只滚动动作列表，标题和状态操作保持可见。
