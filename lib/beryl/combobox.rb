# frozen_string_literal: true

module Beryl
  # L2 · 自动完成：输入即过滤（Signal 驱动），候选列表 CSS 锚定，
  # Enter 取第一个、Esc 收起。开合受控（open Signal），理由同 Select。
  class Combobox < Citrine::Component
    prop :options          # [String]
    prop :value            # Signal<String>
    prop :placeholder, type: String, default: ''
    prop :open             # Signal<bool> 受控开合，可空
    prop :on_pick

    state :internal_open, default: false

    def view
      text_input(value: value, placeholder: placeholder,
                 css_class: 'b-combobox',
                 on_focus: ->(_e) { set_open(true) },
                 on_key: {
                   'Escape' => ->(_ev) { set_open(false) },
                   'Enter' => :pick_first,
                 })
      return unless open?

      q = value.get.to_s
      hits = q == '' ? options : options.select { |o| o.to_s.include?(q) }
      return if hits.empty?

      box(css_class: 'b-combobox-list', direction: :column,
          style: { position: 'absolute', z_index: Beryl.next_z }) do
        hits.first(8).each do |o|
          box(css_class: 'menu-item b-menu-item', on_click: :pick) { o.to_s }
        end
      end
    end

    def open?
      open ? open.get : internal_open
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end

    def pick_first
      q = value.get.to_s
      hits = options.select { |o| o.to_s.include?(q) }
      return if hits.empty?

      value.set(hits.first.to_s)
      set_open(false)
      on_pick&.call(hits.first)
    end

    def pick; pick_first; end
  end
end
