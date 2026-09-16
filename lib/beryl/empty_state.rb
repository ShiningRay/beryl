# frozen_string_literal: true

module Beryl
  # L2 · 空状态：图标 + 文案 + 动作插槽
  class EmptyState < Citrine::Component
    prop :message, type: String, default: ''
    prop :icon, type: String, default: '∅'
    prop :action           # Proc 插槽（如 -> { button(...) { '新建' } }）

    def view
      stack(css_class: 'b-empty', gap: 8) do
        box(css_class: 'b-empty-icon') { icon }
        label { message }
        action&.call
      end
    end
  end
end
