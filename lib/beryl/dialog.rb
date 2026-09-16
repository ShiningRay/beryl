# frozen_string_literal: true

module Beryl
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
              on_click: ->(e) { e.stop_propagation }) do
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
end
