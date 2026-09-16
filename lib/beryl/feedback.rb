# frozen_string_literal: true

module Beryl
  # L2 · 轻提示。
  #   旧契约：data: { 'msg' =>, 'kind' => 'info'|'error' }
  #   新契约：msg: / kind: / duration_ms + on_expire（自动消失，L1 auto_dismiss 原语）
  #           action_label + on_action（右侧动作按钮）
  # 堆叠 = 消费者在 view 里 map 渲染多条（列布局即可）。
  class Toast < Citrine::Component
    prop :data             # 旧契约，保留兼容
    prop :msg              # String，可空
    prop :kind             # String，可空
    prop :duration_ms      # Numeric，可空（nil = 不自动消失）
    prop :on_expire
    prop :action_label     # String，可空
    prop :on_action

    def view
      box(css_class: "b-toast #{toast_kind}",
          style: { z_index: 4200 },
          auto_dismiss: duration_ms, on_dismiss: on_expire,
          on_click: action_label ? ->(_e) { on_action&.call } : nil) do
        row(css_class: 'b-toast-row', gap: 10) do
          label { text }
          if action_label
            button(css_class: 'b-toast-action') { action_label }
          end
        end
      end
    end

    def text
      msg || (data && data['msg']) || ''
    end

    def toast_kind
      kind || (data && data['kind']) || 'info'
    end
  end

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

  # L2 · 进度条：value 可传数值或 Signal；indeterminate 走 CSS 动画
  class Progress < Citrine::Component
    prop :value            # Numeric | Signal<Numeric>
    prop :indeterminate, default: false
    prop :height, type: Numeric, default: 6

    def view
      box(css_class: indeterminate ? 'b-progress is-indeterminate' : 'b-progress',
          style: { height: "#{height}px" }) do
        box(css_class: 'b-progress-fill', style: { width: "#{pct}%" })
      end
    end

    def pct
      return 0 if indeterminate

      v = value.respond_to?(:get) ? value.get : value
      v = (v || 0).to_f
      v = 100 if v > 100
      v = 0 if v.negative?
      v.round(2)
    end
  end

  # L2 · 加载指示（纯 CSS 旋转）。prop 叫 text 不叫 label——prop 定义的
  # 同名方法会遮住 view 里的 label 元素 DSL
  class Spinner < Citrine::Component
    prop :size, type: Numeric, default: 16
    prop :text             # String，可空

    def view
      row(css_class: 'b-spinner-row', gap: 8) do
        box(css_class: 'b-spinner', style: { width: "#{size}px", height: "#{size}px" })
        label { text } if text
      end
    end
  end

  # L2 · 徽标：kind 可为 info/success/warn/error 或 nil（中性）。
  # prop 叫 text 不叫 label——远端 citrine 的 prop 宏已禁止与元素 DSL 同名
  class Badge < Citrine::Component
    prop :text, type: String
    prop :kind             # String，可空
    prop :css_class, type: String, default: ''  # 追加类（消费者自有配色，如 market 的 badge-hold）

    def view
      parts = ['b-badge']
      parts << "b-badge-#{kind}" if kind
      parts << css_class unless css_class.empty?
      box(css_class: parts.join(' ')) { text }
    end
  end

  # L2 · 标签（M7）：Badge 的近亲——可关闭、可点选（checkable 受控，
  # checked 传 Signal，F4）。kind 色板同 Badge。
  class Tag < Citrine::Component
    prop :text, type: String
    prop :kind             # String，可空（info/success/warn/error）
    prop :closable, default: false
    prop :on_close
    prop :checkable, default: false
    prop :checked          # Signal<bool>，checkable 时必传（受控）
    prop :on_toggle        # ->(next_checked)

    def view
      if closable
        box(css_class: classes, on_click: clickable? ? :toggle : nil) do
          row(css_class: 'b-tag-inner', gap: 4, style: { align_items: 'center' }) do
            label { text.to_s }
            box(css_class: 'b-tag-x', on_click: ->(_e) { on_close&.call }) { '✕' }
          end
        end
      else
        box(css_class: classes, on_click: clickable? ? :toggle : nil) { text.to_s }
      end
    end

    def classes
      parts = ['b-tag']
      parts << "b-tag-#{kind}" if kind
      parts << 'is-checkable' if checkable
      parts << 'is-checked' if checkable && checked && checked.get
      parts.join(' ')
    end

    def toggle
      on_toggle&.call(!checked.get) if checked
    end

    def clickable?
      checkable && checked
    end
  end

  # L2 · 空状态：图标 + 文案 + 动作插槽
  class EmptyState < Citrine::Component
    prop :message, type: String, default: ''
    prop :icon, type: String, default: '∅'
    prop :action           # Proc 插槽（如 -> { button(...) { '新建' } }）

    def view
      stack(css_class: 'b-empty', gap: 8) do
        box(css_class: 'b-empty-icon') { icon }
        label { message }
        action&.call
      end
    end
  end
end
