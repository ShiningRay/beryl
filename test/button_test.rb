# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class ButtonTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  # ── Button ────────────────────────────────────────────

  def test_renders_text_and_default_class
    html = render(Beryl::Button.new(text: '保存'))
    assert_includes html, 'b-btn'
    assert_includes html, '保存'
    refute_includes html, 'b-btn-primary'
  end

  def test_kind_and_size_classes
    html = render(Beryl::Button.new(text: '删', kind: :danger, size: :sm))
    assert_includes html, 'b-btn-danger'
    assert_includes html, 'b-btn-sm'
  end

  def test_content_slot_overrides_text
    html = render(Beryl::Button.new(text: '不该出现', content: -> { '插槽内容' }))
    assert_includes html, '插槽内容'
    refute_includes html, '不该出现'
  end

  def test_icon_loading_block_classes
    html = render(Beryl::Button.new(text: '存', icon: '💾', loading: true, block: true))
    assert_includes html, 'is-loading'
    assert_includes html, 'b-btn-block'
    assert_includes html, '◌'
    assert_includes html, '💾'
  end

  def test_disabled_reads_value_or_signal
    refute Beryl::Button.new(text: 'x').disabled?
    assert Beryl::Button.new(text: 'x', disabled: true).disabled?
    sig = Citrine::Signal.new(false)
    btn = Beryl::Button.new(text: 'x', disabled: sig)
    refute btn.disabled?
    sig.set(true)
    assert btn.disabled?
  end

  def test_loading_or_disabled_not_clickable
    refute Beryl::Button.new(text: 'x', loading: true).clickable?
    refute Beryl::Button.new(text: 'x', disabled: true).clickable?
    assert Beryl::Button.new(text: 'x').clickable?
  end

  def test_disabled_renders_attribute_but_no_click
    html = render(Beryl::Button.new(text: 'x', disabled: true))
    assert_includes html, 'disabled'
  end

  def test_css_class_and_style_passthrough
    html = render(Beryl::Button.new(text: '×', kind: :primary,
                                    css_class: 'calc-key', style: { background: '#f59e0b' }))
    assert_includes html, 'b-btn b-btn-primary calc-key'
    assert_includes html, 'background:#f59e0b'
  end

  def test_key_passthrough_for_keyed_reuse
    html = render(Beryl::Button.new(text: 'D2', css_class: 'chip', key: 'dep-D2'))
    assert_includes html, 'chip'
    refute_includes html, 'key:'     # key 被渲染器消费，不出现在输出属性里
  end

  def test_css_class_proc_is_passed_through_for_reactive_classes
    sig = Citrine::Signal.new(false)
    btn = Beryl::Button.new(text: 'x', css_class: -> { sig.get ? 'chip is-on' : 'chip' })
    assert btn.css_class.is_a?(Proc)   # 契约：Proc 原样透传给元素（响应式求值）
  end

  def test_block_width_overridden_by_consumer_style
    html = render(Beryl::Button.new(text: 'x', block: true, style: { width: '40%' }))
    assert_includes html, 'width:40%'    # 消费者键优先
  end

  # ── ButtonGroup ───────────────────────────────────────

  def test_button_group_renders_content_buttons
    html = render(Beryl::ButtonGroup.new(content: -> {
      Beryl::Button.new(text: 'A').view
      Beryl::Button.new(text: 'B').view
    }))
    assert_includes html, 'b-btn-group'
    assert_includes html, 'A'
    assert_includes html, 'B'
  end
end
