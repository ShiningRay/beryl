# Beryl（绿水晶的姐妹石 · 工作名）

[Citrine](../citrine) 信号内核之上的**桌面式 UI 组件库**。

```
citrine  = React（Signal/Effect/渲染器抽象）
beryl    = MUI/AntD + 桌面外壳（窗口框、窗口管理器、菜单、z 序、任务栏）
rubyworld= 第一个真实应用（dogfood 场景）
```

## 安装（当前为 path 依赖）

```bash
# Gemfile
gem 'citrine', path: '../citrine'
gem 'beryl',   path: '.'
```

浏览器侧经 Opal 编译（`-I citrine/lib -I beryl/lib`），
`require 'beryl'` 自动在 Opal 环境加载输入原语层。

## 用法速览

```ruby
require 'beryl'

# ── 窗口管理：注册在渲染器外（view 内变更会同步重入渲染，WindowManager 有守卫）
wm = Beryl::WindowManager.new(viewport: { w: 1200, h: 800 })
    .open(:inspector, title: 'Inspector', geometry: { x: 8, y: 8, w: 300, h: 400 })

class Desktop < Citrine::Component
  def initialize
    super()
    @wm = Beryl::WindowManager.new(viewport: { w: `window.innerWidth`, h: `window.innerHeight` })
              .open(:inspector, title: 'Inspector', geometry: { x: 8, y: 8, w: 300, h: 400 })
  end

  def view
    @wm.frame(:inspector, content: -> { slot }).view   # z 序/激活/最大化/吸附全接线
    Beryl::Taskbar.new(wm: @wm).view                   # 任务栏：最小化/还原置顶
  end
end

# ── 表单（受控：值与开合都传 Signal，见 PLAN F4）
Beryl::Select.new(options: [['Ruby', :ruby], ['JS', :js]],
                  value: signal(:lang), open: signal(:lang_open),
                  on_change: ->(v) { ... }).view

# ── 弹层与对话框
Beryl::Menu.new(items: [{ 'label' => '关闭', 'action' => -> { close } }],
                x: 120, y: 80, on_close: -> { }).view
Beryl::Confirm.new(title: '确认', message: '删除？',
                   on_confirm: -> { ... }, on_cancel: -> { ... }).view
Beryl::Toast.new(msg: 'saved', kind: 'info', duration_ms: 3000,
                 on_expire: -> { ... }).view

# ── 信息展示（List 为窗口化虚拟滚动）
Beryl::Table.new(columns: [{ key: :name, label: '名称' }], rows: rows).view
Beryl::List.new(items: items, height: 300, row_height: 28).view
```

## 组件目录

L1 原语：textarea · drag（八向缩放/clamp/最小尺寸）· front · menu · hover ·
dblclick · wheel · scroll · tabindex/autofocus · tip · 数据拖放 · auto_dismiss
L2 控件：Menu · MenuBar · Popover · Select · MultiSelect · RadioGroup · Switch ·
Slider · NumberInput · SearchInput · Combobox · ColorPicker · DatePicker · Tabs ·
Accordion · Dialog(Alert/Confirm/Prompt) · Toast · Progress · Spinner · Badge ·
EmptyState · Table · List(虚拟滚动) · Tree · KV · Breadcrumb · Pagination ·
Toolbar · StatusBar · Icon
L3 外壳：WindowFrame · WindowManager（z 序/最大化/吸附/clamp）· Taskbar

## 库法则（详见 [docs/PLAN.md](docs/PLAN.md)）

1. **值在 owner 求值，行为保持闭包**（事件 Proc 不重绑 self）
2. **插槽用 Proc prop**（`content:`/`tools:`）
3. **props 即契约**（未声明即错；可空 prop 不带 type）
4. **组件无状态优先；交互态必须受控**（父块重渲染会重建实例，内部态自焚）
5. **控件层纯 CRuby 可测**（StringRenderer 渲染断言；Opal 代码只在 L1）
6. **WindowManager 变更操作禁止在 view/Effect 内调用**（守卫 fail fast）
7. **Signal 读取位置决定订阅边界**（虚拟滚动在内容块内读 scroll_top）

## 测试与演示

```bash
bundle exec rake                 # 79 项：渲染断言 + 契约 + 窗口管理逻辑
# 演示页（双窗口桌面 + 全组件画廊）：
cd ../citrine && bin/citrine dev ../beryl/examples -I ../beryl/lib
```
