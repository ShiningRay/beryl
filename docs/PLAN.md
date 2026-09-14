# Beryl UI 库 · 整体规划

> 工作名 **Beryl（绿柱石）**——与 **Citrine（黄水晶）** 同族宝石命名。
> 定位：Citrine 信号内核之上的**桌面式 UI 组件库**。Citrine ≈ React（内核），
> Beryl ≈ MUI/AntD + 桌面外壳（组件库）。第一个真实消费者：RubyWorld。

状态：v0.2 · M1-M4 主体落地（M2/M3 组件目录、M4 窗口管理与交互原语），
本文档是唯一的规划事实源，变更须同步修订。

---

## 1. 分层架构

```
L4  应用                 rubyworld（面板、业务组件）
L3  桌面外壳  beryl      WindowFrame · WindowManager · Taskbar · MenuBar · z 序 · 吸附
L2  控件层    beryl      Menu · Select · Tabs · Dialog · Table · List · Tree · …
L1  原语层    beryl      输入原语（renderer 扩展）：drag · front · menu · hover ·
                        dblclick · wheel · scroll · tabindex · autofocus · tip ·
                        drag_payload/on_drop · auto_dismiss · textarea
L0  内核      citrine    Signal / Effect / Component / Renderer 家族
```

依赖单向向下。L1-L3 全部在本仓库；L0 在 citrine 仓库，Beryl 只通过
Citrine 公共 API 扩展（子类化 Renderer、标准 Component），不 fork 内核。

## 2. 库法则（违反即 bug）

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
注意 citrine 的实现对 **default 值也跑类型校验**：可空 prop 一律不能带 `type:`。
prop 名不得与元素 DSL 同名（如 `label`）——prop 定义的读取方法会遮住 view 里的
`label { }` 元素调用（Spinner 踩过，改叫 `text`）。

### F4 · 组件无状态优先；**交互态必须受控**（v0.2 强化）
控件自身不持有业务状态：受控值由消费者注入 Signal（`value: signal(:x)`）。
**v0.2 推论**：父块重渲染会**重建子组件实例**——开合/游标/展开集这类
跨渲染存活的交互态放组件内部 `state` 等于自焚（Select 下拉点开即关），
**必须受控**（`open:`/`cursor:`/`expanded:` 传 Signal）。组件保留内部态
回退仅用于自根挂载的独立演示场景。模型状态走消费者的 Store。

