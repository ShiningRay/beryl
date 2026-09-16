# frozen_string_literal: true

module Beryl
  # L2 · 工具栏 / 状态栏：插槽容器（内容归消费者）
  class Toolbar < Citrine::Component
    prop :content          # Proc 插槽
    prop :css_class, type: String, default: ''

    def view
      row(css_class: "b-toolbar #{css_class}".strip, gap: 6) { content&.call }
    end
  end
end
