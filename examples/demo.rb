# backtick_javascript: true
# Beryl 组件演示（浏览器）
# 运行：在 citrine 仓库执行 bin/citrine dev <本目录绝对路径>
# 编译（beryl/ 目录内）：bundle exec opal -c -I../citrine/lib -Ilib -o examples/demo.js examples/demo.rb
require 'citrine/browser'
require 'beryl'

# 桌面：WindowManager 管两个窗口 + 任务栏 + 菜单栏
class Desktop < Citrine::Component
  state :dialog, default: nil
  state :lang,   default: :ruby
  state :dark,   default: false
  state :tab,    default: 'form'
  state :mode,   default: :balanced
  state :level,  default: 60
  state :count,  default: 3
  state :query,  default: ''
  state :symbol, default: ''
  state :accent, default: '#4f8cff'
  state :day,    default: nil
  state :node,   default: nil
  state :file,   default: 'window.rb'
  state :picked, default: nil
  state :page,   default: 1
  state :lang_open,  default: false    # Select 开合（受控——组件实例会被父块重建）
  state :tree_open,  default: [1]      # Tree 展开集（受控）
  state :menu_open,  default: nil      # MenuBar 开合 { index:, x:, y: }（受控）

  # 窗口注册必须在渲染器外完成（initialize 无 Effect）：
  # view 里 open 会 set @order → 同步重入渲染 → 无限递归（WindowManager 已加守卫）
  def initialize
    super()
    @wm = Beryl::WindowManager.new(viewport: { w: `window.innerWidth`, h: `window.innerHeight` })
              .open(:gallery, title: '组件画廊', geometry: { x: 30, y: 46, w: 470, h: 420 })
              .open(:data, title: '数据视图', geometry: { x: 530, y: 70, w: 430, h: 330 })
    # 响应式集合（citrine signal_list）：push_bounded 一次通知完成「追加 + 封顶」
    @toasts = Citrine.signal_list([])
  end

  attr_reader :wm, :toasts

  def view
    menubar.view
    window(:gallery)
    window(:data)
    Beryl::Taskbar.new(wm: wm).view
    render_dialog if dialog
    toasts.each_with_index do |t, i|
      Beryl::Toast.new(msg: t['msg'], kind: t['kind'],
                       duration_ms: 3000,
                       on_expire: -> { dismiss(i) }).view
    end
  end

  # 关闭（✕）会注销窗口——渲染必须以 wm.windows 为准条件渲染：
  # 无守卫地 wm.frame(已关闭 id) 会 raise（frame 对未注册窗口 fail fast）
  def window(id)
    return unless wm.windows.include?(id)

    wm.frame(id, content: -> { frame_content(id) }).view
  end

  def frame_content(id)
    id == :gallery ? gallery_body : data_body
  end

  # ── 菜单栏 ────────────────────────────────────────────

  def menubar
    Beryl::MenuBar.new(viewport: menu_viewport, open_index: signal(:menu_open), menus: [
      { label: '桌面', items: [
        { label: '新窗口', action: -> { new_window } },
        { separator: true },
        { label: '弹窗', shortcut: '⌘D', action: -> { self.dialog = 'confirm' } },
        { label: '打招呼', action: -> { toast('hello from beryl', 'info') } },
      ] },
      { label: '视图', items: [
        { label: '暗色主题', checked: dark, action: -> { self.dark = !dark } },
        { label: '最大化画廊', action: -> { wm.toggle_max(:gallery) } },
        { separator: true },
        { label: '层叠', disabled: true },
      ] },
    ])
  end

  def menu_viewport
    { w: `window.innerWidth`, h: `window.innerHeight` }
  end

  # ── 窗口 1：组件画廊（Tabs 分页）───────────────────────

  def gallery_body
    Beryl::Tabs.new(
      active: signal(:tab), on_change: ->(id) { self.tab = id },
      tabs: [
        { id: 'form', label: '表单', content: -> { form_tab } },
        { id: 'show', label: '展示', content: -> { show_tab } },
        { id: 'feed', label: '反馈', content: -> { feed_tab } },
      ],
    ).view
  end

  def form_tab
    stack(gap: 10, style: { padding: '8px' }) do
      row(gap: 8) do
        Beryl::Select.new(options: [['Ruby', :ruby], ['JS', :js], ['Rust', :rust]],
                          value: signal(:lang), open: signal(:lang_open),
                          on_change: ->(v) { self.lang = v }).view
        Beryl::Switch.new(value: signal(:dark), on_change: ->(v) { self.dark = v }).view
      end
      Beryl::RadioGroup.new(options: [['保守', :safe], ['平衡', :balanced], ['激进', :aggressive]],
                            value: signal(:mode), on_change: ->(v) { self.mode = v },
                            direction: :row).view
      Beryl::Slider.new(value: signal(:level), min: 0, max: 100, step: 5,
                        on_change: ->(v) { self.level = v }).view
      Beryl::NumberInput.new(value: signal(:count), min: 0, max: 99, step: 1).view
      Beryl::SearchInput.new(value: signal(:query), on_enter: ->(_e) { toast("搜索 #{query}") }).view
      Beryl::Combobox.new(options: %w[Signal Effect Component Renderer WindowFrame],
                          value: signal(:symbol), on_pick: ->(v) { toast("选中 #{v}") }).view
      Beryl::ColorPicker.new(value: signal(:accent), on_change: ->(c) { self.accent = c }).view
      Beryl::DatePicker.new(value: signal(:day), on_change: ->(d) { toast("选了 #{d}") }).view
    end
  end

  def show_tab
    stack(gap: 10, style: { padding: '8px' }) do
      Beryl::KV.new(pairs: { 语言: lang, 模式: mode, 数量: count, 主题: dark ? '暗' : '亮' }).view
      Beryl::Tree.new(
        nodes: tree_nodes, selected: signal(:node),
        expanded: signal(:tree_open),
        on_toggle: ->(n) { toggle_tree_node(n) },
        on_select: ->(n) { toast("节点 #{n['label'] || n[:label]}") },
      ).view
      Beryl::Breadcrumb.new(items: [
        { label: '首页' }, { label: '组件', on_click: -> { toast('组件') } }, { label: '树' },
      ]).view
    end
  end

  def tree_nodes
    [{ id: 1, label: 'Object', children: [
      { id: 2, label: 'Module', children: [{ id: 3, label: 'Class' }] },
      { id: 4, label: 'Kernel' },
    ] }, { id: 5, label: 'Beryl', children: [{ id: 6, label: 'WindowFrame' }] }]
  end

  def toggle_tree_node(n)
    id = n['id'] || n[:id]
    cur = tree_open.dup
    cur.include?(id) ? cur.delete(id) : cur << id
    self.tree_open = cur
  end

  # ✕ 关掉的窗口从这里重开（注册回 WindowManager 即可，几何给默认值）
  def new_window
    id = %i[gallery data].find { |i| !wm.windows.include?(i) }
    if id
      geom = id == :gallery ? { x: 30, y: 46, w: 470, h: 420 } : { x: 530, y: 70, w: 430, h: 330 }
      wm.open(id, title: id == :gallery ? '组件画廊' : '数据视图', geometry: geom)
    else
      toast('两个窗口都开着呢')
    end
  end

  def feed_tab
    stack(gap: 12, style: { padding: '8px' }) do
      Beryl::Progress.new(value: signal(:level)).view
      Beryl::Progress.new(value: 0, indeterminate: true).view
      Beryl::Spinner.new(text: '加载中…').view
      row(gap: 6) do
        Beryl::Badge.new(text: 'info', kind: 'info').view
        Beryl::Badge.new(text: 'ok', kind: 'success').view
        Beryl::Badge.new(text: 'warn', kind: 'warn').view
        Beryl::Badge.new(text: 'err', kind: 'error').view
      end
      Beryl::EmptyState.new(message: '这里什么都没有', icon: '∅',
                            action: -> { empty_action }).view
    end
  end

  def empty_action
    button(on_click: :toast_from_slot) { '新建一个' }
  end

  def toast_from_slot
    toast('从空状态动作触发')
  end

  # ── 窗口 2：数据视图（Table + List + 分页）─────────────

  def data_body
    stack(gap: 8, style: { padding: '8px' }) do
      Beryl::Table.new(
        columns: [{ key: :name, label: '文件' }, { key: :size, label: '大小', align: :right }],
        rows: table_rows,
        row_key: :name, selected: signal(:file),
        on_row_click: ->(r) { self.file = r[:name] },
      ).view
      Beryl::List.new(items: list_items, height: 84, row_height: 28,
                      selected: signal(:picked), on_select: ->(it) { toast("选了 #{it}") }).view
      Beryl::Pagination.new(page: signal(:page), total: 230, per_page: 20,
                            on_change: ->(p) { self.page = p }).view
    end
  end

  def table_rows
    [{ name: 'signal.rb', size: '8.1K' }, { name: 'component.rb', size: '12K' },
     { name: 'window.rb', size: '9.4K' }, { name: 'renderer.rb', size: '6.2K' }]
  end

  def list_items
    (1..40).map { |i| "第 #{i} 行 · 虚拟滚动" }
  end

  # ── 弹窗 / toast ──────────────────────────────────────

  def render_dialog
    Beryl::Confirm.new(title: '确认', message: '要删除这条数据吗？',
                       content: -> { dialog_body },
                       on_confirm: -> { confirm_delete },
                       on_cancel: -> { self.dialog = nil }).view
  end

  def dialog_body
    label { '此操作不可撤销（Dialog 插槽内容）' }
  end

  def confirm_delete
    self.dialog = nil
    toast('已删除', 'error')
  end

  def toast(msg, kind = 'success')
    @toasts.push_bounded({ 'msg' => msg, 'kind' => kind }, 5)   # 最多同时 5 条
  end

  def dismiss(i)
    @toasts.delete_at(i)
  end
end

Beryl::Renderer.mount_at('app', Desktop.new)
