# frozen_string_literal: true

module Beryl
  # L2 · 数字输入：text_input（Signal 双向）+ 步进按钮
  class NumberInput < Citrine::Component
    prop :value            # Signal
    prop :min, type: Numeric, default: 0
    prop :max, type: Numeric, default: 100
    prop :step, type: Numeric, default: 1
    prop :width, type: Numeric, default: 72
    prop :on_change

    def view
      row(css_class: 'b-number', gap: 4) do
        button(css_class: 'b-number-btn', on_click: :step_down) { '−' }
        text_input(value: value, css_class: 'b-number-input',
                   style: { width: "#{width}px" })
        button(css_class: 'b-number-btn', on_click: :step_up) { '+' }
      end
    end

    def step_by(delta)
      v = value.get.to_f + delta
      v = min if v < min
      v = max if v > max
      value.set(v)
      on_change&.call(v)
    end

    def step_up;   step_by(step);   end
    def step_down; step_by(-step);  end
  end
end
