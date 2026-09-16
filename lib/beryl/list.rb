# frozen_string_literal: true

module Beryl
  # L2 · 列表 + 窗口化虚拟滚动。
  # 只渲染视口 ± overscan 的行（绝对定位在总高占位层上）；
  # scroll_top 信号必须在内容 block 内读取（G-2）——否则滚动容器
  # 会随整块重建，滚动位置丢失。SSR 渲染首屏窗口，快照稳定。
  class List < Citrine::Component
    prop :items
    prop :height, type: Numeric            # 视口高（px）
    prop :row_height, type: Numeric, default: 28
    prop :overscan, type: Numeric, default: 3
    prop :selected                         # Signal（元素身份或索引，可选）
    prop :on_select
    prop :item                             # ->(item, index) 插槽；缺省渲染 to_s

    state :scroll_top, default: 0

    def view
      box(css_class: 'b-list', direction: :column,
          style: { height: "#{height}px", overflow: :auto, position: 'relative' },
          on_scroll: ->(ev) { self.scroll_top = ev[:top] }) do
        # 内层：信号读在这里，重渲染只重建行、不动滚动容器
        box(css_class: 'b-list-inner', direction: :column,
            style: { height: "#{items.size * row_height}px", position: 'relative' }) do
          window_items.each do |it, i|
            on = selected && selected.get == it
            row(css_class: on ? 'b-list-row is-selected' : 'b-list-row',
                style: { position: 'absolute', top: "#{i * row_height}px",
                         left: '0', right: '0', height: "#{row_height}px" },
                on_click: on_select ? ->(_e) { on_select.call(it) } : nil) do
              if item
                item.call(it, i)
              else
                it.to_s
              end
            end
          end
        end
      end
    end

    # 公开给测试/调用方：当前窗口的 [item, index] 对
    def window_items
      first = [scroll_top / row_height - overscan, 0].max
      count = (height.to_f / row_height).ceil + 1 + overscan * 2
      items.each_with_index.select { |_it, i| i >= first && i < first + count }
    end
  end
end
