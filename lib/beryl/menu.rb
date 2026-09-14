# frozen_string_literal: true

module Beryl
  # L2 · 上下文菜单（右键/按钮弹出）。
  #
  # items 的数据契约（symbol / string 键均可）：
  #   { label:, action:, disabled:, checked:, shortcut:, submenu: [item...] }
  #   { separator: true }
  # 点任意处（含菜单项）关闭；sticky: true 时点菜单项不关（MultiSelect 用），
  # 只能靠捕获层点击 / Escape 关闭。
  #
  # 键盘：容器可聚焦（L1 tabindex+autofocus 原语），↑↓ 换高亮、Enter 执行、Esc 关闭；
  # SSR 只渲染结构，键盘行为全在浏览器侧。
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

  # L2 · 应用级菜单栏：横排顶层菜单，点击弹出 Menu。
  #   menus: [{ label:, items: [Menu items] }]
  # 开合索引受控（open_index Signal<[index, x, y]>）——MenuBar 在父块里
  # 每轮重建，内部 state 存不住开合（F4 推论）；不传则回退内部态。
  class MenuBar < Citrine::Component
    prop :menus
    prop :viewport
    prop :open_index       # Signal<{ index:, x:, y: } | nil> 可空

    state :internal, default: nil

    def view
      row(css_class: 'b-menubar', gap: 2) do
        menus.each_with_index do |m, i|
          on = opened?(i)
          button(css_class: on ? 'b-menubar-item is-open' : 'b-menubar-item',
                 on_click: ->(e) { toggle(i, e) }) { Beryl.pick(m, :label) }
        end
      end
      if (cur = current)
        m = menus[cur[:index]]
        Beryl::Menu.new(items: Beryl.pick(m, :items) || [],
                        x: cur[:x], y: cur[:y], viewport: viewport,
                        on_close: -> { set_open(nil) }).view
      end
    end

    def opened?(i)
      cur = current
      cur && cur[:index] == i
    end

    def current
      open_index ? open_index.get : internal
    end

    def set_open(v)
      open_index ? open_index.set(v) : (self.internal = v)
    end

    def toggle(index, event = nil)
      if opened?(index)
        set_open(nil)
        return
      end
      x = event ? event[:clientX] : 8
      y = event ? event[:clientY] + 6 : 30
      set_open({ index: index, x: x, y: y })
    end
  end
end
