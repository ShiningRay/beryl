# frozen_string_literal: true

module Beryl
  # L2 · 键值列表。pairs: 哈希或 [[k, v]]
  class KV < Citrine::Component
    prop :pairs
    prop :label_width, type: Numeric, default: 96

    def view
      stack(css_class: 'b-kv', gap: 2) do
        normalized.each do |k, v|
          row(css_class: 'b-kv-row', gap: 8) do
            box(css_class: 'b-kv-key', style: { width: "#{label_width}px" }) { k.to_s }
            box(css_class: 'b-kv-val') { v.nil? ? '' : v.to_s }
          end
        end
      end
    end

    def normalized
      pairs.is_a?(Hash) ? pairs.to_a : pairs
    end
  end
end
