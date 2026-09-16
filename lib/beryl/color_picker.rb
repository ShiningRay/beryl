# frozen_string_literal: true

module Beryl
  # L2 · 取色器 v1：预设色板网格（自由取色等 Canvas 原语就绪）
  class ColorPicker < Citrine::Component
    PALETTE = %w[#4f8cff #3fb950 #d29922 #f85149 #bc8cff #39c5cf
                 #ffffff #adbac7 #6e7681 #22272e #e2c08d #ff9bce].freeze
    prop :value            # Signal<String>
    prop :colors, default: PALETTE
    prop :on_change

    def view
      box(css_class: 'b-colorpicker') do
        row(css_class: 'b-color-grid', gap: 6) do
          colors.each do |c|
            box(css_class: value.get == c ? 'b-color-swatch is-active' : 'b-color-swatch',
                style: { background: c },
                on_click: ->(_e) { on_change&.call(c) })
          end
        end
      end
    end
  end
end
