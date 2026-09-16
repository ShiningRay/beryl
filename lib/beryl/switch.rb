# frozen_string_literal: true

module Beryl
  # L2 · 开关（受控）
  class Switch < Citrine::Component
    prop :value            # Signal（truthy = 开）
    prop :on_change

    def view
      box(css_class: value.get ? 'b-switch is-on' : 'b-switch',
          on_click: :toggle) do
        box(css_class: 'b-switch-thumb')
      end
    end

    def toggle
      on_change&.call(!value.get)
    end
  end
end
