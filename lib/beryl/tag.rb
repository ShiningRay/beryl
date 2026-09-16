# frozen_string_literal: true

module Beryl
  # L2 · 标签（M7）：Badge 的近亲——可关闭、可点选（checkable 受控，
  # checked 传 Signal，F4）。kind 色板同 Badge。
  class Tag < Citrine::Component
    prop :text, type: String
    prop :kind             # String，可空（info/success/warn/error）
    prop :closable, default: false
    prop :on_close
    prop :checkable, default: false
    prop :checked          # Signal<bool>，checkable 时必传（受控）
    prop :on_toggle        # ->(next_checked)

    def view
      if closable
        box(css_class: classes, on_click: clickable? ? :toggle : nil) do
          row(css_class: 'b-tag-inner', gap: 4, style: { align_items: 'center' }) do
            label { text.to_s }
            box(css_class: 'b-tag-x', on_click: ->(_e) { on_close&.call }) { '✕' }
          end
        end
      else
        box(css_class: classes, on_click: clickable? ? :toggle : nil) { text.to_s }
      end
    end

    def classes
      parts = ['b-tag']
      parts << "b-tag-#{kind}" if kind
      parts << 'is-checkable' if checkable
      parts << 'is-checked' if checkable && checked && checked.get
      parts.join(' ')
    end

    def toggle
      on_toggle&.call(!checked.get) if checked
    end

    def clickable?
      checkable && checked
    end
  end
end
