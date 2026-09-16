# frozen_string_literal: true

module Beryl
  # L2 · 复选组（受控，M7）。value Signal<Array>；契约同 RadioGroup。
  class CheckboxGroup < Citrine::Component
    prop :options
    prop :value            # Signal<Array>
    prop :on_change
    prop :direction, default: :column

    def view
      box(css_class: 'b-checkboxgroup', direction: direction, gap: 6) do
        options.each do |o|
          v = Beryl.option_value(o)
          on = selected.include?(v)
          row(css_class: on ? 'b-checkbox is-checked' : 'b-checkbox', gap: 6,
              on_click: ->(_e) { toggle(v) }) do
            box(css_class: 'b-checkbox-box') { '✓' if on }
            label { Beryl.option_label(o).to_s }
          end
        end
      end
    end

    def selected
      value.get || []
    end

    def toggle(v)
      cur = selected.dup
      cur.include?(v) ? cur.delete(v) : cur << v
      on_change&.call(cur)
    end
  end
end
