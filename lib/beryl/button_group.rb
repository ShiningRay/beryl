# frozen_string_literal: true

module Beryl
  # L2 · 按钮组：横向排列若干 Button 的间距容器（内容归消费者，F2 插槽）。
  class ButtonGroup < Citrine::Component
    prop :content         # Proc 插槽
    prop :gap, type: Numeric, default: 6

    def view
      row(css_class: 'b-btn-group', gap: gap) { content&.call }
    end
  end
end
