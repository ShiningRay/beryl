# frozen_string_literal: true

module Beryl
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
      # 位置读原生坐标必须经 Event#raw（Citrine::Event 无 [] 访问器——
      # E7 emerald 浏览器验收发现的 bug，2026-09-15 修复）
      x = event ? event.raw[:clientX] : 8
      y = event ? event.raw[:clientY] + 6 : 30
      set_open({ index: index, x: x, y: y })
    end
  end
end
