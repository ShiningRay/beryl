# frozen_string_literal: true

module Beryl
  class Table < Citrine::Component
    prop :columns
    prop :rows
    prop :row_key, default: nil          # ->(row, index) 或 Symbol/nil（index 兜底）
    prop :selected                       # Signal 可选
    prop :on_row_click
    prop :sort                           # Signal<{key:, dir:}> 可空
    prop :on_sort                        # ->(next_sort) 可空
    prop :height                         # Numeric px，可空（可空 prop 不带 type，F3）
    prop :css_class, type: String, default: ''

    def view
      opts = { css_class: "b-table #{css_class}".strip }
      opts[:style] = { height: "#{height}px", overflow: :auto } if height
      stack(**opts) do
        row(css_class: 'b-table-head', gap: 0) do
          columns.each { |c| head_cell(c) }
        end
        display_rows.each_with_index do |r, i|
          row(css_class: row_class(r, i),
              on_click: on_row_click ? ->(_e) { on_row_click.call(r) } : nil) do
            columns.each do |c|
              box(css_class: 'b-table-td', style: cell_style(c)) { cell_text(r, c) }
            end
          end
        end
      end
    end

    # 可排序表头：整格可点，标签后随排序方向箭头（仅活动列）
    def head_cell(c)
      text = Beryl.pick(c, :label).to_s
      if sortable?(c)
        row(css_class: sorted?(c) ? 'b-table-th is-sortable is-sorted' : 'b-table-th is-sortable',
            style: cell_style(c), on_click: ->(_e) { toggle_sort(c) }) do
          "#{text}#{sort_arrow(c)}"
        end
      else
        box(css_class: 'b-table-th', style: cell_style(c)) { text }
      end
    end

    def sortable?(c)
      sort && Beryl.pick(c, :sortable)
    end

    def sorted?(c)
      s = sort && sort.get
      !!s && Beryl.pick(s, :key) == Beryl.pick(c, :key)
    end

    def sort_arrow(c)
      return '' unless sorted?(c)

      Beryl.pick(sort.get, :dir) == :desc ? ' ↓' : ' ↑'
    end

    def toggle_sort(c)
      key = Beryl.pick(c, :key)
      s = sort.get
      dir = s && Beryl.pick(s, :key) == key && Beryl.pick(s, :dir) == :asc ? :desc : :asc
      next_sort = { key: key, dir: dir }
      on_sort ? on_sort.call(next_sort) : sort.set(next_sort)
    end

    # 展示行：受控排序就位且未接管（无 on_sort）时就地排
    # （列声明 sort_by: 用其结果比较，否则按单元格文本）
    def display_rows
      return rows unless sort && sort.get && !on_sort

      s = sort.get
      col = columns.find { |c| Beryl.pick(c, :key) == Beryl.pick(s, :key) }
      by = col && Beryl.pick(col, :sort_by)
      sorted = by ? rows.sort_by { |r| by.call(r) }
                  : rows.sort_by { |r| cell_value(r, Beryl.pick(s, :key)) }
      Beryl.pick(s, :dir) == :desc ? sorted.reverse : sorted
    end

    def cell_value(row, key)
      v = Beryl.pick(row, key)
      v.nil? ? '' : v.to_s
    end

    def cell_text(row, col)
      cell_value(row, Beryl.pick(col, :key))
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
end
