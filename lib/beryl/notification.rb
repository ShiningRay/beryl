# frozen_string_literal: true

module Beryl
  # L2 · 通知（M7）：标题 + 正文 + 关闭钮 + 可选动作；duration_ms 走 L1
  # auto_dismiss（on_expire 收尾）。style prop 供消费者做角落堆叠定位
  # （固定 right/top 归消费者——同 Toast 的堆叠哲学，组件只管单条）。
  class Notification < Citrine::Component
    prop :title            # String
    prop :msg              # String，可空
    prop :kind             # String 'info'|'success'|'error'|'warn'，可空
    prop :duration_ms      # Numeric，可空（nil = 不自动消失）
    prop :on_expire
    prop :on_close
    prop :action_label     # String，可空
    prop :on_action
    prop :style            # Hash，可空（堆叠定位；z_index 有缺省）

    def view
      stack(css_class: "b-notification #{kind}".strip,
            style: { z_index: 4300 }.merge!(style || {}),
            auto_dismiss: duration_ms, on_dismiss: on_expire) do
        row(css_class: 'b-notification-head', gap: 8) do
          label { title.to_s }
          if on_close
            box(css_class: 'b-notification-x', on_click: ->(_e) { on_close.call }) { '✕' }
          end
        end
        box(css_class: 'b-notification-msg') { msg.to_s } if msg
        if action_label
          button(css_class: 'b-notification-action', on_click: ->(_e) { on_action&.call }) do
            action_label
          end
        end
      end
    end
  end
end
