# frozen_string_literal: true

module Beryl
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
end
