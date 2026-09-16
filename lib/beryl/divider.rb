# frozen_string_literal: true

module Beryl
  # L2 · 分隔线（M7）：水平嵌字 / 竖直细线。竖直形态忽略 text（嵌字竖线无此需求）。
  class Divider < Citrine::Component
    prop :text             # String，可空（嵌字分隔线）
    prop :orientation, default: :horizontal  # :horizontal | :vertical
    prop :css_class, type: String, default: ''

    def view
      if orientation == :vertical
        box(css_class: classes) { seg }
      elsif text
        row(css_class: classes, gap: 8, style: { align_items: 'center' }) do
          seg
          label { text }
          seg
        end
      else
        row(css_class: classes, gap: 0) { seg }
      end
    end

    def seg
      box(css_class: 'b-divider-line')
    end

    def classes
      parts = ['b-divider']
      parts << 'is-vertical' if orientation == :vertical
      parts << css_class unless css_class.empty?
      parts.join(' ')
    end
  end
end
