# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class DisplayTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  COLS = [{ key: :name, label: '名称' }, { key: 'size', label: '大小', align: :right }]

  # ── Table ─────────────────────────────────────────────

  def test_table_renders_headers_cells_and_symbol_or_string_keys
    rows = [{ name: 'a.rb', 'size' => 12 }, { 'name' => 'b.rb', size: 34 }]
    html = render(Beryl::Table.new(columns: COLS, rows: rows))
    assert_includes html, '名称'
    assert_includes html, 'a.rb'
    assert_includes html, '34'
    assert_includes html, 'text-align:right'
  end

  def test_table_row_click_and_selection
    rows = [{ name: 'r0' }, { name: 'r1' }]
    html = render(Beryl::Table.new(columns: COLS, rows: rows, row_key: :name))
    assert_includes html, 'b-table-row'
    # row_key :name → id = name 值；selected Signal 匹配第二行
    selected = Citrine::Signal.new('r1')
    html = render(Beryl::Table.new(columns: COLS, rows: rows, row_key: :name, selected: selected))
    assert_includes html, 'is-selected'
  end

  # ── List（窗口化）─────────────────────────────────────

  def test_list_renders_only_window_and_rolls_with_scroll
    items = (0...200).map { |i| "item-#{i}" }
    list = Beryl::List.new(items: items, height: 100, row_height: 20)
    html = render(list)
    assert_includes html, 'item-0'
    assert_includes html, 'item-8'         # 100/20 + 1 + 3*2 = 9 行
    refute_includes html, 'item-50'
    assert_includes html, 'height:4000px'  # 占位总高

    list.scroll_top = 2000                 # 第 100 行附近
    html = Citrine.render(list)
    assert_includes html, 'item-97'        # 100 - 3
    assert_includes html, 'item-108'
    refute_includes html, 'item-0'
    refute_includes html, 'item-110'       # 窗口外
    refute_includes html, 'item-199'
  end

  def test_list_row_click_selects
    picked = nil
    items = %w[a b c]
    # SSR 不触发事件，这里验证 on_select 契约经由插槽路径
    list = Beryl::List.new(items: items, height: 60, on_select: ->(it) { picked = it })
    render(list)
    list.on_select.call('b')
    assert_equal 'b', picked
  end

  # ── Tree ──────────────────────────────────────────────

  NODES = [{ id: 1, label: 'Object', children: [
    { id: 2, label: 'Module', children: [{ id: 3, label: 'Class' }] },
    { id: 4, label: 'Kernel' },
  ] }].freeze

  def test_tree_collapsed_by_default
    html = render(Beryl::Tree.new(nodes: NODES))
    assert_includes html, 'Object'
    refute_includes html, 'Module'         # 未展开
  end

  def test_tree_internal_expansion
    tree = Beryl::Tree.new(nodes: NODES)
    render(tree)
    tree.toggle(tree.nodes.first)          # 展开 Object
    html = Citrine.render(tree)
    assert_includes html, 'Module'
    refute_includes html, 'Class'          # 二级仍未展开
    tree.toggle(NODES[0][:children].first)
    html = Citrine.render(tree)
    assert_includes html, 'Class'
  end

  def test_tree_controlled_and_select
    expanded = Citrine::Signal.new([1])
    picked = nil
    html = render(Beryl::Tree.new(nodes: NODES, expanded: expanded, on_select: ->(n) { picked = n[:id] }))
    assert_includes html, 'Module'
    # 受控模式下 toggle 走 on_toggle 回调（未传则不动）
    tree = Beryl::Tree.new(nodes: NODES, expanded: expanded, on_toggle: ->(n) { expanded.set(expanded.get - [n[:id]]) })
    tree.toggle(tree.nodes.first)
    assert_equal [], expanded.get
  end

  # ── KV / Breadcrumb / Pagination ──────────────────────

  def test_kv_renders_pairs
    html = render(Beryl::KV.new(pairs: { 名称: 'demo.rb', 大小: nil }))
    assert_includes html, '名称'
    assert_includes html, 'demo.rb'
    html2 = render(Beryl::KV.new(pairs: [%w[a 1], %w[b 2]]))
    assert_includes html2, 'a'
    assert_includes html2, '2'
  end

  def test_breadcrumb_separators
    html = render(Beryl::Breadcrumb.new(items: [
      { label: '首页' }, { label: '库', on_click: -> {} }, { label: 'Beryl' },
    ]))
    assert_equal 2, html.scan('b-crumb-sep').size
    assert_includes html, 'is-link'
  end

  def test_pagination_small_count_shows_all
    page = Citrine::Signal.new(2)
    html = render(Beryl::Pagination.new(page: page, total: 200, per_page: 10))
    assert_includes html, 'is-active'
    assert_includes html, '>20<'           # 共 20 页
  end

  def test_pagination_window_and_clamp
    p = Beryl::Pagination.new(page: Citrine::Signal.new(1), total: 10_000, per_page: 10)
    assert_equal 1000, p.pages
    assert_equal [1, 2, :ellipsis, 1000], p.visible_pages
    p.go(-5)
    assert_equal 1, p.page.get
    p.go(999_999)
    assert_equal 1000, p.page.get
    p2 = Beryl::Pagination.new(page: Citrine::Signal.new(500), total: 10_000, per_page: 10)
    assert_equal [1, :ellipsis, 499, 500, 501, :ellipsis, 1000], p2.visible_pages
    p3 = Beryl::Pagination.new(page: Citrine::Signal.new(2), total: 200, per_page: 10)
    assert_equal [1, 2, 3, :ellipsis, 20], p3.visible_pages
    p2.prev
    assert_equal 499, p2.page.get
  end

  # ── Toolbar / StatusBar / Icon ────────────────────────

  # ── Divider（M7）────────────────────────────────────

  def test_divider_horizontal_with_text
    html = render(Beryl::Divider.new(text: '或'))
    assert_includes html, 'b-divider'
    assert_includes html, 'b-divider-line'
    assert_includes html, '或'
  end

  def test_divider_vertical
    html = render(Beryl::Divider.new(orientation: :vertical))
    assert_includes html, 'is-vertical'
  end

  def test_toolbar_and_statusbar_slots
    html = render(SlotsHost.new)
    assert_includes html, 'b-toolbar'
    assert_includes html, 'TOOL-BTN'
    assert_includes html, 'b-statusbar'
    assert_includes html, 'LEFT-INFO'
    assert_includes html, 'RIGHT-INFO'
  end

  def test_icon_glyphs
    assert_equal '✕', Beryl::Icon[:close]
    assert_equal 'x_wing', Beryl::Icon[:x_wing]   # 未知名字原样返回
  end

  # ── Table 排序 / 吸顶（M7）──────────────────────────

  SORT_COLS = [{ key: :name, label: '名称', sortable: true },
               { key: :size, label: '大小', align: :right }]

  def test_table_sortable_header_marks_active_and_arrow
    sort = Citrine::Signal.new({ key: :name, dir: :asc })
    html = render(Beryl::Table.new(columns: SORT_COLS,
                                   rows: [{ name: 'b' }, { name: 'a' }], sort: sort))
    assert_includes html, 'is-sortable'
    assert_includes html, 'is-sorted'
    assert_includes html, '↑'
    refute_match(/大小[^\n]*↑/, html)   # 箭头只挂活动列
  end

  def test_table_sort_toggles_and_sorts_rows_in_memory
    sort = Citrine::Signal.new({ key: :name, dir: :asc })
    table = Beryl::Table.new(columns: SORT_COLS, rows: [{ name: 'b' }, { name: 'a' }], sort: sort)
    assert_equal %w[a b], table.display_rows.map { |r| r[:name] }
    sort.set({ key: :name, dir: :desc })
    assert_equal %w[b a], table.display_rows.map { |r| r[:name] }
    table.toggle_sort(SORT_COLS.first)     # desc → 点一下回 asc
    assert_equal :asc, sort.get[:dir]
  end

  def test_table_sort_with_on_sort_delegates_ordering
    got = nil
    rows = [{ name: 'b' }, { name: 'a' }]
    table = Beryl::Table.new(columns: SORT_COLS, rows: rows,
                             sort: Citrine::Signal.new({ key: :name, dir: :asc }),
                             on_sort: ->(s) { got = s })
    assert_equal rows, table.display_rows  # 外部排序：行序不动，只回调
    table.toggle_sort(SORT_COLS.first)
    assert_equal({ key: :name, dir: :desc }, got)
  end

  def test_table_height_makes_scroll_container
    html = render(Beryl::Table.new(columns: COLS, rows: [{ name: 'x' }], height: 120))
    assert_includes html, 'height:120px'
    assert_includes html, 'overflow:auto'
  end

  def test_table_sort_by_custom_key
    cols = [{ key: :size, label: '大小', sortable: true,
              sort_by: ->(r) { r[:bytes] } }]
    rows = [{ size: '12K', bytes: 12_288 }, { size: '8.1K', bytes: 8_294 }]
    sort = Citrine::Signal.new({ key: :size, dir: :asc })
    table = Beryl::Table.new(columns: cols, rows: rows, sort: sort)
    # 字符串序会排成 12K < 8.1K；按字节数才是 8.1K < 12K
    assert_equal ['8.1K', '12K'], table.display_rows.map { |r| r[:size] }
    sort.set({ key: :size, dir: :desc })
    assert_equal ['12K', '8.1K'], table.display_rows.map { |r| r[:size] }
  end
end

class SlotsHost < Citrine::Component
  def view
    Beryl::Toolbar.new(content: -> { toolbar_content }).view
    Beryl::StatusBar.new(left: -> { label { 'LEFT-INFO' } },
                         right: -> { right_info }).view
  end

  def toolbar_content
    label { 'TOOL-BTN' }
  end

  def right_info
    label { 'RIGHT-INFO' }
  end
end
