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

    def view
      cls = kind ? "b-badge b-badge-#{kind}" : 'b-badge'
      box(css_class: cls) { text }
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
