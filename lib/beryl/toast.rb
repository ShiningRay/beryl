# frozen_string_literal: true

module Beryl
  class Toast < Citrine::Component
    prop :data             # 旧契约，保留兼容
    prop :msg              # String，可空
    prop :kind             # String，可空
    prop :duration_ms      # Numeric，可空（nil = 不自动消失）
    prop :on_expire
    prop :action_label     # String，可空
    prop :on_action

    def view
      box(css_class: "b-toast #{toast_kind}",
          style: { z_index: 4200 },
          auto_dismiss: duration_ms, on_dismiss: on_expire,
          on_click: action_label ? ->(_e) { on_action&.call } : nil) do
        row(css_class: 'b-toast-row', gap: 10) do
          label { text }
          if action_label
            button(css_class: 'b-toast-action') { action_label }
          end
        end
      end
    end

    def text
      msg || (data && data['msg']) || ''
    end

    def toast_kind
      kind || (data && data['kind']) || 'info'
    end
  end
end
