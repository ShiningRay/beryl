# Beryl UI 库 · 整体规划

> 工作名 **Beryl（绿柱石）**——与 **Citrine（黄水晶）** 同族宝石命名。
> 定位：Citrine 信号内核之上的**桌面式 UI 组件库**。Citrine ≈ React（内核），
> Beryl ≈ MUI/AntD + 桌面外壳（组件库）。第一个真实消费者：RubyWorld。

状态：v0.1 · M1 已落地（自 rubyworld/frontend/sdk 移植并验证）
本文档是唯一的规划事实源，变更须同步修订。

---

## 1. 分层架构

```
L4  应用                 rubyworld（面板、业务组件）
L3  桌面外壳  beryl      WindowFrame · 世界/面板菜单 · z 序 · 焦点 · 快捷键
L2  控件层    beryl      Menu · Toast · Select · Tabs · Dialog · List · Table …
L1  原语层    beryl      输入原语（renderer 扩展）：drag · front · menu · key …
L0  内核      citrine    Signal / Effect / Component / Renderer 家族
```

依赖单向向下。L1-L3 全部在本仓库；L0 在 citrine 仓库，Beryl 只通过
Citrine 公共 API 扩展（子类化 Renderer、标准 Component），不 fork 内核。

## 2. 库法则（已被 RubyWorld 实战验证，违反即 bug）

### F1 · 值在 owner 求值，行为保持闭包
与 Citrine G-2 响应式属性同一划分：
- **值**（`css_class/style/direction/...` 传 Proc）→ 在节点 owner 上下文求值（`prop_value`）；
- **行为**（事件回调 `on_*` 传 Proc）→ 保持定义处闭包 self，**禁止 instance_exec 重绑**。
背景：WindowFrame 抽取时发现旧 `handle_event` 重绑 self，导致父组件回调
里的方法全部落到子组件上（已修入 citrine，含回归测试）。

### F2 · 插槽用 Proc prop
跨组件内容注入（`content:` / `tools:`）用普通 `.call` 的 Proc——
闭包保留父组件上下文，emit 的 owner 归属父组件，信号订阅互不干扰。
这是 Beryl 组件组合的唯一正规方式。

### F3 · props 即契约
未声明的 prop 立即 ArgumentError；声明了 type 的 prop 强制校验。
组件公开面 = prop 列表，读代码即读文档。

### F4 · 组件无状态优先
控件自身不持有业务状态：受控值由消费者注入 Signal（`value: signal(:x)`），
内部 UI 态（如菜单开合）才用 `state` 宏私有。模型状态走消费者的 Store。

### F5 · 纯 CRuby 可测
L2 控件层禁止触碰 Opal/Native——用 `Citrine.render`（StringRenderer）
做渲染断言。只有 L1 原语层允许 `` ` `` 反引号 JS 与 Native，且必须
`defined?(Opal)` 守卫加载。

## 3. 现有资产（M1，已从 rubyworld 移植）

| 组件/原语 | 层 | 说明 |
|---|---|---|
| `Beryl::Renderer` | L1 | 输入原语：`textarea`（Signal 双向绑定+⌘⏎）、`drag_move`/`drag_resize`（零重渲染拖拽）、`on_front`（点击置顶）、`on_menu`（右键菜单） |
| `Beryl::Menu` | L2 | 上下文菜单：`items: [{label:, action:}]`，点任意处关闭 |
| `Beryl::Toast` | L2 | 轻提示 `{msg:, kind:}` |
| `Beryl::WindowFrame` | L3 | 桌面窗口框：拖动/置顶/右键/缩放手柄 + `content`/`tools` 插槽，`resizable: false` 变体 |

## 4. 控件目录（M2 起）

### M2 · 表单与弹层（优先：Editor/Inspector 立刻用得上）
```ruby
# 下拉选择（受控）
Beryl::Select.new(options: [['Ruby', 'ruby'], ['JS', 'js']],
                   value: signal(:lang), on_change: ->(v) { ... })
