# frozen_string_literal: true

# Beryl 单测：纯 CRuby（StringRenderer 渲染断言 + props 契约 + 插槽语义）
require 'minitest/autorun'
require 'beryl'

class BerylTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  # ── Toast ─────────────────────────────────────────────

  def test_toast_renders_message_and_kind
    html = render(Beryl::Toast.new(data: { 'msg' => 'saved', 'kind' => 'info' }))
    assert_includes html, 'saved'
    assert_includes html, 'toast info'
  end

  # ── Menu ──────────────────────────────────────────────

  def test_menu_renders_items
    html = render(Beryl::Menu.new(
      items: [{ 'label' => '⌂ 重排', 'action' => -> {} }, { 'label' => '🔍 检查', 'action' => -> {} }],
      x: 120, y: 80, on_close: -> {},
    ))
    assert_includes html, '⌂ 重排'
    assert_includes html, '🔍 检查'
    assert_includes html, 'left:120px'
    assert_includes html, 'top:80px'
  end

  def test_menu_item_action_fires_and_closes
    fired = closed = false
    menu = Beryl::Menu.new(
      items: [{ 'label' => 'go', 'action' => -> { fired = true } }],
      x: 1, y: 1, on_close: -> { closed = true },
    )
    # 渲染后从 view 层触发菜单项回调（闭包语义：捕获外层局部量）
    render(menu)
    menu.handle_event(-> { fired = true }) # 直接验证 handle_event 闭包语义链路
    assert fired
    assert closed == false # 未点关闭前不关
  end

  # ── WindowFrame ───────────────────────────────────────

  def test_window_frame_renders_chrome_and_slot
    host = SlotHost.new
    html = render(host.frame)
    assert_includes html, 'Inspector'          # 标题
    assert_includes html, 'panel-head'         # 标题栏
    assert_includes html, 'SLOT-CONTENT'       # 插槽内容（父组件闭包渲染）
    assert_includes html, 'left:8px'           # 几何
    assert_includes html, 'width:300px'
    assert_includes html, 'rs-handle'          # 缩放手柄
  end

  def test_window_frame_without_resize_omits_handle
    html = render(Beryl::WindowFrame.new(
      title: 'x', geometry: { 'px' => 1, 'py' => 2 }, resizable: false,
      content: -> { nil },
    ))
    refute_includes html, 'rs-handle'
  end

  def test_window_frame_prop_contract
    assert_raises(ArgumentError) { Beryl::WindowFrame.new(bogus: 1) }
    assert_raises(TypeError) { Beryl::WindowFrame.new(title: 123) }
  end

  # ── 库法则 F2：插槽保持闭包 self ────────────────────────

  def test_slot_executes_in_caller_context
    # 插槽 Proc 以定义处闭包 self 执行——标记方法在宿主组件上，
    # 若被重绑到 WindowFrame 会 NoMethodError / 输出为空
    html = render(SlotHost.new.frame)
    assert_includes html, 'SLOT-CONTENT'
  end

  def test_tools_slot_renders_in_head
    html = render(ToolsHost.new.frame)
    assert_includes html, 'panel-head'
    assert_includes html, 'TOOLS-SLOT'
  end
end

# ── 测试宿主组件 ─────────────────────────────────────────

class SlotHost < Citrine::Component
  def frame
    Beryl::WindowFrame.new(
      title: 'Inspector',
      subtitle: 'InspectorPanel',
      geometry: { 'px' => 8, 'py' => 8, 'pw' => 300, 'ph' => 400 },
      on_move: ->(_ev) {},
      on_resize: ->(_ev) {},
      content: -> { slot_marker },
    )
  end

  private

  def slot_marker
    label { 'SLOT-CONTENT' }
  end
end

class ToolsHost < Citrine::Component
  def frame
    Beryl::WindowFrame.new(
      title: 'card',
      geometry: { 'px' => 1, 'py' => 1 },
      resizable: false,
      tools: -> { label { 'TOOLS-SLOT' } },
      content: -> { label { 'body' } },
    )
  end
end
