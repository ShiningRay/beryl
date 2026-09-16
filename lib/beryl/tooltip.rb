# frozen_string_literal: true

module Beryl
  # L2 · 文字提示（受控，M7）。open 传 Signal 受控显隐；on_hover 透传到锚容器，
  # 消费者一行完成布线（F4：交互态必须受控；不传 open 回退内部态，仅自根挂载可用）。
  # CSS 锚定四向 placement（.b-tooltip.is-*），不走坐标定位——提示跟随锚内容即可。
  class Tooltip < Citrine::Component
    prop :text             # String 提示文案
    prop :anchor           # String，可空：纯文本锚（content 插槽缺省时用）
    prop :content          # Proc 插槽：锚内容（发射节点，F2）
    prop :open             # Signal<bool> 受控显隐，可空
    prop :placement, default: :top   # :top | :bottom | :left | :right
    prop :on_hover         # ->(hovering) L1 原语透传，可空

    state :internal_open, default: false

    def view
      opts = { css_class: 'b-tooltip-wrap',
               style: { position: 'relative', display: 'inline-block' } }
      opts[:on_hover] = ->(hovering) { set_open(hovering) } if on_hover
      box(**opts) do
        if content
          content.call
        else
          label { anchor.to_s }
        end
        bubble if open?
      end
    end

    def bubble
      box(css_class: "b-tooltip is-#{placement}") { text.to_s }
    end

    def open?
      open ? open.get : internal_open
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end
  end
end
