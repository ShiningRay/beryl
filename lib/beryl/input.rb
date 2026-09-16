# frozen_string_literal: true

module Beryl
  # L2 · 通用单行输入（受控，M7）。value 是 Signal（每键更新）；
  # 前后缀字形、清空钮、错误态、禁用。disabled/error 接受明值或 Signal（Beryl.flag）。
  # SearchInput/NumberInput 是它的场景化近亲（保留，暂不迁移）。
  class Input < Citrine::Component
    prop :value            # Signal<String>
    prop :placeholder, type: String, default: ''
    prop :prefix           # String 前缀字形，可空
    prop :suffix           # String 后缀字形，可空
    prop :clearable, default: false  # 有值时显示 ✕
    prop :disabled         # bool | Signal，可空
    prop :error            # bool | Signal，可空 → is-error
    prop :width            # Numeric px，可空（可空 prop 不带 type，F3）
    prop :on_enter

    def view
      row(css_class: wrap_class, gap: 6, style: wrap_style) do
        box(css_class: 'b-input-glyph') { prefix } if prefix
        ti = { value: value, placeholder: placeholder, on_enter: on_enter,
               css_class: 'b-input-inner' }
        ti[:disabled] = true if disabled?
        text_input(**ti)
        if clearable && value.get.to_s != ''
          box(css_class: 'b-input-clear', on_click: ->(_e) { value.set('') }) { '✕' }
        end
        box(css_class: 'b-input-glyph') { suffix } if suffix
      end
    end

    def wrap_class
      parts = ['b-input']
      parts << 'is-error' if Beryl.flag(error)
      parts << 'is-disabled' if disabled?
      parts.join(' ')
    end

    def wrap_style
      width ? { width: "#{width}px" } : nil
    end

    def disabled?
      !!Beryl.flag(disabled)
    end
  end
end
