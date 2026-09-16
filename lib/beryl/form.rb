# frozen_string_literal: true

module Beryl
  # L2 · 表单容器（M7）：Field 纵向排列 + 提交区。
  # footer 插槽可覆盖缺省的主按钮；on_submit 挂在主按钮的 on_click 上。
  # 注意 `form` 是 citrine 元素词表（ELEMENT_TAGS）——本类用 stack 语义足够。
  class Form < Citrine::Component
    prop :content          # Proc 插槽：Field 列表
    prop :submit_text, type: String, default: '提交'
    prop :on_submit
    prop :footer           # Proc 插槽，可空

    def view
      stack(css_class: 'b-form', gap: 12) do
        content.call if content
        stack(css_class: 'b-form-foot', gap: 6) do
          if footer
            footer.call
          else
            Button.new(text: submit_text, kind: :primary, on_click: on_submit).view
          end
        end
      end
    end
  end
end
