# Beryl（绿水晶的姐妹石 · 工作名）

[Citrine](../citrine) 信号内核之上的**桌面式 UI 组件库**。

```
citrine  = React（Signal/Effect/渲染器抽象）
beryl    = MUI/AntD + 桌面外壳（窗口框、菜单、z 序、焦点）
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

# 窗口框：拖动/置顶/右键/缩放 + Proc 插槽（闭包保持父组件 self）
Beryl::WindowFrame.new(
  title: 'Inspector', accent: '#3fb950',
  geometry: { 'px' => 8, 'py' => 8, 'pw' => 300, 'ph' => 400 },
  on_move:  ->(ev) { api('layout', 'px' => ev[:x], 'py' => ev[:y]) },
  on_menu:  ->(ev) { open_menu(ev) },
  content:  -> { label { "hello" } },   # 插槽：在父组件上下文渲染
).view

# 上下文菜单 / 轻提示
Beryl::Menu.new(items: [{ 'label' => '关闭', 'action' => -> { close } }],
                x: 120, y: 80, on_close: -> { }).view
Beryl::Toast.new(data: { 'msg' => 'saved', 'kind' => 'info' }).view
```

## 库法则（详见 [docs/PLAN.md](docs/PLAN.md)）

1. **值在 owner 求值，行为保持闭包**（事件 Proc 不重绑 self）
2. **插槽用 Proc prop**（`content:`/`tools:`）
3. **props 即契约**（未声明即错，类型强校验）
4. **组件无状态优先**（受控值注入 Signal，业务状态在消费者的 Store）
5. **控件层纯 CRuby 可测**（StringRenderer 渲染断言；Opal 代码只在 L1）

## 测试

```bash
ruby -Ilib -I../citrine/lib test/beryl_test.rb
```