### F5 · 纯 CRuby 可测
L2/L3 控件层禁止触碰 Opal/Native——用 `Citrine.render`（StringRenderer）
做渲染断言。只有 L1 原语层允许 `` ` `` 反引号 JS 与 Native，且必须
`defined?(Opal)` 守卫加载。`Beryl::Timer` 是例外通道：抽象在 support.rb
（纯 CRuby），setTimeout 后端由 L1 renderer 加载时注入。

### F6 · WindowManager 变更操作禁止在 view/Effect 内调用（v0.2）
Signal#set 同步重跑订阅者。在 view 里 `open/focus/place` → set(@order/geom)
→ 触发 view 自己重跑 → memo 尚未赋值 → 再构造再 open → 无限重入（栈溢出，
demo 真实踩坑）。守卫已内置（`assert_outside_effect!` fail fast）：
窗口注册在初始化阶段（mount 前）完成；运行期变更只从事件回调进入
（浏览器事件回调里 `Effect.current` 为 nil）。

### F7 · 视图里读 Signal 的位置决定订阅边界（G-2 应用）
虚拟滚动 List 的 `scroll_top` 必须在**内容 block 内**读取（重跑只重建行），
若在外层读，滚动容器随整块重建、滚动位置丢失。

## 3. 现有资产

### L1 · 输入原语（renderer.rb，仅 Opal）
| 原语 | 说明 |
|---|---|
| `textarea` + `value:`/`on_submit` | 多行输入：Signal 双向绑定 + ⌘⏎ 提交 |
| `drag_move` / `drag_resize` + `drag_dir`/`drag_min`/`drag_clamp`/`drag_pane` | 零重渲染拖拽；八向缩放；最小尺寸；视口 clamp；面板选择器 |
| `on_front` | mousedown 置顶 |
| `on_menu` | contextmenu 菜单 |
| `on_hover` | mouseenter/leave → true/false |
| `on_dblclick` | 双击（标题栏最大化用） |
| `on_wheel` | 滚轮 {delta_x, delta_y} |
| `on_scroll` | 滚动 {top, left}（List 虚拟滚动用） |
| `tabindex` / `autofocus` | 让容器参与焦点链（Menu 键盘导航的前提） |
| `tip` | 原生浮层 tooltip（.b-tip） |
| `drag_payload` / `on_drop` | 数据拖放（DragBus 携带任意 Ruby 对象） |
| `auto_dismiss` + `on_dismiss` | 自动消失（Toast 用；节点脱文档则忽略） |

### L2 · 控件（widgets，纯 CRuby 可测）
| 组件 | 说明 |
|---|---|
| `Menu` | items: label/action/disabled/checked/shortcut/submenu/separator；↑↓ 导航、Enter 执行、Esc 关闭；sticky；视口 clamp |
| `MenuBar` | 顶层菜单栏；开合受控 `open_index:` |
| `Popover` | fixed 浮层容器（捕获层 + 定位 + z 序） |
| `Select` / `MultiSelect` | CSS 锚定下拉；受控 `value`/`open` |
| `RadioGroup` / `Switch` / `Slider` / `NumberInput` / `SearchInput` | 受控表单件 |
| `Combobox` | 输入过滤 + 候选；Enter 取首个 |
| `ColorPicker` | 预设色板 v1 |
| `DatePicker` | 月视图网格；Zeller 同余推星期（无 Date/strftime 依赖）；游标受控 |
| `Tabs` / `Accordion` | 受控 active / open |
| `Dialog` + `Alert` / `Confirm` / `Prompt` | 遮罩模态；Esc 走 window_key |
| `Toast` | msg/kind；duration_ms 自动消失（L1 auto_dismiss）；动作按钮；堆叠由消费者 map |
| `Progress` / `Spinner` / `Badge` / `EmptyState` | 反馈件 |
| `Table` | 列定义 + 行哈希（symbol/string 键兼容）+ 选中 + 行点击 |
| `List` | **窗口化虚拟滚动**（overscan；scroll_top 信号在内容块内读，F7） |
| `Tree` | 受控 expanded；递归渲染；缩进/箭头 |
| `KV` / `Breadcrumb` / `Pagination` / `Toolbar` / `StatusBar` / `Icon` | 展示与布局件 |

### L3 · 桌面外壳（window.rb）
| 组件/服务 | 说明 |
|---|---|
| `WindowFrame` | 标题栏拖动/右键/置顶/双击最大化 + chrome 控制钮（− □ ✕，opt-in）+ content/tools 插槽 + **八向缩放手柄** + active/inactive 外观 + minimized 不渲染 |
| `WindowManager` | 注册表 + z 序 + 最大化/最小化（restore 几何）+ 视口 clamp + **Aero Snap**（拖到上/左/右缘 → 最大化/半屏；吸附仅拖动路径，缩放不吸附）+ `frame(id)` 一站式接线（守卫见 F6） |
| `Taskbar` | 任务栏：激活再点 → 最小化；后台/最小化点 → 还原置顶 |

### 支撑（support.rb / overlay.rb）
- `Beryl::Timer`：定时器抽象（后端由 L1 注入，CRuby 测试可注入同步后端）
- `Beryl::DragBus`：数据拖放通道（payload 任意 Ruby 对象）
- `Beryl.next_z`：全局浮层 z 序计数器；`Beryl.pick`：symbol/string 键兼容
- `Beryl::Overlay.position`：纯几何定位算法（锚点 → 翻转 → shift 回视口），Menu clamp / Popover 共用

## 4. 里程碑与验收

| 里程碑 | 内容 | 状态 |
|---|---|---|
| M1 | Renderer 四原语 + Menu/Toast/WindowFrame | ✅ |
| M2 | Select/Tabs/Dialog + 表单件 | ✅（Select 系 CSS 锚定下拉；Dialog 三变体） |
| M3 | Tooltip(tip 原语)/List(虚拟滚动)/Table/Tree/Accordion/分页等展示件 | ✅ |
| M4 | 焦点(tabindex/autofocus)/hover/dblclick/wheel/scroll/数据拖放/WindowManager/Taskbar/吸附 | ✅ 主体（全键盘遍历与快捷键注册表仍欠） |
| M5 | 主题 token（CSS 变量表、b- 前缀统一迁移、暗/亮密度切换） | ☐ demo.html 已全量 b-* 化可作底稿 |
| M6 | SSR 快照进 CI / CanvasRenderer 适配评估 | ☐ |
| M-WM+ | 窗口吸附实时预览、热点重入 edge case、快捷键注册表（`Beryl.hotkey`）、数据拖放跨面板示例 | ☐ |

## 5. 事件原语清单

| 原语 | 状态 | 备注 |
|---|---|---|
| on_click / on_enter / on_change / on_key / on_focus / on_blur | ✅ citrine L0 | focus/blur 早已内建（旧文档误记 M4 待做） |
| window_key（全局键盘） | ✅ citrine L0 | Dialog Esc 用 |
| textarea / drag / front / menu | ✅ beryl L1 | M1 |
| on_hover / on_dblclick / on_wheel / on_scroll | ✅ beryl L1 | v0.2 |
| tabindex / autofocus / tip / auto_dismiss | ✅ beryl L1 | v0.2 |
| drag_payload / on_drop（数据拖放） | ✅ beryl L1 | DragBus 同文档传递 |

## 6. 测试策略

1. **单元（纯 CRuby）**：props 契约、渲染断言（`Citrine.render` → StringRenderer 输出）、
   插槽语义、WindowManager 几何/吸附/clamp 纯逻辑、Overlay 定位算法。
   当前 79 项（`bundle exec rake`）。
2. **集成**：rubyworld 冒烟 + 浏览器 E2E 作为唯一交互验收场
   （v0.2 已在浏览器逐项验证：Select 开合选中、MenuBar 下拉、Dialog、
   双击最大化/还原、chrome 按钮、任务栏最小化/还原、Toast）。
3. **演示页**：`examples/demo.html`（组件画廊 + 双窗口桌面 + 任务栏）。
   跨仓库启动：`bin/citrine dev <beryl>/examples -I <beryl>/lib`
   （dev_server 支持 `-I` 重复传参，v0.2 起）。

## 7. 仓库与版本

```
beryl/
  lib/beryl.rb            入口（Opal 守卫加载 renderer）
  lib/beryl/support.rb    Timer / DragBus / next_z / pick
  lib/beryl/overlay.rb    Overlay 定位算法 + Popover
  lib/beryl/menu.rb       Menu + MenuBar
  lib/beryl/form.rb       Select/MultiSelect/RadioGroup/Switch/Slider/NumberInput/
                          SearchInput/Combobox/ColorPicker/DatePicker
  lib/beryl/tabs.rb       Tabs + Accordion
  lib/beryl/dialog.rb     Dialog + Alert/Confirm/Prompt
  lib/beryl/feedback.rb   Toast/Progress/Spinner/Badge/EmptyState
  lib/beryl/display.rb    Table/List/Tree/KV/Breadcrumb/Pagination/Toolbar/StatusBar/Icon
  lib/beryl/window.rb     WindowFrame + WindowManager + Taskbar
  lib/beryl/renderer.rb   L1 原语（仅 Opal；注入 Timer 后端）
  docs/PLAN.md            本文档
  examples/               演示页（demo.rb + demo.html，全组件画廊）
  test/                   minitest（按域分文件）
