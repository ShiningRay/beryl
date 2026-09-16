# frozen_string_literal: true

module Beryl
  # 浮层定位纯几何算法：锚点旁放弹层，放不下就翻转，仍越界就 shift 回视口。
  # Select 下拉 / Menu clamp / Popover 共用；输入输出全是纯哈希，CRuby 直接可测。
  module Overlay
    module_function

    # anchor:   { x:, y:, w:, h: }（锚元素矩形；点锚用 w: 0, h: 0）
    # size:     { w:, h: } 弹层尺寸
    # viewport: { w:, h: }
    # placement: :bottom | :top | :left | :right（首选方向，放不下翻转到对侧）
    # → { x:, y:, placement: }（左上角坐标，已 shift 进视口）
    def position(anchor:, size:, viewport:, placement: :bottom)
      best = coords(anchor, size, placement)
      chosen = placement
      flipped = coords(anchor, size, flip(placement))

      unless fits?(best, size, viewport)
        if fits?(flipped, size, viewport)
          best = flipped
          chosen = flip(placement)
        end
      end

      {
        x: clamp(best[:x], 0, [viewport[:w] - size[:w], 0].max),
        y: clamp(best[:y], 0, [viewport[:h] - size[:h], 0].max),
        placement: chosen,
      }
    end

    def coords(a, s, placement)
      case placement
      when :top   then { x: a[:x], y: a[:y] - s[:h] }
      when :left  then { x: a[:x] - s[:w], y: a[:y] }
      when :right then { x: a[:x] + a[:w], y: a[:y] }
      else             { x: a[:x], y: a[:y] + a[:h] } # :bottom
      end
    end

    def flip(placement)
      case placement
      when :top then :bottom
      when :bottom then :top
      when :left then :right
      when :right then :left
      else placement
      end
    end

    def fits?(coord, size, viewport)
      coord[:x] >= 0 && coord[:y] >= 0 &&
        coord[:x] + size[:w] <= viewport[:w] &&
        coord[:y] + size[:h] <= viewport[:h]
    end

    def clamp(v, lo, hi)
      v = lo if v < lo
      v = hi if v > hi
      v
    end
  end

  # L2 · 通用浮层容器：fixed 定位 + 可选全屏捕获层（点任意处关闭）。
  # x/y 是锚点坐标（配合 Overlay.position 预先换算好左上角也可直接传）。
  class Popover < Citrine::Component
    prop :x, type: Numeric
    prop :y, type: Numeric
    prop :placement, default: :bottom
    prop :viewport          # { w:, h: } 可选；传了才做视口防溢出
    prop :size              # { w:, h: } 弹层估算尺寸，clamp 用
    prop :z_index, type: Numeric, default: 2900
    prop :tabindex        # Numeric，可空
    prop :autofocus
    prop :on_key
    prop :on_close
    prop :css_class, type: String, default: 'b-popover'
    prop :content           # Proc 插槽

    def view
      if on_close
        box(css_class: 'menu-overlay', on_click: ->(_e) { on_close.call },
            on_menu: ->(ev) { ev.preventDefault; on_close.call })
      end
      opts = { tabindex: tabindex, autofocus: true }.select { |_, v| v }
      pos = placed
      box(css_class: css_class, direction: :column,
          style: { position: 'fixed', left: "#{pos[:x]}px", top: "#{pos[:y]}px",
                   z_index: z_index },
          on_key: on_key, **opts) do
        content.call if content
      end
    end

    def placed
      return { x: x, y: y } unless viewport && size

      Overlay.position(
        anchor: { x: x, y: y, w: 0, h: 0 },
        size: size, viewport: viewport, placement: placement,
      )
    end
  end

  # L2 · 文字提示（受控，M7）。open 传 Signal 受控显隐；on_hover 透传到锚容器，
  # 消费者一行完成布线（F4：交互态必须受控；不传 open 回退内部态，仅自根挂载可用）。
  # CSS 锚定四向 placement（.b-tooltip.is-*），不走坐标定位——提示跟随锚内容即可。
  class Tooltip < Citrine::Component
    prop :text             # String 提示文案
    prop :anchor           # String，可空：纯文本锚（content 插槽缺省时用）
    prop :content          # Proc 插槽：锚内容（发射节点，F2）
    prop :open             # Signal<bool> 受控显隐，可空
    prop :placement, default: :top   # :top | :bottom | :left | :right
    prop :on_hover         # ->(hovering) L1 原语透传，可空

    state :internal_open, default: false

    def view
      opts = { css_class: 'b-tooltip-wrap',
               style: { position: 'relative', display: 'inline-block' } }
      opts[:on_hover] = ->(hovering) { set_open(hovering) } if on_hover
      box(**opts) do
        if content
          content.call
        else
          label { anchor.to_s }
        end
        bubble if open?
      end
    end

    def bubble
      box(css_class: "b-tooltip is-#{placement}") { text.to_s }
    end

    def open?
      open ? open.get : internal_open
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end
  end
end
