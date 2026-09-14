# frozen_string_literal: true

module Beryl
  # L2 · 表格：列定义 + 行哈希。行数据兼容 symbol/string 键。
  #   columns: [{ key:, label:, width?:, align?: }]
  #   selected: Signal（与 row_key 对齐的选中标识，可选）
  class Table < Citrine::Component
    prop :columns
    prop :rows
    prop :row_key, default: nil          # ->(row, index) 或 Symbol/nil（index 兜底）
    prop :selected                       # Signal 可选
    prop :on_row_click
    prop :css_class, type: String, default: ''

    def view
      stack(css_class: "b-table #{css_class}".strip) do
        row(css_class: 'b-table-head', gap: 0) do
          columns.each { |c| box(css_class: 'b-table-th', style: cell_style(c)) { Beryl.pick(c, :label).to_s } }
        end
        rows.each_with_index do |r, i|
          row(css_class: row_class(r, i),
              on_click: on_row_click ? ->(_e) { on_row_click.call(r) } : nil) do
            columns.each do |c|
              box(css_class: 'b-table-td', style: cell_style(c)) { cell_text(r, c) }
            end
          end
        end
      end
    end

    def cell_text(row, col)
      v = Beryl.pick(row, Beryl.pick(col, :key))
      v.nil? ? '' : v.to_s
    end

    def row_class(r, i)
      cls = i.even? ? 'b-table-row is-even' : 'b-table-row'
      cls += ' is-selected' if selected && selected.get == row_id(r, i)
      cls
    end

    def row_id(r, i)
      key = row_key
      return i if key.nil?
      return key.call(r, i) if key.is_a?(Proc)

      Beryl.pick(r, key) || i
    end

    private

    def cell_style(col)
      s = {}
      s[:width] = "#{Beryl.pick(col, :width)}px" if Beryl.pick(col, :width)
      s[:text_align] = Beryl.pick(col, :align).to_s if Beryl.pick(col, :align)
      s
    end
  end

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

  # L2 · 树。expanded 传 Signal<Array>(节点 id) 为受控；
  # 不传则内部维护展开集（内部 UI 态）。nodes: [{ id:, label:, children?: [...] }]
  class Tree < Citrine::Component
    prop :nodes
    prop :expanded         # Signal<Array> 可选
    prop :selected         # Signal 可选（节点 id）
    prop :on_select
    prop :on_toggle        # ->(node) 受控时的展开/收起回调

    state :internal_open, default: []

    def view
      stack(css_class: 'b-tree', gap: 0) do
        render_nodes(nodes, 0)
      end
    end

    def render_nodes(list, depth)
      list.each do |n|
        children = Beryl.pick(n, :children) || []
        id = Beryl.pick(n, :id)
        open = expanded?(id)
        row(css_class: row_class(id),
            style: { padding_left: "#{depth * 16 + 4}px" },
            on_click: ->(_e) { select(n) }) do
          if children.any?
            box(css_class: 'b-tree-caret', on_click: ->(_e) { toggle(n) }) { open ? '▾' : '▸' }
          else
            box(css_class: 'b-tree-caret b-tree-leaf-dot')
          end
          label { Beryl.pick(n, :label).to_s }
        end
        render_nodes(children, depth + 1) if open
      end
    end

    def expanded?(id)
      if expanded
        (expanded.get || []).include?(id)
      else
        internal_open.include?(id)
      end
    end

    def toggle(n)
      id = Beryl.pick(n, :id)
      if expanded || on_toggle
        on_toggle&.call(n)
      else
        cur = internal_open.include?(id) ? internal_open - [id] : internal_open + [id]
        self.internal_open = cur
      end
    end

    def select(n)
      on_select&.call(n)
    end

    def row_class(id)
      cls = 'b-tree-row'
      cls += ' is-selected' if selected && selected.get == id
      cls
    end
  end

  # L2 · 键值列表。pairs: 哈希或 [[k, v]]
  class KV < Citrine::Component
    prop :pairs
    prop :label_width, type: Numeric, default: 96

    def view
      stack(css_class: 'b-kv', gap: 2) do
        normalized.each do |k, v|
          row(css_class: 'b-kv-row', gap: 8) do
            box(css_class: 'b-kv-key', style: { width: "#{label_width}px" }) { k.to_s }
            box(css_class: 'b-kv-val') { v.nil? ? '' : v.to_s }
          end
        end
      end
    end

    def normalized
      pairs.is_a?(Hash) ? pairs.to_a : pairs
    end
  end

  # L2 · 面包屑。items: [{ label:, on_click?: }]
  class Breadcrumb < Citrine::Component
    prop :items

    def view
      row(css_class: 'b-breadcrumb', gap: 6) do
        items.each_with_index do |it, i|
          box(css_class: 'b-crumb-sep') { '›' } if i.positive?
          if Beryl.pick(it, :on_click)
            box(css_class: 'b-crumb is-link', on_click: ->(_e) { Beryl.pick(it, :on_click).call }) do
              Beryl.pick(it, :label).to_s
            end
          else
            box(css_class: 'b-crumb') { Beryl.pick(it, :label).to_s }
          end
        end
      end
    end
  end

  # L2 · 分页（受控）。page 是 Signal（1 起）。
  # 页数 ≤ 9 全展示，否则滑窗（首页/末页常驻，其余 … 折叠）。
  class Pagination < Citrine::Component
    prop :page             # Signal<Numeric>
    prop :total, type: Numeric
    prop :per_page, type: Numeric, default: 20
    prop :on_change

    def view
      row(css_class: 'b-pagination', gap: 4) do
        button(css_class: 'b-page-btn', on_click: :prev) { '‹' }
        visible_pages.each do |p|
          if p == :ellipsis
            box(css_class: 'b-page-ellipsis') { '…' }
          else
            button(css_class: p == page.get ? 'b-page-btn is-active' : 'b-page-btn',
                   on_click: ->(_e) { go(p) }) { p.to_s }
          end
        end
        button(css_class: 'b-page-btn', on_click: :next) { '›' }
      end
    end

    def pages
      n = (total.to_f / per_page).ceil
      n < 1 ? 1 : n
    end

    def visible_pages
      n = pages
      cur = page.get
      return (1..n).to_a if n <= 9

      out = [1]
      lo = cur - 1 < 2 ? 2 : cur - 1
      hi = cur + 1 > n - 1 ? n - 1 : cur + 1
      out << :ellipsis if lo > 2
      (lo..hi).each { |p| out << p }
      out << :ellipsis if hi < n - 1
      out << n
      out
    end

    def go(p)
      p = 1 if p < 1
      p = pages if p > pages
      on_change ? on_change.call(p) : page.set(p)
    end

    def prev; go(page.get - 1); end
    def next; go(page.get + 1); end
  end

  # L2 · 工具栏 / 状态栏：插槽容器（内容归消费者）
  class Toolbar < Citrine::Component
    prop :content          # Proc 插槽
    prop :css_class, type: String, default: ''

    def view
      row(css_class: "b-toolbar #{css_class}".strip, gap: 6) { content&.call }
    end
  end

  class StatusBar < Citrine::Component
    prop :left             # Proc 插槽
    prop :right            # Proc 插槽

    def view
      row(css_class: 'b-statusbar', gap: 12) do
        box(css_class: 'b-statusbar-side') { left&.call }
        box(css_class: 'b-statusbar-spring', style: { flex: 1 })
        box(css_class: 'b-statusbar-side') { right&.call }
      end
    end
  end

  # 最小图标集：unicode 字形映射（资产嵌入方案等 M5 主题系统再定）
  module Icon
    GLYPHS = {
      close: '✕', plus: '+', minus: '−', check: '✓',
      caret_right: '▸', caret_down: '▾', chevron_left: '‹', chevron_right: '›',
      search: '🔍', folder: '▤', file: '▢', gear: '⚙', star: '★', dot: '•',
    }.freeze

    def self.[](name)
      GLYPHS[name] || name.to_s
    end
  end
end
