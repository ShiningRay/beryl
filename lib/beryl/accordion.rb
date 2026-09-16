# frozen_string_literal: true

module Beryl
  # L2 · 手风琴/折叠分区。
  #   sections: [{ id:, label:, content: -> { ... } }]
  #   open: Signal<Array> 受控多开；不传则组件内部单开（内部 UI 态，F4 允许）
  class Accordion < Citrine::Component
    prop :sections
    prop :open             # Signal<Array> 可选

    state :internal, default: nil

    def view
      stack(css_class: 'b-accordion') do
        sections.each do |s|
          id = Beryl.pick(s, :id)
          box(css_class: 'b-acc-item', direction: :column) do
            row(css_class: open?(id) ? 'b-acc-head is-open' : 'b-acc-head',
                on_click: ->(_e) { toggle(id) }) do
              box(css_class: 'b-acc-caret') { open?(id) ? '▾' : '▸' }
              label { Beryl.pick(s, :label).to_s }
            end
            box(css_class: 'b-acc-body') { Beryl.pick(s, :content)&.call } if open?(id)
          end
        end
      end
    end

    def open?(id)
      if open
        (open.get || []).include?(id)
      else
        internal == id
      end
    end

    def toggle(id)
      if open
        cur = (open.get || []).include?(id) ? (open.get || []) - [id] : (open.get || []) + [id]
        open.set(cur)
      else
        self.internal = internal == id ? nil : id
      end
    end
  end
end
