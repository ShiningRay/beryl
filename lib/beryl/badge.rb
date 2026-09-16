# frozen_string_literal: true

module Beryl
  # L2 · 徽标：kind 可为 info/success/warn/error 或 nil（中性）。
  # prop 叫 text 不叫 label——远端 citrine 的 prop 宏已禁止与元素 DSL 同名
  class Badge < Citrine::Component
    prop :text, type: String
    prop :kind             # String，可空
    prop :css_class, type: String, default: ''  # 追加类（消费者自有配色，如 market 的 badge-hold）

    def view
      parts = ['b-badge']
      parts << "b-badge-#{kind}" if kind
      parts << css_class unless css_class.empty?
      box(css_class: parts.join(' ')) { text }
    end
  end
end
