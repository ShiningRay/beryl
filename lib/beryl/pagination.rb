# frozen_string_literal: true

module Beryl
  # L2 · 分页（受控）。page 是 Signal（1 起）。
  # 页数 ≤ 9 全展示，否则滑窗（首页/末页常驻，其余 … 折叠）。
  class Pagination < Citrine::Component
    prop :page             # Signal<Numeric>
    prop :total, type: Numeric
    prop :per_page, type: Numeric, default: 20
    prop :on_change

    def view
      row(css_class: 'b-pagination', gap: 4) do
        button(css_class: 'b-page-btn', on_click: :prev) { '‹' }
        visible_pages.each do |p|
          if p == :ellipsis
            box(css_class: 'b-page-ellipsis') { '…' }
          else
            button(css_class: p == page.get ? 'b-page-btn is-active' : 'b-page-btn',
                   on_click: ->(_e) { go(p) }) { p.to_s }
          end
        end
        button(css_class: 'b-page-btn', on_click: :next) { '›' }
      end
    end

    def pages
      n = (total.to_f / per_page).ceil
      n < 1 ? 1 : n
    end

    def visible_pages
      n = pages
      cur = page.get
      return (1..n).to_a if n <= 9

      out = [1]
      lo = cur - 1 < 2 ? 2 : cur - 1
      hi = cur + 1 > n - 1 ? n - 1 : cur + 1
      out << :ellipsis if lo > 2
      (lo..hi).each { |p| out << p }
      out << :ellipsis if hi < n - 1
      out << n
      out
    end

    def go(p)
      p = 1 if p < 1
      p = pages if p > pages
      on_change ? on_change.call(p) : page.set(p)
    end

    def prev; go(page.get - 1); end
    def next; go(page.get + 1); end
  end
end
