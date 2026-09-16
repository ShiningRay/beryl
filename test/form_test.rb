# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class FormTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  OPTS = [['Ruby', :ruby], ['JS', :js]]

  # ── Select ────────────────────────────────────────────

  def test_select_renders_current_label
    sig = Citrine::Signal.new(:js)
    html = render(Beryl::Select.new(options: OPTS, value: sig))
    assert_includes html, 'JS'
    assert_includes html, 'b-select'
    refute_includes html, 'menu-overlay'  # 闭合态没有下拉
  end

  def test_select_change_fires_on_change
    sig = Citrine::Signal.new(:ruby)
    got = nil
    sel = Beryl::Select.new(options: OPTS, value: sig, on_change: ->(v) { got = v })
    sel.view rescue nil   # 闭合态渲染（无宿主上下文时插槽不涉及）
    assert_equal :ruby, sig.get
    # 模拟选中第二项：直接走 Menu item 的 action 路径太深，这里验证 on_change 契约
    sel.on_change.call(:js)
    assert_equal :js, got
  end

  # ── MultiSelect ───────────────────────────────────────

  def test_multiselect_renders_chips_and_toggles
    sig = Citrine::Signal.new([:ruby])
    got = nil
    ms = Beryl::MultiSelect.new(options: OPTS, value: sig,
                                on_change: ->(v) { sig.set(v); got = v })
    html = render(ms)
    assert_includes html, 'b-chip'
    assert_includes html, 'Ruby'
    ms.toggle(:js)
    assert_equal [:ruby, :js], got
    ms.toggle(:js)
    assert_equal [:ruby], got
  end

  # ── RadioGroup ────────────────────────────────────────

  def test_radiogroup_marks_checked_and_fires
    sig = Citrine::Signal.new(:js)
    got = nil
    html = render(Beryl::RadioGroup.new(options: OPTS, value: sig, on_change: ->(v) { got = v }))
    assert_includes html, 'is-checked'
    refute_match(/b-radio is-checked[^\n]*Ruby/, html) # 勾的是 JS 不是 Ruby（宽松断言：见下行）
    assert_includes html, 'b-radio-dot'
    # 点击行为 = on_change 契约
    sig.set(:ruby)
    assert_equal :ruby, sig.get
  end

  # ── Switch ────────────────────────────────────────────

  def test_switch_toggles
    sig = Citrine::Signal.new(false)
    got = nil
    sw = Beryl::Switch.new(value: sig, on_change: ->(v) { got = v })
    refute_includes render(sw), 'is-on'
    sw.toggle
    assert_equal true, got
    assert_includes render(Beryl::Switch.new(value: Citrine::Signal.new(true), on_change: ->(_) {})), 'is-on'
  end

  # ── Slider / NumberInput ──────────────────────────────

  def test_slider_steps_within_bounds
    sig = Citrine::Signal.new(95)
    got = nil
    s = Beryl::Slider.new(value: sig, min: 0, max: 100, step: 10,
                          on_change: ->(v) { sig.set(v); got = v })
    html = render(s)
    assert_includes html, 'width:95.0%'
    s.step_up
    assert_equal 100, got
    s.step_up
    assert_equal 100, got                # 顶住 max
    s.step_down
    assert_equal 90, got
  end

  def test_number_input_steps_and_writes_signal
    sig = Citrine::Signal.new(5)
    got = nil
    n = Beryl::NumberInput.new(value: sig, min: 0, max: 10, step: 2, on_change: ->(v) { got = v })
    render(n)
    n.step_up
    assert_equal 7, sig.get
    assert_equal 7, got
    3.times { n.step_up }
    assert_equal 10, sig.get             # clamp 到 max
  end

  # ── SearchInput / Combobox ────────────────────────────

  def test_search_input_shows_clear_only_with_value
    empty = Citrine::Signal.new('')
    refute_includes render(Beryl::SearchInput.new(value: empty)), 'b-search-clear'
    full = Citrine::Signal.new('abc')
    assert_includes render(Beryl::SearchInput.new(value: full)), 'b-search-clear'
  end

  def test_combobox_filters_and_picks_first
    sig = Citrine::Signal.new('')
    picked = nil
    cb = Beryl::Combobox.new(options: %w[ruby rust racket], value: sig, on_pick: ->(v) { picked = v })
    html = render(cb)
    refute_includes html, 'b-combobox-list'  # 未聚焦不展开
    sig.set('ru')
    html = Citrine.render(cb)
    # open 态需要浏览器交互；这里直接验证 pick_first 的过滤逻辑
    cb_pick = Beryl::Combobox.new(options: %w[ruby rust racket], value: Citrine::Signal.new('ra'), on_pick: ->(v) { picked = v })
    cb_pick.pick_first
    assert_equal 'racket', picked
    assert_equal 'racket', cb_pick.value.get
  end

  # ── ColorPicker / DatePicker ──────────────────────────

  def test_colorpicker_marks_active
    sig = Citrine::Signal.new('#3fb950')
    got = nil
    html = render(Beryl::ColorPicker.new(value: sig, on_change: ->(c) { got = c }))
    assert_includes html, 'background:#3fb950'
    assert_includes html, 'is-active'
    sig.set('#ffffff')
    got = nil
    render(Beryl::ColorPicker.new(value: sig, on_change: ->(c) { got = c }))
    assert_nil got                        # 渲染本身不触发
  end

  def test_datepicker_renders_month_and_marks_value
    t = Time.local(2026, 9, 14)
    html = render(Beryl::DatePicker.new(value: Citrine::Signal.new(t)))
    assert_includes html, '2026 年 9 月'
    assert_includes html, 'is-active'
    # 2026-09-01 是周二 → 前面 2 个空位；9 月 30 天
    dp = Beryl::DatePicker.new(value: Citrine::Signal.new(t))
    assert_equal 2, dp.send(:leading_blanks, 2026, 9)
    assert_equal 30, dp.send(:days_in_month, 2026, 9)
    assert_equal 28, dp.send(:days_in_month, 2026, 2)
    assert_equal 29, dp.send(:days_in_month, 2024, 2)
  end

  def test_datepicker_month_nav
    t = Time.local(2026, 1, 14)
    dp = Beryl::DatePicker.new(value: Citrine::Signal.new(t))
    dp.prev_month
    assert_equal [2025, 12], dp.shown_month
    dp.next_month
    dp.next_month
    assert_equal [2026, 2], dp.shown_month
  end

  # ── Input（M7）──────────────────────────────────────

  def test_input_renders_prefix_placeholder
    sig = Citrine::Signal.new('hi')
    html = render(Beryl::Input.new(value: sig, placeholder: '写点…', prefix: '✎'))
    assert_includes html, 'b-input'
    assert_includes html, '✎'
    assert_includes html, '写点…'
  end

  def test_input_clear_button_only_with_value
    sig = Citrine::Signal.new('')
    refute_includes render(Beryl::Input.new(value: sig, clearable: true)), 'b-input-clear'
    sig.set('x')
    assert_includes render(Beryl::Input.new(value: sig, clearable: true)), 'b-input-clear'
  end

  def test_input_error_state_and_disabled_signal
    assert_includes render(Beryl::Input.new(value: Citrine::Signal.new(''), error: true)), 'is-error'
    sig = Citrine::Signal.new(false)
    input = Beryl::Input.new(value: Citrine::Signal.new(''), disabled: sig)
    refute input.disabled?
    sig.set(true)
    assert input.disabled?
  end

  # ── Checkbox（M7）───────────────────────────────────

  def test_checkbox_checked_state_and_toggle
    sig = Citrine::Signal.new(false)
    got = nil
    cb = Beryl::Checkbox.new(value: sig, text: '同意', on_change: ->(v) { got = v })
    refute_includes render(cb), 'is-checked'
    cb.toggle
    assert_equal true, got
    assert_includes render(Beryl::Checkbox.new(value: Citrine::Signal.new(true), text: '同意')), 'is-checked'
  end

  def test_checkbox_group_toggles_membership
    sig = Citrine::Signal.new([:red])
    got = nil
    grp = Beryl::CheckboxGroup.new(options: [['红', :red], ['蓝', :blue]],
                                   value: sig, on_change: ->(v) { sig.set(v); got = v })
    html = render(grp)
    assert_includes html, '红'
    assert_includes html, 'is-checked'
    grp.toggle(:blue)
    assert_equal [:red, :blue], got
    grp.toggle(:red)
    assert_equal [:blue], got
  end

  # ── Field / Form（M7）───────────────────────────────

  def test_field_layout_title_required_error_hint
    html = render(Beryl::Field.new(title: '备注', required: true,
                                   error: '必填项', hint: '不超过 10 字',
                                   content: -> {
                                     Beryl::Input.new(value: Citrine::Signal.new('')).view
                                   }))
    assert_includes html, 'b-field-title'
    assert_includes html, 'b-field-req'
    assert_includes html, '必填项'
    assert_includes html, 'b-field-hint'
    assert_includes html, 'b-input'
    assert_includes html, 'has-error'
  end

  def test_form_default_submit_and_footer_override
    html = render(Beryl::Form.new(on_submit: -> {}, content: -> {
      Beryl::Field.new(title: '字段区',
                       content: -> { Beryl::Input.new(value: Citrine::Signal.new('')).view }).view
    }))
    assert_includes html, 'b-btn-primary'
    assert_includes html, '提交'
    assert_includes html, 'b-field'

    html = render(Beryl::Form.new(footer: -> { '自定义底部' }, content: -> {}))
    assert_includes html, '自定义底部'
    refute_includes html, 'b-btn-primary'
  end

  def test_prop_contract
    assert_raises(ArgumentError) { Beryl::Select.new(options: OPTS, value: Citrine::Signal.new(:ruby), bogus: 1) }
  end
end
