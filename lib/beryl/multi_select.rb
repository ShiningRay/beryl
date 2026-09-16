# frozen_string_literal: true

module Beryl
  # L2 · 多选：chips + CSS 锚定的常驻列表（选中打勾，点选不关闭）。
  # 开合受控（open Signal），理由同 Select。
  class MultiSelect < Citrine::Component
    prop :options
    prop :value            # Signal<Array>
    prop :on_change
    prop :open             # Signal<bool> 受控开合，可空
    prop :placeholder, type: String, default: '请选择'
    prop :viewport         # 兼容旧签名

    state :internal_open, default: false

    def view
      box(css_class: 'b-multiselect-wrap', style: { position: 'relative' }) do
        row(css_class: 'b-multiselect', gap: 4) do
          selected.each do |v|
            opt = options.find { |o| Beryl.option_value(o) == v }
            box(css_class: 'b-chip') do
              label { Beryl.option_label(opt).to_s }
              box(css_class: 'b-chip-x', on_click: ->(_e) { toggle(v) }) { '✕' }
            end
          end
          button(css_class: 'b-select b-ms-add', on_click: :toggle) { open? ? '收起 ▴' : '+ 添加' }
        end
        option_list if open?
      end
    end

    def option_list
      box(css_class: 'b-select-list', direction: :column,
          style: { position: 'absolute', top: '100%', left: '0',
                   z_index: Beryl.next_z, min_width: '160px' }) do
        options.each do |o|
          checked = selected.include?(Beryl.option_value(o))
          box(css_class: checked ? 'menu-item is-checked' : 'menu-item',
              on_click: ->(_e) { toggle(Beryl.option_value(o)) }) do
            "#{checked ? '✓ ' : ''}#{Beryl.option_label(o)}"
          end
        end
      end
    end

    def selected
      value.get || []
    end

    def open?
      open ? open.get : internal_open
    end

    def toggle_open
      set_open(!open?)
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end

    def toggle(v)
      selected = self.selected.dup
      selected.include?(v) ? selected.delete(v) : selected << v
      on_change&.call(selected)
    end
  end
end
