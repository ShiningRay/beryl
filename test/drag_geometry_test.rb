# frozen_string_literal: true

# 拖拽几何回归（Beryl::DragGeometry，L1 setup_drag 的纯数学核心）：
# scale=1 时与既有行为逐点一致；drag_scale（世界缩放补偿）把屏幕位移
# ÷ scale 再进布局坐标——ZUI zoom≠1 不补偿会漂移（zoom=2 跑双倍距离）。
require 'minitest/autorun'
require 'beryl'

class DragGeometryTest < Minitest::Test
  BASE = { left: 100, top: 80, w: 300, h: 200 }.freeze

  # ── scale=1：移动 ─────────────────────────────────────

  def test_move_plain
    assert_equal({ left: 130, top: 100, w: 300, h: 200 },
                 Beryl::DragGeometry.compute(BASE, 30, 20))
  end

  def test_move_clamp_keeps_60x30_visible
    vp = { w: 1200, h: 800 }
    g = Beryl::DragGeometry.compute(BASE, 10_000, 10_000, clamp: true, viewport: vp)
    assert_equal 1140, g[:left]                # vw - 60
    assert_equal 770, g[:top]                  # vh - 30
    g = Beryl::DragGeometry.compute(BASE, -10_000, -10_000, clamp: true, viewport: vp)
    assert_equal(-240, g[:left])               # 只留 60px 露出
    assert_equal 0, g[:top]
  end

  # ── scale=1：八向缩放 ─────────────────────────────────

  def test_resize_se_grows
    assert_equal({ left: 100, top: 80, w: 360, h: 240 },
                 Beryl::DragGeometry.compute(BASE, 60, 40, move: false, dir: 'se'))
  end

  def test_resize_ne_combines_n_and_e
    assert_equal({ left: 100, top: 50, w: 340, h: 230 },
                 Beryl::DragGeometry.compute(BASE, 40, -30, move: false, dir: 'ne'))
  end

  def test_resize_w_shifts_left
    assert_equal({ left: 50, top: 80, w: 350, h: 200 },
                 Beryl::DragGeometry.compute(BASE, -50, 0, move: false, dir: 'w'))
  end

  def test_resize_enforces_min_and_anchors_far_side
    # 拖过最小宽：w 钳到 min，left 锚在 ol + (ow - min_w)
    g = Beryl::DragGeometry.compute(BASE, 500, 0, move: false, dir: 'w', min: [160, 70])
    assert_equal 160, g[:w]
    assert_equal 100 + (300 - 160), g[:left]
    g = Beryl::DragGeometry.compute(BASE, 0, 500, move: false, dir: 'n', min: [160, 70])
    assert_equal 70, g[:h]
    assert_equal 80 + (200 - 70), g[:top]
  end

  # ── drag_scale：世界缩放补偿（ZUI 关键路径）────────────

  def test_scale_zoom_in_halves_world_travel
    # zoom=2：指针拖 60/40 屏幕像素 = 30/20 世界像素
    assert_equal({ left: 130, top: 100, w: 300, h: 200 },
                 Beryl::DragGeometry.compute(BASE, 60, 40, scale: 2.0))
  end

  def test_scale_zoom_out_doubles_world_travel
    # zoom=0.5：指针拖 15/10 屏幕像素 = 30/20 世界像素
    assert_equal({ left: 130, top: 100, w: 300, h: 200 },
                 Beryl::DragGeometry.compute(BASE, 15, 10, scale: 0.5))
  end

  def test_scale_applies_to_resize_handle
    g = Beryl::DragGeometry.compute(BASE, 120, 80, scale: 2.0, move: false, dir: 'se')
    assert_equal({ left: 100, top: 80, w: 360, h: 240 }, g)
  end

  def test_scale_all_zui_tiers_match_unscaled_math
    # Z1 验收五档：各档下同等世界位移，手感与光标一致
    [0.25, 0.5, 1.0, 2.0, 4.0].each do |z|
      g = Beryl::DragGeometry.compute(BASE, 30 * z, 20 * z, scale: z)
      assert_equal({ left: 130, top: 100, w: 300, h: 200 }, g, "zoom=#{z}")
    end
  end

  def test_nil_scale_defaults_to_one
    assert_equal({ left: 130, top: 100, w: 300, h: 200 },
                 Beryl::DragGeometry.compute(BASE, 30, 20, scale: nil))
  end
end
