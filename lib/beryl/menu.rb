# frozen_string_literal: true

module Beryl
  class Menu < Citrine::Component
    prop :items
    prop :x, type: Numeric
    prop :y, type: Numeric
    prop :viewport          # { w:, h: } 可选；传了才做视口防溢出
    prop :on_close
    prop :sticky, default: false

    state :active, default: nil

    def view
      px, py = clamped
      box(css_class: 'menu-overlay', on_click: ->(_e) { on_close.call },
          on_menu: ->(ev) { ev.preventDefault; on_close.call })
      box(css_class: 'ctx-menu', direction: :column,
          style: { left: "#{px}px", top: "#{py}px" },
          tabindex: 0, autofocus: true,
          on_key: {
            'ArrowDown' => :next_item, 'ArrowUp' => :prev_item,
            'Enter' => :choose_active, ' ' => :choose_active,
            'Escape' => ->(_ev) { on_close&.call },
          }) do
        render_items(items)
      end
    end

    # ── 键盘导航（on_key 的 Symbol 目标，公开以便单测）──────────

    def nav_indices
      @nav ||= items.each_with_index
                    .select { |item, _i| !separator?(item) && !disabled?(item) }
                    .map { |_item, i| i }
    end

    def next_item
      list = nav_indices
      return if list.empty?

      cur = list.index(active)
      self.active = cur.nil? ? list.first : list[(cur + 1) % list.size]
    end

    def prev_item
      list = nav_indices
      return if list.empty?

      cur = list.index(active)
      self.active = cur.nil? ? list.last : list[(cur - 1) % list.size]
    end

    def choose_active
      return if active.nil?

      item = items[active]
      return if item.nil? || separator?(item) || disabled?(item)

      activate(item)
    end

    private

    def render_items(list)
      list.each_with_index do |item, i|
        if separator?(item)
          box(css_class: 'menu-sep b-menu-sep')
          next
        end
        label_text = "#{Beryl.pick(item, :checked) ? '✓ ' : ''}#{Beryl.pick(item, :label)}"
        shortcut = Beryl.pick(item, :shortcut)
        item_box(css_class: item_class(item, i),
                 on_click: disabled?(item) ? nil : ->(_e) { activate(item) },
                 on_hover: disabled?(item) ? nil : ->(entered) { self.active = i if entered }) do
          row(gap: 8) do
            label { label_text }
            if shortcut
              box(css_class: 'b-menu-shortcut') { shortcut }
            elsif Beryl.pick(item, :submenu)
              box(css_class: 'b-menu-shortcut') { '▸' }
            end
          end
          subs = Beryl.pick(item, :submenu)
          render_items(subs) if subs && !disabled?(item)
        end
      end
    end

    def item_box(css_class:, on_click:, on_hover:, &blk)
      props = { css_class: css_class, direction: :column }
      props[:on_click] = on_click if on_click
      props[:on_hover] = on_hover if on_hover
      box(**props, &blk)
    end

    def item_class(item, i)
      cls = 'menu-item b-menu-item'
      cls += ' is-active' if active == i
      cls += ' is-disabled' if disabled?(item)
      cls += ' has-submenu' if Beryl.pick(item, :submenu)
      cls
    end

    def activate(item)
      action = Beryl.pick(item, :action)
      on_close.call unless sticky
      action&.call
    end

    def separator?(item)
      Beryl.pick(item, :separator) ? true : false
    end

    def disabled?(item)
      Beryl.pick(item, :disabled) ? true : false
    end

    # 视口防溢出：菜单估算尺寸（宽 170，每项 30px）走 Overlay 统一算法
    def clamped
      return [x, y] unless viewport

      est_h = items.size * 30 + 8
      pos = Overlay.position(
        anchor: { x: x, y: y, w: 0, h: 0 },
        size: { w: 170, h: est_h }, viewport: viewport, placement: :bottom,
      )
      [pos[:x], pos[:y]]
    end
  end
end
