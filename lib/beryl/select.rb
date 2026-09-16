# frozen_string_literal: true

module Beryl
  class Select < Citrine::Component
    prop :options
    prop :value            # Signal
    prop :on_change
    prop :open             # Signal<bool> 受控开合，可空
    prop :placeholder, type: String, default: '请选择'
    prop :viewport         # 兼容旧签名；CSS 锚定后不再需要

    state :internal_open, default: false

    def view
      box(css_class: 'b-select-wrap', style: { position: 'relative' }) do
        current = options.find { |o| Beryl.option_value(o) == value.get }
        button(css_class: open? ? 'b-select is-open' : 'b-select',
               on_click: :toggle) do
          current ? "#{Beryl.option_label(current)} ▾" : "#{placeholder} ▾"
        end
        option_list if open?
      end
    end

    def option_list
      box(css_class: 'b-select-list', direction: :column,
          style: { position: 'absolute', top: '100%', left: '0',
                   z_index: Beryl.next_z, min_width: '160px' }) do
        options.each do |o|
          checked = Beryl.option_value(o) == value.get
          box(css_class: checked ? 'menu-item is-checked' : 'menu-item',
              on_click: ->(_e) { on_change&.call(Beryl.option_value(o)); set_open(false) }) do
            "#{checked ? '✓ ' : ''}#{Beryl.option_label(o)}"
          end
        end
      end
    end

    def open?
      open ? open.get : internal_open
    end

    def toggle
      set_open(!open?)
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end
  end
end
