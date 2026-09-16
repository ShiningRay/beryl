# frozen_string_literal: true

module Beryl
  # L2 · 搜索输入：🔍 前缀 + 可清空。value 是 Signal（每键更新，视图自动跟随）
  class SearchInput < Citrine::Component
    prop :value            # Signal<String>
    prop :placeholder, type: String, default: '搜索…'
    prop :on_enter

    def view
      row(css_class: 'b-search', gap: 6) do
        box(css_class: 'b-search-icon') { '🔍' }
        text_input(value: value, placeholder: placeholder, on_enter: on_enter,
                   css_class: 'b-search-input')
        box(css_class: 'b-search-clear', on_click: ->(_e) { value.set('') }) { '✕' } if value.get.to_s != ''
      end
    end
  end
end
