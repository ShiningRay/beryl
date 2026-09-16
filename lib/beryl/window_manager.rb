# frozen_string_literal: true

module Beryl
  # L3 · 窗口管理器：注册表 + z 序 + 最大化/最小化 + 视口 clamp + 边缘吸附。
  # 纯服务（非组件）：状态是 Signal，消费者在 view 里读即自动订阅；
  # WindowFrame 保持无状态，几何/回调由 #frame 统一接线。
  #
  # 吸附语义（Aero Snap 简化版）：拖到顶边 → 最大化；左/右边 → 半屏。
  # 拖动已最大化/吸附窗口 → 恢复原尺寸再定位。落点吸附只在松手时判定（无实时预览）。
  class WindowManager
    Record = Struct.new(:id, :title, :geom, :state, :min_w, :min_h)

    SNAP_EDGE = 8   # 距边多少像素内触发吸附
    CANON = { 'px' => :x, 'py' => :y, 'pw' => :w, 'ph' => :h,
              x: :x, y: :y, w: :w, h: :h }.freeze

    attr_reader :viewport

    def initialize(viewport: nil)
      @viewport = viewport
      # z 序（末尾 = 最上层），也是注册表成员表；signal_list 让「改集合」本身成为触发点
      @order = Citrine.signal_list([])
      @records = {}
    end

    def viewport=(vp)
      @viewport = vp
    end

    # ── 注册表 ────────────────────────────────────────────
    #
    # 变更操作禁止在 view/Effect 内调用：Signal#set 同步重跑订阅者，
    # 「view 里 open → set(@order) → 触发 view 重跑 → @wm memo 尚未赋值 →
    # 再 new 再 open」会无限重入（demo 真实踩坑）。窗口在初始化阶段
    # （mount 前）注册；运行期 focus/place 等只从事件回调进入（无 Effect）。

    def open(id, title: id.to_s, geometry:, min_w: 160, min_h: 70)
      assert_outside_effect!(:open)
      raise ArgumentError, "窗口 #{id} 已存在" if @records.key?(id)

      @records[id] = Record.new(id, title,
                                Citrine::Signal.new(normalize(geometry)),
                                Citrine::Signal.new({ minimized: false, maximized: false, restore: nil }),
                                min_w, min_h)
      @order << id
      self
    end

    def close(id)
      assert_outside_effect!(:close)
      @records.delete(id)
      @order.delete(id)
    end

    def windows
      @order.get   # 读 Signal → 视图订阅开/关
    end

    def record(id)
      @records[id]
    end

    def each_window
      @order.get.each { |id| yield @records[id] }
      nil # 块的返回值不外泄——否则空窗时块返回 []，会被渲染层 tos 成可见 "[]" 文本
    end

    # ── 状态查询（view 内读取即响应式）────────────────────

    def geometry(id)
      r = @records[id]
      r && r.geom.get
    end

    def z(id)
      i = @order.get.index(id)
      i && 100 + i
    end

    def active?(id)
      @order.get.last == id && !minimized?(id)
    end

    def minimized?(id)
      st(id)[:minimized]
    end

    def maximized?(id)
      st(id)[:maximized]
    end

    # ── 操作 ──────────────────────────────────────────────

    def focus(id)
      assert_outside_effect!(:focus)
      return unless @records[id]

      r = @records[id]
      r.state.set(r.state.get.merge(minimized: false)) if r.state.get[:minimized]
      @order.set(@order.get - [id] + [id])
    end

    def toggle_min(id)
      assert_outside_effect!(:toggle_min)
      r = @records[id] or return
      r.state.set(r.state.get.merge(minimized: !r.state.get[:minimized]))
    end

    def toggle_max(id)
      assert_outside_effect!(:toggle_max)
      r = @records[id] or return
      s = r.state.get
      if s[:maximized]
        r.state.set(s.merge(maximized: false, restore: nil))
        r.geom.set(s[:restore]) if s[:restore]
      else
        restore_to = r.geom.get
        r.state.set(s.merge(maximized: true, restore: restore_to))
        r.geom.set(full_rect) if @viewport
      end
    end

    def move(id, x, y)
      g = geometry(id) or return
      place(id, { x: x, y: y, w: g[:w], h: g[:h] })
    end

    def resize(id, w, h)
      g = geometry(id) or return
      place(id, { x: g[:x], y: g[:y], w: w, h: h })
    end

    # 拖拽/缩放落点统一入口：restore → (吸附，仅拖动) → clamp → 写回。
    # 吸附只跟拖动走（snap: true，由 frame 的 on_move 接线）：
    # clamp 到边缘的坐标必然落在吸附带里，缩放/程序化 place 一吸附就乱。
    def place(id, payload, snap: false)
      assert_outside_effect!(:place)
      r = @records[id] or return
      g = normalize(payload)
      s = r.state.get

      if s[:maximized] || s[:restore]
        rg = s[:restore] || r.geom.get
        r.state.set(s.merge(maximized: false, restore: nil))
        g = { x: g[:x], y: g[:y], w: rg[:w], h: rg[:h] }
      end

      g = snap_zone(g) ? apply_snap(r, g, snap_zone(g)) : clamp_geom(r, g) if snap
      g = clamp_geom(r, g) unless snap
      r.geom.set(g)
    end

    # 变更操作若在 Effect（view 渲染）内执行，set 会同步重入渲染造成无限递归；
    # 直接 fail fast，把问题暴露在写错的瞬间而不是栈溢出时
    def assert_outside_effect!(op)
      return unless Citrine::Effect.current

      raise ArgumentError,
            "WindowManager##{op} 不能在 view/Effect 内调用（set 会同步重入渲染）。" \
            "窗口注册请在初始化阶段完成；运行期变更请从事件回调进入。"
    end

    # ── WindowFrame 接线 ──────────────────────────────────

    # 在消费者 view 内调用：读取 order/geom/state 信号并构建窗口框。
    #   wm.frame(:inspector, content: -> { ... }, maximizable: true).view
    # opts 透传 WindowFrame（shape/css_class/drag_scale 等）；另有 wm 级开关：
    #   snap: false —— 拖到屏幕边缘不触发吸附（异形窗口的矩形假设不适用）
    def frame(id, **opts)
      r = @records[id]
      raise ArgumentError, "窗口 #{id} 未注册" unless r

      g = r.geom.get
      snap = opts.delete(:snap) { true }
      flags = {
        closable: opts.delete(:closable) { true },
        minimizable: opts.delete(:minimizable) { true },
        maximizable: opts.delete(:maximizable) { true },
      }
      Beryl::WindowFrame.new(
        title: r.title,
        geometry: { 'px' => g[:x], 'py' => g[:y], 'pw' => g[:w], 'ph' => g[:h] },
        z_index: z(id),
        active: active?(id),
        minimized: r.state.get[:minimized],
        maximized: r.state.get[:maximized],
        min_w: r.min_w, min_h: r.min_h,
        on_front: ->(_el) { focus(id) },
        on_move: ->(ev) { place(id, ev, snap: snap) },
        on_resize: ->(ev) { place(id, ev) },
        on_head_dblclick: ->(_ev) { toggle_max(id) },
        on_minimize: -> { toggle_min(id) },
        on_maximize: -> { toggle_max(id) },
        on_close: -> { close(id) },
        **flags, **opts,
      )
    end

    # ── 几何规则 ──────────────────────────────────────────

    private

    def normalize(g)
      out = {}
      CANON.each { |from, to| out[to] = g[from] if g.key?(from) }
      out
    end

    def st(id)
      r = @records[id]
      r ? r.state.get : {}
    end

    def clamp_geom(r, g)
      return g unless @viewport

      min_w = r.min_w
      min_h = r.min_h
      g[:w] = min_w if g[:w] && g[:w] < min_w
      g[:h] = min_h if g[:h] && g[:h] < min_h
      g[:w] = @viewport[:w] if g[:w] && g[:w] > @viewport[:w]
      g[:h] = @viewport[:h] if g[:h] && g[:h] > @viewport[:h]
      # 拖出界仍要留一条可见（60×30）
      g[:x] = [g[:x], @viewport[:w] - 60].min if g[:x]
      g[:x] = [g[:x], -(g[:w].to_i - 60)].max if g[:x] && g[:w]
      g[:y] = [g[:y], @viewport[:h] - 30].min if g[:y]
      g[:y] = 0 if g[:y] && g[:y].negative?
      g
    end

    def snap_zone(g)
      return nil unless @viewport

      vw = @viewport[:w]
      vh = @viewport[:h]
      if g[:y] <= SNAP_EDGE
        { x: 0, y: 0, w: vw, h: vh }
      elsif g[:x] <= SNAP_EDGE
        { x: 0, y: 0, w: vw / 2, h: vh }
      elsif g[:x] + g[:w] >= vw - SNAP_EDGE
        { x: vw - vw / 2, y: 0, w: vw / 2, h: vh }
      end
    end

    def apply_snap(r, _g, rect)
      s = r.state.get
      r.state.set(s.merge(maximized: rect[:w] == @viewport[:w], restore: r.geom.get))
      rect
    end

    def full_rect
      { x: 0, y: 0, w: @viewport[:w], h: @viewport[:h] }
    end
  end
end
