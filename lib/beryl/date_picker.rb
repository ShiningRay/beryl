# frozen_string_literal: true

module Beryl
  # L2 · 日期选择 v1：月视图网格，value 为 Time（浏览器/CRuby 两侧都有）。
  # 只用整数算术（Zeller 同余）推星期，不依赖 Date/strftime，Opal 侧同样可测。
  # 月份游标受控（cursor Signal<[y, m]>），理由同 Select——内部态活不过父块重渲染。
  class DatePicker < Citrine::Component
    prop :value            # Signal<Time|nil>
    prop :cursor           # Signal<[year, month]> 受控月份游标，可空
    prop :on_change

    def view
      y, m = shown_month
      stack(css_class: 'b-datepicker', gap: 6) do
        row(css_class: 'b-dp-head', gap: 6) do
          button(css_class: 'b-dp-nav', on_click: :prev_month) { '‹' }
          label { "#{y} 年 #{m} 月" }
          button(css_class: 'b-dp-nav', on_click: :next_month) { '›' }
        end
        box(css_class: 'b-dp-grid',
            style: { display: 'grid', grid_template_columns: 'repeat(7, 30px)', gap: '2px' }) do
          %w[日 一 二 三 四 五 六].each { |w| box(css_class: 'b-dp-wday') { w } }
          leading_blanks(y, m).times { box(css_class: 'b-dp-blank') }
          (1..days_in_month(y, m)).each do |d|
            box(css_class: day_class(y, m, d),
                on_click: ->(_e) { pick(y, m, d) }) { d.to_s }
          end
        end
      end
    end

    def shown_month
      return cursor.get if cursor
      return internal_cursor if internal_cursor

      v = value.get
      v ? [v.year, v.month] : [Time.now.year, Time.now.month]
    end

    def shift_month(delta)
      y, m = shown_month
      total = y * 12 + (m - 1) + delta
      next_cur = [total / 12, total % 12 + 1]
      cursor ? cursor.set(next_cur) : (self.internal_cursor = next_cur)
    end

    # 内部态模式（无受控 cursor）时的月份游标：仅自根挂载时可靠
    attr_accessor :internal_cursor

    def prev_month; shift_month(-1); end
    def next_month; shift_month(1);  end

    def pick(y, m, d)
      on_change&.call(Time.local(y, m, d))
    end

    def day_class(y, m, d)
      v = value.get
      on = v && v.year == y && v.month == m && v.day == d
      on ? 'b-dp-day is-active' : 'b-dp-day'
    end

    private

    def days_in_month(y, m)
      return 29 if m == 2 && ((y % 4).zero? && !(y % 100).zero? || (y % 400).zero?)

      [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
    end

    # Zeller 同余：该月 1 号是星期几（0 = 周日）
    def leading_blanks(y, m)
      yy = m < 3 ? y - 1 : y
      mm = m < 3 ? m + 12 : m
      h = (1 + (13 * (mm + 1)) / 26 + yy % 100 + (yy % 100) / 4 + yy / 400 + 5 * (yy / 100)) % 7
      (h + 6) % 7
    end
  end
end
