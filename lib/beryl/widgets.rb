# frozen_string_literal: true

module Beryl
  # L2 · 右键/按钮弹出的上下文菜单。
  # items: [{ 'label' => String, 'action' => Proc }]；点任意处（含菜单项）关闭。
  class Menu < Citrine::Component
    prop :items
    prop :x, type: Numeric
    prop :y, type: Numeric
    prop :on_close

    def view
      box(css_class: 'menu-overlay', on_click: ->(_e) { on_close.call },
          on_menu: ->(ev) { ev.preventDefault; on_close.call })
      box(css_class: 'ctx-menu', direction: :column,
          style: { left: "#{x}px", top: "#{y}px" }) do
        items.each do |item|
          box(css_class: 'menu-item', on_click: ->(_e) { on_close.call; item['action']&.call }) do
            item['label']
          end
        end
      end
    end
  end

  # L2 · 轻提示。data: { 'msg' => String, 'kind' => 'info'|'error' }
  class Toast < Citrine::Component
    prop :data

    def view
      box(css_class: "b-toast #{data['kind']}") { data['msg'] }
    end
  end
end
