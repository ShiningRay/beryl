# frozen_string_literal: true

module Beryl
  # L2 · 复选框（受控，M7）。value Signal truthy = 勾选；独立于 Switch 的
  # 二元勾选件（表单语义：勾选 ≠ 开关）。disabled 接受明值或 Signal。
  class Checkbox < Citrine::Component
    prop :value            # Signal（truthy = 勾选）
    prop :text             # String，可空
    prop :on_change
    prop :disabled         # bool | Signal，可空

    def view
      row(css_class: cb_class, gap: 6, on_click: enabled? ? :toggle : nil) do
        box(css_class: 'b-checkbox-box') { '✓' if value.get }
        label { text.to_s } if text
      end
    end

    def cb_class
      parts = ['b-checkbox']
      parts << 'is-checked' if value.get
      parts << 'is-disabled' if disabled?
      parts.join(' ')
    end

    def toggle
      on_change&.call(!value.get)
    end

    def disabled?
      !!Beryl.flag(disabled)
    end

    def enabled?
      !disabled?
    end
  end
end
