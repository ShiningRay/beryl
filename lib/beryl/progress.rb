# frozen_string_literal: true

module Beryl
  # L2 · 进度条：value 可传数值或 Signal；indeterminate 走 CSS 动画
  class Progress < Citrine::Component
    prop :value            # Numeric | Signal<Numeric>
    prop :indeterminate, default: false
    prop :height, type: Numeric, default: 6

    def view
      box(css_class: indeterminate ? 'b-progress is-indeterminate' : 'b-progress',
          style: { height: "#{height}px" }) do
        box(css_class: 'b-progress-fill', style: { width: "#{pct}%" })
      end
    end

    def pct
      return 0 if indeterminate

      v = value.respond_to?(:get) ? value.get : value
      v = (v || 0).to_f
      v = 100 if v > 100
      v = 0 if v.negative?
      v.round(2)
    end
  end
end
