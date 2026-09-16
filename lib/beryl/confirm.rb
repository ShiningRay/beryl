# frozen_string_literal: true

module Beryl
  class Confirm < Dialog
    prop :message, type: String, default: ''

    def view
      return super if message.empty?

      inner = content || -> { label { message } }
      Beryl::Dialog.new(title: title, content: inner,
                        on_confirm: on_confirm, on_cancel: on_cancel,
                        confirm_text: confirm_text, cancel_text: cancel_text,
                        width: width).view
    end
  end
end
