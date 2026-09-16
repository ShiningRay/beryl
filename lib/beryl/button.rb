# frozen_string_literal: true

module Beryl
  # L2 · 按钮：变体/尺寸/加载/禁用的统一契约（M7 前各件各自裸写
  # button+css_class，b-btn 语义散落在 Dialog/Pagination/Tabs 里，新代码一律走这里）。
  # text 与 content 插槽二选一；disabled/loading 接受明值或 Signal（Beryl.flag 归一）。
  class Button < Citrine::Component
    prop :text            # String，可空（prop 不得叫 label——会遮住 label 元素方法，F3）
    prop :content         # Proc 插槽（F2），可空
    prop :kind, default: :default   # :default | :primary | :danger | :ghost
    prop :size, default: :md        # :sm | :md | :lg
    prop :icon            # String 前置字形，可空
    prop :disabled        # bool | Signal，可空
    prop :loading         # bool | Signal，可空
    prop :block, default: false     # 撑满整行
    prop :css_class       # String | Proc：Proc 走响应式属性（激活态跟随信号重算 class）
    prop :style           # Hash，可空（内联样式逃生舱；与 block 的宽度约束合并）
    prop :key             # citrine keyed 复用的身份（透传给元素），可空
    prop :on_click

    def view
      opts = { css_class: full_classes, on_click: clickable? ? on_click : nil,
               style: full_style }
      opts[:disabled] = true if disabled?
      opts[:key] = key if key
      button(**opts) do
        if content
          glyphs
          content.call
        else
          "#{glyphs}#{text}"
        end
      end
    end

    # 前置字形：loading 占位（Icon 资产方案等 M5 定）+ icon prop
    # （Opal 不支持 String#<<，拼串一律走数组 join）
    def glyphs
      parts = []
      parts << '◌ ' if loading?
      parts << "#{icon} " if icon
      parts.join
    end

    def classes
      parts = ['b-btn']
      parts << "b-btn-#{kind}" unless kind == :default
      parts << "b-btn-#{size}" unless size == :md
      parts << 'is-loading' if loading?
      parts << 'b-btn-block' if block
      parts.join(' ')
    end

    def full_classes
      return css_class if css_class.is_a?(Proc)

      extra = css_class.to_s
      extra.empty? ? classes : "#{classes} #{extra}"
    end

    # block 的撑满宽度与消费者 style 合并（消费者键优先）；空则不挂 style
    def full_style
      s = {}
      s[:width] = '100%' if block
      s.merge!(style) if style
      s.empty? ? nil : s
    end

    def disabled?
      !!Beryl.flag(disabled)
    end

    def loading?
      !!Beryl.flag(loading)
    end

    # 禁用/加载中不挂 on_click（布尔 disabled 属性之外的双保险）
    def clickable?
      !(disabled? || loading?)
    end
  end

  # L2 · 按钮组：横向排列若干 Button 的间距容器（内容归消费者，F2 插槽）。
  class ButtonGroup < Citrine::Component
    prop :content         # Proc 插槽
    prop :gap, type: Numeric, default: 6

    def view
      row(css_class: 'b-btn-group', gap: gap) { content&.call }
    end
  end
end
