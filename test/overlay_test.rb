# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class OverlayTest < Minitest::Test
  VP = { w: 1000, h: 800 }

  def test_bottom_when_it_fits
    pos = Beryl::Overlay.position(anchor: { x: 100, y: 100, w: 0, h: 0 },
                                  size: { w: 170, h: 200 }, viewport: VP)
    assert_equal({ x: 100, y: 100, placement: :bottom }, pos)
  end

  def test_flips_to_top_when_bottom_overflows
    pos = Beryl::Overlay.position(anchor: { x: 100, y: 700, w: 0, h: 0 },
                                  size: { w: 170, h: 200 }, viewport: VP)
    assert_equal :top, pos[:placement]
    assert_equal 500, pos[:y]   # 700 - 200
  end

  def test_shifts_back_into_viewport_when_neither_side_fits
    # 锚点在右下角：bottom/top 都放不下 → shift 回视口内
    pos = Beryl::Overlay.position(anchor: { x: 990, y: 790, w: 0, h: 0 },
                                  size: { w: 170, h: 200 }, viewport: VP)
    assert_equal 830, pos[:x]  # 1000 - 170
    assert_equal 600, pos[:y]  # 800 - 200
  end

  def test_zero_size_viewport_clamps_to_origin
    pos = Beryl::Overlay.position(anchor: { x: 50, y: 50, w: 0, h: 0 },
                                  size: { w: 200, h: 100 }, viewport: { w: 100, h: 50 })
    assert_equal 0, pos[:x]
    assert_equal 0, pos[:y]
  end

  def test_next_z_is_monotonic
    a = Beryl.next_z
    b = Beryl.next_z
    assert_operator b, :>, a
  end

  # Popover 的 content 插槽在 owner 上下文执行（F2），用宿主组件验证
  def test_popover_renders_fixed_position_and_slot
    html = Citrine.render(PopoverHost.new.popover)
    assert_includes html, 'position:fixed'
    assert_includes html, 'left:40px'
    assert_includes html, 'top:60px'
    assert_includes html, 'POPOVER-SLOT'
    assert_includes html, 'menu-overlay'   # 传了 on_close 就有捕获层
  end

  def test_popover_clamps_with_viewport
    html = Citrine.render(PopoverHost.new.clamped_popover)
    assert_includes html, 'left:330px'   # 500 - 170
    assert_includes html, 'top:300px'    # 400 - 100
  end

  # ── Tooltip（M7）────────────────────────────────────

  def render(component)
    Citrine.render(component)
  end

  def test_tooltip_anchor_always_shown_bubble_only_when_open
    open = Citrine::Signal.new(false)
    tip = Beryl::Tooltip.new(text: '提示文字', anchor: '锚内容', open: open)
    html = render(tip)
    assert_includes html, 'b-tooltip-wrap'
    assert_includes html, '锚内容'
    refute_includes html, '提示文字'
    open.set(true)
    html = render(tip)
    assert_includes html, '提示文字'
    assert_includes html, 'is-top'         # 缺省 placement
  end

  def test_tooltip_placement_class
    html = render(Beryl::Tooltip.new(text: 't', anchor: 'a',
                                     open: Citrine::Signal.new(true), placement: :left))
    assert_includes html, 'is-left'
  end

  def test_tooltip_on_hover_wires_open
    open = Citrine::Signal.new(false)
    tip = Beryl::Tooltip.new(text: 't', anchor: 'a', open: open,
                             on_hover: ->(v) { open.set(v) })
    render(tip)
    tip.set_open(true)
    assert open.get                        # 受控通道：内部态写穿透到 Signal
  end
end

class PopoverHost < Citrine::Component
  def popover
    Beryl::Popover.new(x: 40, y: 60, z_index: 2999,
                       on_close: -> {},
                       content: -> { popover_slot })
  end

  def clamped_popover
    Beryl::Popover.new(x: 400, y: 350, viewport: { w: 500, h: 400 },
                       size: { w: 170, h: 100 },
                       content: -> { popover_slot })
  end

  def popover_slot
    label { 'POPOVER-SLOT' }
  end

  def view; end
end
