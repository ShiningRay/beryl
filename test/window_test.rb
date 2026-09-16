# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class WindowTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  VP = { w: 1200, h: 800 }

  # ── 注册表 / z 序 ─────────────────────────────────────

  def test_open_close_and_z_order
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 10, y: 10, w: 200, h: 150 })
           .open(:b, title: 'B 窗', geometry: { x: 50, y: 50, w: 300, h: 200 })
    assert_equal [:a, :b], wm.windows
    assert_operator wm.z(:b), :>, wm.z(:a)
    assert wm.active?(:b)                  # 后开者在上

    wm.focus(:a)
    assert wm.active?(:a)
    assert_operator wm.z(:a), :>, wm.z(:b)
    assert_equal [:a, :b], wm.windows.reverse

    wm.close(:a)
    assert_equal [:b], wm.windows
    assert_nil wm.geometry(:a)
  end

  def test_open_rejects_duplicate_id
    wm = Beryl::WindowManager.new
    wm.open(:a, geometry: { x: 0, y: 0, w: 10, h: 10 })
    assert_raises(ArgumentError) { wm.open(:a, geometry: { x: 0, y: 0, w: 10, h: 10 }) }
  end

  # 变更操作在 Effect 内会同步重入渲染（Signal#set 同步跑订阅者），必须 fail fast
  def test_mutations_raise_inside_effect
    wm = Beryl::WindowManager.new(viewport: VP)
    error = nil
    effect = Citrine::Effect.create do
      begin
        wm.open(:a, geometry: { x: 0, y: 0, w: 10, h: 10 })
      rescue ArgumentError => e
        error = e
      end
      nil
    end
    effect.dispose
    assert error
    assert_match(/view\/Effect/, error.message)
  end

  # ── clamp ─────────────────────────────────────────────

  def test_place_clamps_to_viewport
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 0, y: 0, w: 300, h: 200 })
    wm.place(:a, { x: 5000, y: 5000, w: 300, h: 200 })
    g = wm.geometry(:a)
    assert_equal 1140, g[:x]               # vw - 60
    assert_equal 770, g[:y]                # vh - 30
    wm.place(:a, { x: -10_000, y: -10_000, w: 300, h: 200 })
    g = wm.geometry(:a)
    assert_equal(-240, g[:x])              # 只留 60px 露出
    assert_equal 0, g[:y]
  end

  def test_resize_enforces_min_and_viewport_max
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 0, y: 0, w: 300, h: 200 }, min_w: 240, min_h: 120)
    wm.resize(:a, 10, 10)
    g = wm.geometry(:a)
    assert_equal 240, g[:w]
    assert_equal 120, g[:h]
    wm.resize(:a, 99_999, 99_999)
    g = wm.geometry(:a)
    assert_equal 1200, g[:w]
    assert_equal 800, g[:h]
  end

  def test_no_viewport_no_clamp
    wm = Beryl::WindowManager.new
    wm.open(:a, geometry: { x: 0, y: 0, w: 100, h: 80 })
    wm.place(:a, { x: 50_000, y: 50_000, w: 100, h: 80 })
    g = wm.geometry(:a)
    assert_equal 50_000, g[:x]
  end

  # ── 吸附（Aero Snap）──────────────────────────────────

  def test_snap_top_maximizes_and_keeps_restore
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 100, y: 100, w: 400, h: 300 })
    wm.place(:a, { x: 100, y: 2, w: 400, h: 300 }, snap: true)   # 顶边 → 最大化
    assert wm.maximized?(:a)
    assert_equal({ x: 0, y: 0, w: 1200, h: 800 }, wm.geometry(:a))
    # 拖动已最大化窗口 → 恢复原尺寸、以新落点定位
    wm.place(:a, { x: 300, y: 200, w: 1200, h: 800 }, snap: true)
    refute wm.maximized?(:a)
    g = wm.geometry(:a)
    assert_equal 400, g[:w]
    assert_equal 300, g[:h]
    assert_equal 300, g[:x]
  end

  def test_snap_left_right_halves
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 600, y: 100, w: 400, h: 300 })
    wm.place(:a, { x: 1, y: 300, w: 400, h: 300 }, snap: true)
    assert_equal({ x: 0, y: 0, w: 600, h: 800 }, wm.geometry(:a))
    wm.place(:a, { x: 1198, y: 300, w: 600, h: 800 }, snap: true)
    assert_equal({ x: 600, y: 0, w: 600, h: 800 }, wm.geometry(:a))
  end

  def test_programmatic_place_never_snaps
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 500, y: 100, w: 300, h: 200 })
    wm.place(:a, { x: 900, y: 400, w: 300, h: 200 })   # 贴近右缘但不触发（snap 未开）
    g = wm.geometry(:a)
    assert_equal({ x: 900, y: 400, w: 300, h: 200 }, g)
  end

  # ── 最大化/最小化 ─────────────────────────────────────

  def test_toggle_max_and_min
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, title: 'A', geometry: { x: 100, y: 100, w: 400, h: 300 })
    wm.toggle_max(:a)
    assert wm.maximized?(:a)
    assert_equal({ x: 0, y: 0, w: 1200, h: 800 }, wm.geometry(:a))
    wm.toggle_max(:a)
    assert_equal({ x: 100, y: 100, w: 400, h: 300 }, wm.geometry(:a))

    wm.toggle_min(:a)
    assert wm.minimized?(:a)
    refute wm.active?(:a)                  # 最小化不算激活
    wm.focus(:a)                           # focus 还原最小化
    refute wm.minimized?(:a)
  end

  # ── frame 接线 ────────────────────────────────────────

  def test_frame_renders_wired_window_frame
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:inspector, title: 'Inspector', geometry: { x: 8, y: 8, w: 300, h: 400 })
    host = WmHost.new(wm, :inspector)
    html = render(host)
    assert_includes html, 'Inspector'
    assert_includes html, 'left:8px'
    assert_includes html, 'width:300px'
    assert_includes html, 'is-active'
    assert_includes html, 'b-win-btn'      # chrome 控制钮（frame 默认全开）
    assert_includes html, 'rs-ne'          # 八向手柄
    assert_includes html, 'WM-SLOT'
    assert_raises(ArgumentError) { wm.frame(:missing) }
  end

  def test_frame_front_moves_window_to_top
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 0, y: 0, w: 100, h: 80 })
    wm.open(:b, geometry: { x: 0, y: 0, w: 100, h: 80 })
    host_a = WmHost.new(wm, :a)
    frame_a = wm.frame(:a, content: -> { label { 'x' } })
    frame_a.on_front.call(nil)             # 模拟 mousedown 置顶
    assert wm.active?(:a)
  end

  # 未激活窗口的 mousedown 会先 focus，导致宿主 view 重跑并改变 z 序。
  # WindowManager 必须让同一窗口继续复用原 DOM；否则 setup_drag 持有的旧 pane
  # 会变成游离节点，mousemove 期间看不到窗口移动，只在 mouseup 落点回写。
  def test_frame_identity_survives_focus_reorder
    wm = Beryl::WindowManager.new
    wm.open(:a, geometry: { x: 0, y: 0, w: 100, h: 80 })
       .open(:b, geometry: { x: 20, y: 20, w: 100, h: 80 })
    host = WindowIdentityHost.new(wm)
    renderer = WindowIdentityRenderer.new
    root = renderer.mount_component(host, WindowIdentityDom.new)
    dom_by_id = root.children.to_h { |node| [node.reuse_key, node.dom] }

    wm.focus(:a)

    assert_same dom_by_id[:a], root.children.find { |node| node.reuse_key == :a }.dom
    assert_same dom_by_id[:b], root.children.find { |node| node.reuse_key == :b }.dom
    assert_equal [:b, :a], root.children.map(&:reuse_key)
  end

  def test_frame_move_and_close_wiring
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 0, y: 0, w: 300, h: 200 })
    frame = wm.frame(:a)
    frame.on_move.call({ x: 30, y: 40, w: 300, h: 200 })
    assert_equal({ x: 30, y: 40, w: 300, h: 200 }, wm.geometry(:a))
    frame.on_close.call
    assert_nil wm.geometry(:a)
    assert_equal [], wm.windows
  end

  # drag_scale：世界缩放补偿（ZUI 相机 zoom）——prop 契约 + wm.frame opts 透传。
  # L1 原语在浏览器侧才接线，这里锁 prop 通路；数学在 DragGeometryTest 逐点锁。
  def test_frame_drag_scale_prop_and_passthrough
    html = render(Beryl::WindowFrame.new(
      title: 'z', geometry: { 'px' => 1, 'py' => 1 }, drag_scale: 2.0,
      on_move: ->(_ev) {}, on_resize: ->(_ev) {},
      content: -> { nil },
    ))
    assert_includes html, 'rs-handle'        # drag_scale 不改结构，随标题栏/手柄透传
    wm = Beryl::WindowManager.new
    wm.open(:a, geometry: { x: 0, y: 0, w: 100, h: 80 })
    frame = wm.frame(:a, drag_scale: -> { 2.0 }, content: -> { nil })
    assert_equal 2.0, frame.drag_scale.call  # callable（mousedown 时取值）经 opts 透传
  end

  # ── Taskbar ───────────────────────────────────────────

  def test_taskbar_renders_and_toggles
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, title: '编辑器', geometry: { x: 0, y: 0, w: 200, h: 150 })
    wm.open(:b, title: '检查器', geometry: { x: 0, y: 0, w: 200, h: 150 })
    host = TaskbarHost.new(wm)
    html = render(host)
    assert_includes html, '编辑器'
    assert_includes html, '检查器'
    assert_includes html, 'is-active'      # b 激活

    taskbar = Beryl::Taskbar.new(wm: wm)
    taskbar.activate(:b)                   # 激活窗口再点 → 最小化
    assert wm.minimized?(:b)
    taskbar.activate(:b)                   # 最小化再点 → 还原置顶
    refute wm.minimized?(:b)
    assert wm.active?(:b)
  end

  def test_taskbar_empty_renders_no_brackets
    wm = Beryl::WindowManager.new(viewport: VP)
    html = render(TaskbarHost.new(wm))
    refute_includes html, '[]'             # each_window 空表不外泄：块返回值曾被 tos 成可见 "[]"
    assert_includes html, 'b-taskbar'
  end

  # ── WindowFrame chrome / minimized ────────────────────

  def test_window_frame_chrome_is_opt_in
    html = render(Beryl::WindowFrame.new(
      title: 'bare', geometry: { 'px' => 1, 'py' => 1 }, content: -> { nil },
    ))
    refute_includes html, 'b-win-btn'
    assert_raises(ArgumentError) do
      Beryl::WindowFrame.new(title: 'x', geometry: {}, bogus: 1)
    end
  end

  def test_window_frame_minimized_renders_nothing
    html = render(Beryl::WindowFrame.new(
      title: 'gone', geometry: { 'px' => 1, 'py' => 1 }, minimized: true,
      content: -> { nil },
    ))
    assert_equal '', html
  end

  def test_window_frame_active_inactive_class
    on = render(Beryl::WindowFrame.new(title: 'x', geometry: {}, active: true, content: -> { nil }))
    assert_includes on, 'is-active'
    off = render(Beryl::WindowFrame.new(title: 'x', geometry: {}, active: false, content: -> { nil }))
    assert_includes off, 'is-inactive'
  end

  # 最大化态：□ 控制钮变还原图标 ⧉（还原入口就是同一颗按钮；
  # tooltip 是 L1 tip 原语，SSR 不序列化，浏览器侧验收）
  def test_window_frame_maximized_glyph
    normal = render(Beryl::WindowFrame.new(title: 'x', geometry: {}, maximizable: true, on_maximize: -> {}))
    assert_includes normal, '□'
    refute_includes normal, '⧉'
    maxed = render(Beryl::WindowFrame.new(title: 'x', geometry: {}, maximizable: true,
                                          maximized: true, on_maximize: -> {}))
    assert_includes maxed, '⧉'
    refute_includes maxed, '□'
    assert_includes maxed, 'is-maximized'
  end

  def test_window_frame_dblclick_wiring
    dblclicked = false
    host = DblHost.new(-> { dblclicked = true })
    render(host)                           # 触发渲染路径
    host.frame.on_head_dblclick.call
    assert dblclicked
  end

  # ── 异形窗口（shape）───────────────────────────────────

  def test_window_frame_shape_wraps_and_clips
    html = render(Beryl::WindowFrame.new(
      title: 'note', geometry: { 'px' => 10, 'py' => 10, 'pw' => 240, 'ph' => 240 },
      css_class: 'sticky-note-win', shape: 'polygon(0 0, 100% 0, 100% 100%)',
      content: -> { nil },
    ))
    assert_includes html, 'panel-wrap sticky-note-win'  # 包裹层带 css_class（样式锚点）
    assert_includes html, 'left:10px'                   # 定位/z 序在包裹层
    assert_includes html, 'drop-shadow'                 # 阴影随裁剪轮廓
    assert_includes html, 'clip-path:polygon'           # 裁剪作用于内层 .panel
    assert_includes html, 'width:100%'
    assert_match(/panel-wrap.*?clip-path/m, html)       # 裁剪节点必须在包裹层内部 emit
    refute_includes html, '#<Citrine'                   # 节点不得作为文本泄漏（块返回值坑）
  end

  def test_window_frame_without_shape_has_no_wrap
    html = render(Beryl::WindowFrame.new(
      title: 'plain', geometry: { 'px' => 1, 'py' => 1 }, content: -> { nil },
    ))
    refute_includes html, 'panel-wrap'
    refute_includes html, 'clip-path'
  end

  def test_frame_snap_opt_out
    wm = Beryl::WindowManager.new(viewport: VP)
    wm.open(:a, geometry: { x: 100, y: 100, w: 200, h: 150 })
    frame = wm.frame(:a, snap: false, content: -> { nil })
    frame.on_move.call({ x: 100, y: 2, w: 200, h: 150 })   # 顶边吸附带内
    refute wm.maximized?(:a)                               # snap: false → 不吸附
    assert_equal 2, wm.geometry(:a)[:y]

    snapped = wm.frame(:a, content: -> { nil })            # 默认仍吸附
    snapped.on_move.call({ x: 100, y: 2, w: 200, h: 150 })
    assert wm.maximized?(:a)
  end

