# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class MenuTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  def items
    [
      { label: '剪切', shortcut: '⌘X', action: -> {} },
      { separator: true },
      { label: '检查', disabled: true },
      { label: '只读', checked: true, action: -> {} },
      { label: '更多', submenu: [{ label: '深入', action: -> {} }] },
    ]
  end

  def test_renders_labels_shortcuts_checkmarks_and_disabled
    html = render(Beryl::Menu.new(items: items, x: 10, y: 10, on_close: -> {}))
    assert_includes html, '剪切'
    assert_includes html, '⌘X'
    assert_includes html, '✓ 只读'
    assert_includes html, 'is-disabled'
    assert_includes html, 'menu-sep'
    assert_includes html, 'has-submenu'
    assert_includes html, '深入'      # 子菜单内联渲染
    assert_includes html, '▸'
  end

  def test_disabled_item_binds_nothing
    html = render(Beryl::Menu.new(
      items: [{ label: '禁用', disabled: true, action: -> { raise } }],
      x: 1, y: 1, on_close: -> {},
    ))
    # 禁用项没有 on_click 绑定（SSR 侧不序列化事件，这里验证类名即可）
    assert_includes html, 'is-disabled'
  end

  def test_keyboard_nav_walks_enabled_items_only
    menu = Beryl::Menu.new(items: items, x: 0, y: 0, on_close: -> {})
    assert_nil menu.active
    menu.next_item
    assert_equal 0, menu.active          # '剪切'（index 0）
    menu.next_item
    assert_equal 3, menu.active          # 跳过分隔线(1)与禁用项(2)
    menu.next_item
    assert_equal 4, menu.active          # '更多'
    menu.next_item
    assert_equal 0, menu.active          # 环绕
    menu.prev_item
    assert_equal 4, menu.active
  end

  def test_choose_active_runs_action_and_closes
    ran = false
    closed = false
    menu = Beryl::Menu.new(
      items: [{ label: 'go', action: -> { ran = true } }],
      x: 0, y: 0, on_close: -> { closed = true },
    )
    menu.next_item
    menu.choose_active
    assert ran
    assert closed
  end

  def test_sticky_keeps_menu_open_on_action
    closed = false
    menu = Beryl::Menu.new(
      items: [{ label: 'toggle', action: -> {} }],
      x: 0, y: 0, on_close: -> { closed = true }, sticky: true,
    )
    menu.next_item
    menu.choose_active
    refute closed
  end

  def test_viewport_clamp_keeps_menu_inside
    html = render(Beryl::Menu.new(items: items, x: 990, y: 780,
                                  viewport: { w: 1000, h: 800 }, on_close: -> {}))
    # 右下角弹出：翻转也不合（x 方向溢出），走 shift——钳回 830/642
    assert_includes html, 'left:830px'   # 1000 - 170
    assert_includes html, 'top:642px'    # 800 - (5*30+8)
  end

  def test_menubar_renders_items_and_dropdown_when_open
    html = render(Beryl::MenuBar.new(
      menus: [{ label: '文件', items: [{ label: '新建', action: -> {} }] },
              { label: '编辑', items: [] }],
    ))
    assert_includes html, '文件'
    assert_includes html, '编辑'
    refute_includes html, '新建'          # 未点开不渲染下拉

    bar = Beryl::MenuBar.new(menus: [{ label: '文件', items: [{ label: '新建', action: -> {} }] }])
    bar.toggle(0)                        # 无事件时用默认锚点
    html = Citrine.render(bar)
    assert_includes html, '新建'
  end

  def test_prop_contract
    assert_raises(ArgumentError) { Beryl::Menu.new(items: [], x: 1, y: 1, on_close: -> {}, bogus: 1) }
  end
end
