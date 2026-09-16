# frozen_string_literal: true

module Beryl
  # 选项契约归一：接受 [label, value] 数组或 { label:, value: } 哈希
  def self.option_label(opt)
    opt.is_a?(Hash) ? Beryl.pick(opt, :label) : opt[0]
  end

  def self.option_value(opt)
    opt.is_a?(Hash) ? Beryl.pick(opt, :value) : opt[1]
  end

  # L2 · 下拉选择（受控）。value 是 Signal；on_change 收到选中值。
  # 开合态必须受控（open 传 Signal）：父块重渲染会重建组件实例，
  # 内部 state 无法跨渲染存活（F4 的推论）；不传 open 时回退内部态（仅自根挂载可用）。
  # 下拉列表用 CSS 锚定（relative 容器 + absolute 列表），不依赖点击坐标。
  class Select < Citrine::Component
    prop :options
    prop :value            # Signal
    prop :on_change
    prop :open             # Signal<bool> 受控开合，可空
    prop :placeholder, type: String, default: '请选择'
    prop :viewport         # 兼容旧签名；CSS 锚定后不再需要

    state :internal_open, default: false

    def view
      box(css_class: 'b-select-wrap', style: { position: 'relative' }) do
        current = options.find { |o| Beryl.option_value(o) == value.get }
        button(css_class: open? ? 'b-select is-open' : 'b-select',
               on_click: :toggle) do
          current ? "#{Beryl.option_label(current)} ▾" : "#{placeholder} ▾"
        end
        option_list if open?
      end
    end

    def option_list
      box(css_class: 'b-select-list', direction: :column,
          style: { position: 'absolute', top: '100%', left: '0',
                   z_index: Beryl.next_z, min_width: '160px' }) do
        options.each do |o|
          checked = Beryl.option_value(o) == value.get
          box(css_class: checked ? 'menu-item is-checked' : 'menu-item',
              on_click: ->(_e) { on_change&.call(Beryl.option_value(o)); set_open(false) }) do
            "#{checked ? '✓ ' : ''}#{Beryl.option_label(o)}"
          end
        end
      end
    end

    def open?
      open ? open.get : internal_open
    end

    def toggle
      set_open(!open?)
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end
  end

  # L2 · 多选：chips + CSS 锚定的常驻列表（选中打勾，点选不关闭）。
  # 开合受控（open Signal），理由同 Select。
  class MultiSelect < Citrine::Component
    prop :options
    prop :value            # Signal<Array>
    prop :on_change
    prop :open             # Signal<bool> 受控开合，可空
    prop :placeholder, type: String, default: '请选择'
    prop :viewport         # 兼容旧签名

    state :internal_open, default: false

    def view
      box(css_class: 'b-multiselect-wrap', style: { position: 'relative' }) do
        row(css_class: 'b-multiselect', gap: 4) do
          selected.each do |v|
            opt = options.find { |o| Beryl.option_value(o) == v }
            box(css_class: 'b-chip') do
              label { Beryl.option_label(opt).to_s }
              box(css_class: 'b-chip-x', on_click: ->(_e) { toggle(v) }) { '✕' }
            end
          end
          button(css_class: 'b-select b-ms-add', on_click: :toggle) { open? ? '收起 ▴' : '+ 添加' }
        end
        option_list if open?
      end
    end

    def option_list
      box(css_class: 'b-select-list', direction: :column,
          style: { position: 'absolute', top: '100%', left: '0',
                   z_index: Beryl.next_z, min_width: '160px' }) do
        options.each do |o|
          checked = selected.include?(Beryl.option_value(o))
          box(css_class: checked ? 'menu-item is-checked' : 'menu-item',
              on_click: ->(_e) { toggle(Beryl.option_value(o)) }) do
            "#{checked ? '✓ ' : ''}#{Beryl.option_label(o)}"
          end
        end
      end
    end

    def selected
      value.get || []
    end

    def open?
      open ? open.get : internal_open
    end

    def toggle_open
      set_open(!open?)
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end

    def toggle(v)
      selected = self.selected.dup
      selected.include?(v) ? selected.delete(v) : selected << v
      on_change&.call(selected)
    end
  end

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

  # L2 · 开关（受控）
  class Switch < Citrine::Component
    prop :value            # Signal（truthy = 开）
    prop :on_change

    def view
      box(css_class: value.get ? 'b-switch is-on' : 'b-switch',
          on_click: :toggle) do
        box(css_class: 'b-switch-thumb')
      end
    end

    def toggle
      on_change&.call(!value.get)
    end
  end

  # L2 · 滑杆（受控）：− / + 步进 + 进度条视觉；拖拽滑块留待数据拖放原语就绪
  class Slider < Citrine::Component
    prop :value            # Signal<Numeric>
    prop :min, type: Numeric, default: 0
    prop :max, type: Numeric, default: 100
    prop :step, type: Numeric, default: 1
    prop :on_change

    def view
      row(css_class: 'b-slider', gap: 8) do
        button(css_class: 'b-slider-btn', on_click: :step_down) { '−' }
        box(css_class: 'b-slider-track') do
          box(css_class: 'b-slider-fill', style: { width: "#{pct}%" })
          box(css_class: 'b-slider-thumb', style: { left: "#{pct}%" })
        end
        button(css_class: 'b-slider-btn', on_click: :step_up) { '+' }
      end
    end

    def step_by(delta)
      v = value.get.to_f + delta
      v = min if v < min
      v = max if v > max
      on_change&.call(v)
    end

    def step_up;   step_by(step);   end
    def step_down; step_by(-step);  end

    private

    def pct
      span = max - min
      return 0 if span.zero?

      (((value.get.to_f - min) / span) * 100).round(2)
    end
  end

  # L2 · 数字输入：text_input（Signal 双向）+ 步进按钮
  class NumberInput < Citrine::Component
    prop :value            # Signal
    prop :min, type: Numeric, default: 0
    prop :max, type: Numeric, default: 100
    prop :step, type: Numeric, default: 1
    prop :width, type: Numeric, default: 72
    prop :on_change

    def view
      row(css_class: 'b-number', gap: 4) do
        button(css_class: 'b-number-btn', on_click: :step_down) { '−' }
        text_input(value: value, css_class: 'b-number-input',
                   style: { width: "#{width}px" })
        button(css_class: 'b-number-btn', on_click: :step_up) { '+' }
      end
    end

    def step_by(delta)
      v = value.get.to_f + delta
      v = min if v < min
      v = max if v > max
      value.set(v)
      on_change&.call(v)
    end

    def step_up;   step_by(step);   end
    def step_down; step_by(-step);  end
  end

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

  # L2 · 通用单行输入（受控，M7）。value 是 Signal（每键更新）；
  # 前后缀字形、清空钮、错误态、禁用。disabled/error 接受明值或 Signal（Beryl.flag）。
  # SearchInput/NumberInput 是它的场景化近亲（保留，暂不迁移）。
  class Input < Citrine::Component
    prop :value            # Signal<String>
    prop :placeholder, type: String, default: ''
    prop :prefix           # String 前缀字形，可空
    prop :suffix           # String 后缀字形，可空
    prop :clearable, default: false  # 有值时显示 ✕
    prop :disabled         # bool | Signal，可空
    prop :error            # bool | Signal，可空 → is-error
    prop :width            # Numeric px，可空（可空 prop 不带 type，F3）
    prop :on_enter

    def view
      row(css_class: wrap_class, gap: 6, style: wrap_style) do
        box(css_class: 'b-input-glyph') { prefix } if prefix
        ti = { value: value, placeholder: placeholder, on_enter: on_enter,
               css_class: 'b-input-inner' }
        ti[:disabled] = true if disabled?
        text_input(**ti)
        if clearable && value.get.to_s != ''
          box(css_class: 'b-input-clear', on_click: ->(_e) { value.set('') }) { '✕' }
        end
        box(css_class: 'b-input-glyph') { suffix } if suffix
      end
    end

    def wrap_class
      parts = ['b-input']
      parts << 'is-error' if Beryl.flag(error)
      parts << 'is-disabled' if disabled?
      parts.join(' ')
    end

    def wrap_style
      width ? { width: "#{width}px" } : nil
    end

    def disabled?
      !!Beryl.flag(disabled)
    end
  end

  # L2 · 复选框（受控，M7）。value Signal truthy = 勾选；独立于 Switch 的
  # 二元勾选件（表单语义：勾选 ≠ 开关）。disabled 接受明值或 Signal。
  class Checkbox < Citrine::Component
    prop :value            # Signal（truthy = 勾选）
    prop :text             # String，可空
    prop :on_change
    prop :disabled         # bool | Signal，可空

    def view
      row(css_class: cb_class, gap: 6, on_click: enabled? ? :toggle : nil) do
        box(css_class: 'b-checkbox-box') { '✓' if value.get }
        label { text.to_s } if text
      end
    end

    def cb_class
      parts = ['b-checkbox']
      parts << 'is-checked' if value.get
      parts << 'is-disabled' if disabled?
      parts.join(' ')
    end

    def toggle
      on_change&.call(!value.get)
    end

    def disabled?
      !!Beryl.flag(disabled)
    end

    def enabled?
      !disabled?
    end
  end

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

  # L2 · 自动完成：输入即过滤（Signal 驱动），候选列表 CSS 锚定，
  # Enter 取第一个、Esc 收起。开合受控（open Signal），理由同 Select。
  class Combobox < Citrine::Component
    prop :options          # [String]
    prop :value            # Signal<String>
    prop :placeholder, type: String, default: ''
    prop :open             # Signal<bool> 受控开合，可空
    prop :on_pick

    state :internal_open, default: false

    def view
      text_input(value: value, placeholder: placeholder,
                 css_class: 'b-combobox',
                 on_focus: ->(_e) { set_open(true) },
                 on_key: {
                   'Escape' => ->(_ev) { set_open(false) },
                   'Enter' => :pick_first,
                 })
      return unless open?

      q = value.get.to_s
      hits = q == '' ? options : options.select { |o| o.to_s.include?(q) }
      return if hits.empty?

      box(css_class: 'b-combobox-list', direction: :column,
          style: { position: 'absolute', z_index: Beryl.next_z }) do
        hits.first(8).each do |o|
          box(css_class: 'menu-item b-menu-item', on_click: :pick) { o.to_s }
        end
      end
    end

    def open?
      open ? open.get : internal_open
    end

    def set_open(v)
      open ? open.set(v) : (self.internal_open = v)
    end

    def pick_first
      q = value.get.to_s
      hits = options.select { |o| o.to_s.include?(q) }
      return if hits.empty?

      value.set(hits.first.to_s)
      set_open(false)
      on_pick&.call(hits.first)
    end

    def pick; pick_first; end
  end

  # L2 · 取色器 v1：预设色板网格（自由取色等 Canvas 原语就绪）
  class ColorPicker < Citrine::Component
    PALETTE = %w[#4f8cff #3fb950 #d29922 #f85149 #bc8cff #39c5cf
                 #ffffff #adbac7 #6e7681 #22272e #e2c08d #ff9bce].freeze
    prop :value            # Signal<String>
    prop :colors, default: PALETTE
    prop :on_change

    def view
      box(css_class: 'b-colorpicker') do
        row(css_class: 'b-color-grid', gap: 6) do
          colors.each do |c|
            box(css_class: value.get == c ? 'b-color-swatch is-active' : 'b-color-swatch',
                style: { background: c },
                on_click: ->(_e) { on_change&.call(c) })
          end
        end
      end
    end
  end

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

  # L2 · 表单字段组装层（M7）：标题/必填标记/错误/提示 + 控件插槽。
  # 校验规则框架延后：error 文本由消费者（Store/表单逻辑）算好传入，
  # Field 只负责布局与错误态呈现。
  class Field < Citrine::Component
    prop :title            # String，可空
    prop :required, default: false
    prop :error            # String，可空（有值即错误态）
    prop :hint             # String，可空
    prop :content          # Proc 插槽（F2）：控件

    def view
      stack(css_class: error ? 'b-field has-error' : 'b-field', gap: 4) do
        if title
          row(css_class: 'b-field-title', gap: 4) do
            label { title.to_s }
            box(css_class: 'b-field-req') { '*' } if required
          end
        end
        content.call if content
        box(css_class: 'b-field-error') { error } if error
        box(css_class: 'b-field-hint') { hint } if hint
      end
    end
  end

  # L2 · 表单容器（M7）：Field 纵向排列 + 提交区。
  # footer 插槽可覆盖缺省的主按钮；on_submit 挂在主按钮的 on_click 上。
  # 注意 `form` 是 citrine 元素词表（ELEMENT_TAGS）——本类用 stack 语义足够。
  class Form < Citrine::Component
    prop :content          # Proc 插槽：Field 列表
    prop :submit_text, type: String, default: '提交'
    prop :on_submit
    prop :footer           # Proc 插槽，可空

    def view
      stack(css_class: 'b-form', gap: 12) do
        content.call if content
        stack(css_class: 'b-form-foot', gap: 6) do
          if footer
            footer.call
          else
            Button.new(text: submit_text, kind: :primary, on_click: on_submit).view
          end
        end
      end
    end
  end
end