end

# ── 宿主组件 ─────────────────────────────────────────────

class WmHost < Citrine::Component
  def initialize(wm, id)
    @wm = wm
    @id = id
    super()
  end

  def view
    @wm.frame(@id, content: -> { slot }).view if @wm.windows.include?(@id)
  end

  def slot
    label { 'WM-SLOT' }
  end
end

class TaskbarHost < Citrine::Component
  def initialize(wm)
    @wm = wm
    super()
  end

  def view
    Beryl::Taskbar.new(wm: @wm).view
  end

end

class DblHost < Citrine::Component
  def initialize(handler)
    @handler = handler
    super()
  end

  def frame
    @frame ||= Beryl::WindowFrame.new(
      title: 'dbl', geometry: { 'px' => 0, 'py' => 0 },
      on_head_dblclick: @handler, content: -> { nil },
    )
  end

  def view
    frame.view
  end

end

# 只用于验证 WindowFrame 的复用身份；Beryl::Renderer 依赖 Opal，CRuby 侧用最小
# 内存渲染器模拟 DOM 的 append/detach 语义即可覆盖 focus → z 序重排这条路径。
class WindowIdentityDom
  attr_reader :children, :style
  attr_accessor :parent, :class_name, :text

  def initialize
    @children = []
    @style = {}
  end
end

class WindowIdentityRenderer < Citrine::Renderer
  private

  def setup_root(root, element)
    root.dom = element
  end

  def create_dom(_node)
    WindowIdentityDom.new
  end

  def attach(node, parent)
    parent.dom.children.delete(node.dom)
    parent.dom.children << node.dom
    node.dom.parent = parent.dom
  end

  def detach(node)
    return unless node.dom.parent

    node.dom.parent.children.delete(node.dom)
    node.dom.parent = nil
  end

  def apply_props(node)
    if node.props.key?(:css_class)
      css_class = prop_value(node, node.props[:css_class])
      node.dom.class_name = css_class.is_a?(Array) ? css_class.join(' ') : css_class.to_s
    end
    node.dom.style.replace(resolve_style(node))
  end

  def set_text(node, text)
    node.text = text
  end
end

class WindowIdentityHost < Citrine::Component
  def initialize(wm)
    @wm = wm
    super()
  end

  def view
    @wm.windows.each do |id|
      @wm.frame(id, content: -> { label { id.to_s } }).view
    end
    nil
  end
end
