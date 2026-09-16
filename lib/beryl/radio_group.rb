# frozen_string_literal: true

module Beryl
  # L2 · 单选组（受控）。direction: :column | :row
  class RadioGroup < Citrine::Component
    prop :options
    prop :value            # Signal
    prop :on_change
    prop :direction, default: :column

    def view
      box(css_class: 'b-radiogroup', direction: direction, gap: 6) do
        options.each do |o|
          checked = Beryl.option_value(o) == value.get
          row(css_class: checked ? 'b-radio is-checked' : 'b-radio', gap: 6,
              on_click: ->(_e) { on_change&.call(Beryl.option_value(o)) }) do
            box(css_class: 'b-radio-dot')
            label { Beryl.option_label(o).to_s }
          end
        end
      end
    end
  end
end