```

- 版本 0.x，语义化；citrine 依赖走 path/git（`../citrine`），双仓同步演进，
  citrine 发 gem 后切换为正式依赖。
- **gem 发布名 `citrine-beryl`**（RubyGems 的 `beryl` 名已被他人占用，2018）；
  require 名保持 `beryl`。发版流程：改 gemspec 版本 → 推 `v*` 标签 → Release
  工作流构建 gem 附 GitHub Release 并 gem push（需仓库 secret RUBYGEMS_API_KEY，
  与 citrine 同款；未配置时自动跳过 push，仅附产物）。
- 编译：`bundle exec opal -c -I../citrine/lib -Ilib -o examples/demo.js examples/demo.rb`
  （beryl 目录内，借 citrine 的 bundle；require 走 `-I` 裸路径，
  不要 `require_relative '../lib/beryl'`——Opal PathReader 命中同名目录会 EISDIR）。
- 反哺通道：稳定 ≥ 1 个里程碑的原语应上提进 citrine L0（drag/front/menu/textarea
  为 M1 批次候选）；本库保留桌面语义层。citirne dev_server 的 `-I` 参数为双仓示例
  开发新增（向后兼容）。

## 8. 踩坑记录（新增）

- **view 内 set 已读 Signal → 无限重入**：`@order.set(@order.get + [id])` 在 view 里
  执行时，get 使本 Effect 订阅、set 立即重入 view；若构造/赋值链未完成（memo 模式）
  则每轮重新构造 → 栈溢出。守卫 + 「Store 在渲染器外初始化」约定（F6）。
- **子组件内部态活不过父块重渲染**：实例每轮重建（F4 推论）。开合/游标一律受控。
- **prop 名遮蔽元素 DSL**：`prop :label` 后 view 里 `label { }` 调到 prop 读取器（F3）。
- **可空 prop 不能带 type:**：citrine 对 default 也跑类型校验（F3）。
- **虚拟滚动读位置**：scroll_top 必须在内容 block 内读（F7），否则容器重建丢滚动位置。
- **clamp 与吸附叠加**：clamp 后坐标必然落在吸附带——吸附只跟拖动路径（place snap: true），
  缩放/程序化 place 不吸附。
- **Taskbar/chrome 事件冒泡**：窗口控制钮 on_click 内 `e.stopPropagation`，
  避免同时触发标题栏 on_front/on_head_click。
