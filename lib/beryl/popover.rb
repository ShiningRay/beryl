# frozen_string_literal: true

module Beryl
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
end
