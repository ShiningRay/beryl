# frozen_string_literal: true

module Beryl
  # L2 · 滑杆（受控）：− / + 步进 + 进度条视觉；拖拽滑块留待数据拖放原语就绪
  class Slider < Citrine::Component
    prop :value            # Signal<Numeric>
    prop :min, type: Numeric, default: 0
    prop :max, type: Numeric, default: 100
    prop :step, type: Numeric, default: 1
    prop :on_change

    def view
      row(css_class: 'b-slider', gap: 8) do
        button(css_class: 'b-slider-btn', on_click: :step_down) { '−' }
        box(css_class: 'b-slider-track') do
          box(css_class: 'b-slider-fill', style: { width: "#{pct}%" })
          box(css_class: 'b-slider-thumb', style: { left: "#{pct}%" })
        end
        button(css_class: 'b-slider-btn', on_click: :step_up) { '+' }
      end
    end

    def step_by(delta)
      v = value.get.to_f + delta
      v = min if v < min
      v = max if v > max
      on_change&.call(v)
    end

    def step_up;   step_by(step);   end
    def step_down; step_by(-step);  end

    private

    def pct
      span = max - min
      return 0 if span.zero?

      (((value.get.to_f - min) / span) * 100).round(2)
    end
  end
end
