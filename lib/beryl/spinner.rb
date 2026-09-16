# frozen_string_literal: true

module Beryl
  # L2 · 加载指示（纯 CSS 旋转）。prop 叫 text 不叫 label——prop 定义的
  # 同名方法会遮住 view 里的 label 元素 DSL
  class Spinner < Citrine::Component
    prop :size, type: Numeric, default: 16
    prop :text             # String，可空

    def view
      row(css_class: 'b-spinner-row', gap: 8) do
        box(css_class: 'b-spinner', style: { width: "#{size}px", height: "#{size}px" })
        label { text } if text
      end
    end
  end
end
