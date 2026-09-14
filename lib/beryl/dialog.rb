# frozen_string_literal: true

module Beryl
  # L2 · 模态对话框：遮罩 + 标题栏 + 内容插槽 + 确认/取消页脚。
  # 消费者用自身 Signal 控制显隐（条件渲染）；Esc 关闭走 window 级键盘。
  class Dialog < Citrine::Component
    prop :title, type: String, default: ''
    prop :content          # Proc 插槽
    prop :on_confirm
    prop :on_cancel
    prop :confirm_text, type: String, default: '确定'
    prop :cancel_text, type: String, default: '取消'
    prop :width, type: Numeric, default: 420
    prop :dismiss_on_backdrop, default: true

    window_key :handle_escape

    def view
      box(css_class: 'b-dialog-overlay', on_click: ->(e) { backdrop(e) }) do
        stack(css_class: 'b-dialog', gap: 10,
              style: { width: "#{width}px" },
              on_click: ->(e) { e.stopPropagation }) do
          row(css_class: 'b-dialog-head') do
            label(css_class: 'b-dialog-title') { title }
            box(css_class: 'b-dialog-x', on_click: ->(_e) { on_cancel&.call }) { '✕' } if on_cancel
          end
          box(css_class: 'b-dialog-body') { content&.call }
          if on_confirm || on_cancel
            row(css_class: 'b-dialog-foot', gap: 8) do
              if on_cancel
                button(css_class: 'b-btn', on_click: ->(_e) { on_cancel.call }) { cancel_text }
              end
              if on_confirm
                button(css_class: 'b-btn b-btn-primary', on_click: ->(_e) { on_confirm.call }) { confirm_text }
              end
            end
          end
        end
      end
    end

    def handle_escape(ev)
      on_cancel&.call if ev.key == 'Escape'
    end

    def backdrop(_e)
      on_cancel&.call if dismiss_on_backdrop
    end
  end

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
