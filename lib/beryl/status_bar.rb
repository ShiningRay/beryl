# frozen_string_literal: true

module Beryl
  class StatusBar < Citrine::Component
    prop :left             # Proc 插槽
    prop :right            # Proc 插槽

    def view
      row(css_class: 'b-statusbar', gap: 12) do
        box(css_class: 'b-statusbar-side') { left&.call }
        box(css_class: 'b-statusbar-spring', style: { flex: 1 })
        box(css_class: 'b-statusbar-side') { right&.call }
      end
    end
  end
end
