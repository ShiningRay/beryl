# frozen_string_literal: true

module Beryl
  # L2 · 对话框三件套：提示 / 确认 / 输入
  class Alert < Dialog
    prop :message, type: String, default: ''

    def view
      return super if message.empty?

      inner = content || -> { label { message } }
      Beryl::Dialog.new(title: title, content: inner,
                        on_confirm: on_confirm, confirm_text: confirm_text,
                        width: width).view
    end
  end
end
