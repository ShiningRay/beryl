# frozen_string_literal: true

module Beryl
  # L2 · 面包屑。items: [{ label:, on_click?: }]
  class Breadcrumb < Citrine::Component
    prop :items

    def view
      row(css_class: 'b-breadcrumb', gap: 6) do
        items.each_with_index do |it, i|
          box(css_class: 'b-crumb-sep') { '›' } if i.positive?
          if Beryl.pick(it, :on_click)
            box(css_class: 'b-crumb is-link', on_click: ->(_e) { Beryl.pick(it, :on_click).call }) do
              Beryl.pick(it, :label).to_s
            end
          else
            box(css_class: 'b-crumb') { Beryl.pick(it, :label).to_s }
          end
        end
      end
    end
  end
end
