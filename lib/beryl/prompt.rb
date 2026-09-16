# frozen_string_literal: true

module Beryl
  # Prompt 的 input 是 Signal（受控）；确认时把当前值交给 on_confirm
  class Prompt < Dialog
    prop :message, type: String, default: ''
    prop :input            # Signal<String>

    def view
      return super if message.empty?

      inner = content || lambda {
        stack(gap: 8) do
          label { message }
          text_input(value: input, css_class: 'b-prompt-input')
        end
      }
      Beryl::Dialog.new(title: title, content: inner,
                        on_confirm: -> { on_confirm&.call(input.get) },
                        on_cancel: on_cancel,
                        confirm_text: confirm_text, cancel_text: cancel_text,
                        width: width).view
    end
  end
end
