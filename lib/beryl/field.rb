# frozen_string_literal: true

module Beryl
  # L2 · 表单字段组装层（M7）：标题/必填标记/错误/提示 + 控件插槽。
  # 校验规则框架延后：error 文本由消费者（Store/表单逻辑）算好传入，
  # Field 只负责布局与错误态呈现。
  class Field < Citrine::Component
    prop :title            # String，可空
    prop :required, default: false
    prop :error            # String，可空（有值即错误态）
    prop :hint             # String，可空
    prop :content          # Proc 插槽（F2）：控件

    def view
      stack(css_class: error ? 'b-field has-error' : 'b-field', gap: 4) do
        if title
          row(css_class: 'b-field-title', gap: 4) do
            label { title.to_s }
            box(css_class: 'b-field-req') { '*' } if required
          end
        end
        content.call if content
        box(css_class: 'b-field-error') { error } if error
        box(css_class: 'b-field-hint') { hint } if hint
      end
    end
  end
end
