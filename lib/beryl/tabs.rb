# frozen_string_literal: true

module Beryl
  class Tabs < Citrine::Component
    prop :tabs
    prop :active           # Signal
    prop :on_change

    def view
      stack(css_class: 'b-tabs', gap: 8) do
        row(css_class: 'b-tabbar', gap: 2) do
          tabs.each do |t|
            on = Beryl.pick(t, :id) == active.get
            button(css_class: on ? 'b-tab is-active' : 'b-tab',
                   on_click: ->(_e) { on_change ? on_change.call(Beryl.pick(t, :id)) : active.set(Beryl.pick(t, :id)) }) do
              Beryl.pick(t, :label).to_s
            end
          end
        end
        current = tabs.find { |t| Beryl.pick(t, :id) == active.get }
        box(css_class: 'b-tab-body') { current && Beryl.pick(current, :content)&.call }
      end
    end
  end
end
