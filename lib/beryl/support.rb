# frozen_string_literal: true

module Beryl
  # 定时器：L2 只依赖这里的抽象（纯 CRuby，无 JS）。
  # Opal 后端由 L1 renderer 在加载时注入（setTimeout/clearTimeout）；
  # CRuby 测试可注入同步后端：Beryl::Timer.backend = ->(ms, blk) { blk.call }
  module Timer
    class << self
      # ->(ms, blk) → handle
      attr_accessor :backend
      # ->(handle)
      attr_accessor :cancel_backend

      def after(ms, &blk)
        backend ? backend.call(ms, blk) : nil
      end

      def cancel(handle)
        cancel_backend&.call(handle) if handle
      end
    end
  end

  # 数据拖放的传输通道：dragstart 存、drop 取（同文档内有效）。
  # 不走 dataTransfer 序列化，payload 可以是任意 Ruby 对象（数组/Signal/模型）。
  module DragBus
    class << self
      attr_accessor :current

      def take
        payload = @current
        @current = nil
        payload
      end
    end
  end

  # 全局 z 序分配器：浮层/窗口从同一计数器取值，后开者在上。
  # WindowManager 的窗口 z 另按注册顺序计算，不占用此计数器。
  def self.next_z
    @z_counter = (@z_counter ||= 2000) + 1
  end

  # 哈希取键：兼容 symbol / string 键（Menu items 等公共数据契约）
  def self.pick(hash, key)
    hash[key] || hash[key.to_s] || hash[key.to_sym]
  end

  # 控件 prop 取值归一：bool | Signal 两可（disabled/loading/error …）。
  # F4 受控哲学：跨渲染存活的交互态由消费者传 Signal，明值用于静态场景。
  def self.flag(v)
    v.respond_to?(:get) ? v.get : v
  end

  # 选项契约归一：接受 [label, value] 数组或 { label:, value: } 哈希
  # （Select/MultiSelect/RadioGroup/CheckboxGroup 等公共数据契约）
  def self.option_label(opt)
    opt.is_a?(Hash) ? Beryl.pick(opt, :label) : opt[0]
  end

  def self.option_value(opt)
    opt.is_a?(Hash) ? Beryl.pick(opt, :value) : opt[1]
  end

  # 拖拽几何核心（纯 CRuby，F5）：「mousedown 基准几何 + 屏幕指针位移」→ 手势几何。
  # 数学从 L1 setup_drag 提出，CRuby 可直接回归测试。
  # drag_scale（世界缩放倍率，如 ZUI 相机 zoom）：offsetLeft/Top 是布局（世界）
  # 坐标，不受容器 CSS transform 影响，而 clientX/Y 是屏幕像素——zoom ≠ 1 时
  # 屏幕位移必须 ÷ scale 才等于布局位移，否则拖拽漂移（zoom=2 跑双倍距离）。
  module DragGeometry
    # base     {left:, top:, w:, h:}  mousedown 时的面板几何（布局坐标，口径同 offset*）
    # dx/dy    屏幕像素位移（clientX/Y − 手势起点）
    # scale    drag_scale（mousedown 时取值；nil → 1.0）
    # move     true=移动 / false=缩放；dir 八向；min [w, h] 最小尺寸
    # clamp    限制在视口内（横留 60 / 纵留 30 可见）；viewport {w:, h:}
    def self.compute(base, dx, dy, scale: 1.0, move: true, dir: 'se', min: [160, 70], clamp: false, viewport: nil)
      scale = 1.0 if scale.nil?
      ldx = dx / scale
      ldy = dy / scale
      if move
        left = base[:left] + ldx
        top = base[:top] + ldy
        if clamp && viewport
          left = [[left, 60 - base[:w]].max, viewport[:w] - 60].min
          top = [[top, 0].max, viewport[:h] - 30].min
        end
        { left: left, top: top, w: base[:w], h: base[:h] }
      else
        min_w, min_h = min
        w = base[:w]
        h = base[:h]
        left = base[:left]
        top = base[:top]
        w = base[:w] + ldx if dir.include?("e")
        h = base[:h] + ldy if dir.include?("s")
        w = base[:w] - ldx if dir.include?("w")
        h = base[:h] - ldy if dir.include?("n")
        w = min_w if w < min_w
        h = min_h if h < min_h
        left = base[:left] + (base[:w] - w) if dir.include?("w")
        top = base[:top] + (base[:h] - h) if dir.include?("n")
        { left: left, top: top, w: w, h: h }
      end
    end
  end
end