# 标签页（插槽式）
Beryl::Tabs.new(tabs: [{ id: 'own', label: 'own', content: -> { ... } },
                       { id: 'inh', label: 'inherited', content: -> { ... } }],
                active: signal(:tab))
# 模态（声明式渲染在 view 里，由消费者信号控制显隐）
Beryl::Dialog.new(title: '确认', content: -> { ... },
                  on_confirm: :delete, on_cancel: :close)
```

### M3 · 信息展示
- `Tooltip`（做成 prop 原语：`button(tip: '保存 ⌘S')`）
- `List`（**虚拟滚动**——RubyWorld 类树 300+ 节点已是痛点）
- `Table`（列定义 + 类型感知单元格：RubyWorld 的 ivars/contents 表直接复用）
- `Tree`（类树浏览器的正式化）

### M4 · 桌面行为
- 焦点管理器：Tab 遍历、焦点环、模态焦点捕获
- 快捷键注册表：`Beryl.hotkey('cmd+s', -> { ... })`，冲突检测
- z 序管理器：从 WindowFrame 的 `@z` ivar 升格为正式服务
- `Splitter`、数据拖放（drag 携带 payload，不只是移动面板）

### M5 · 主题系统
- design token：颜色/字号/间距/圆角集中为 CSS 变量表（现有 `--bg/--panel/...` 的正式化）
- 暗/亮切换、密度（compact/comfortable）
- 控件 CSS 与库同仓分发（`assets/beryl.css`），类名前缀 `b-`

### M6 · 便携性
- SSR（StringRenderer 路径回归测试）
- CanvasRenderer 适配评估（桌面端打包用）

## 5. 事件原语清单

| 原语 | 状态 | 备注 |
|---|---|---|
| on_click / on_enter / on_change | ✅ citrine L0 | |
| on_key（G-9 键盘分发） | ✅ citrine L0 | Symbol/Proc/Hash 三态 |
| textarea / drag / front / menu | ✅ beryl L1 | 本次移植 |
| hover / focus / blur | ☐ M4 | 焦点管理器一起做 |
| dblclick / wheel / drop | ☐ M4+ | |

## 6. 测试策略

1. **单元（纯 CRuby）**：props 契约、渲染断言（`Citrine.render` →
   StringRenderer 输出含预期标签/类名/文本）、插槽语义（闭包 self）。
2. **集成**：rubyworld 冒烟（49 项）+ 浏览器 E2E 作为唯一验收场。
3. **演示页**：`examples/*.html`，用 `bin/citrine dev <beryl/examples>` 热刷新。

## 7. 仓库与版本

```
beryl/
  lib/beryl.rb            入口（Opal 守卫加载 renderer）
  lib/beryl/renderer.rb   L1 原语（仅 Opal）
  lib/beryl/widgets.rb    L2 控件（纯 CRuby 可测）
  lib/beryl/window.rb     L3 窗口框
  docs/PLAN.md            本文档
  examples/               演示页
  test/                   minitest
```

- 版本 0.x，语义化；citrine 依赖走 path/git（`../citrine`），双仓同步演进，
  citrine 发 gem 后切换为正式依赖。
- 反哺通道：Beryl 中稳定 ≥ 1 个里程碑的原语（drag/front/menu/textarea）
  应上提进 citrine L0；本库保留桌面语义层。

## 8. 里程碑与验收

| 里程碑 | 内容 | 验收 |
|---|---|---|
| M1 ✅ | Renderer 四原语 + Menu/Toast/WindowFrame | rubyworld E2E 全过 |
| M2 | Select/Tabs/Dialog | 方法编辑器 own/inherited 切换改用 Tabs；类浏览器 scope 改用 Select |
| M3 | Tooltip/List/Table/Tree | 类树 300+ 节点流畅滚动；Inspector 表格复用 Table |
| M4 | 焦点/快捷键/z 序/Splitter | 全键盘操作 rubyworld（Tab 遍历 + ⌘S 应用编辑） |
| M5 | 主题 token | 亮色主题一键切换 |
| M6 | SSR/Canvas | StringRenderer 快照进 CI |
