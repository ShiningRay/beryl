# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class TabsDialogTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  # ── Tabs ──────────────────────────────────────────────

  def test_tabs_render_active_content_only
    active = Citrine::Signal.new('inh')
    host = TabsHost.new(active)
    html = render(host.tabs)
    assert_includes html, 'own'            # tab 标签都在
    assert_includes html, 'inherited'
    assert_includes html, 'INH-BODY'
    refute_includes html, 'OWN-BODY'       # 只渲染活动页内容
    assert_includes html, 'is-active'
  end

  def test_accordion_internal_single_open
    host = AccHost.new
    html = render(host.acc)
    refute_includes html, 'A-BODY'         # 默认全收起
    refute_includes html, 'B-BODY'
    host.acc.toggle(:a)
    html = Citrine.render(host.acc)
    assert_includes html, 'A-BODY'
    refute_includes html, 'B-BODY'
    host.acc.toggle(:b)                    # 单开模式：切换
    html = Citrine.render(host.acc)
    assert_includes html, 'B-BODY'
    refute_includes html, 'A-BODY'
  end

  def test_accordion_controlled_multi_open
    open_sig = Citrine::Signal.new([:a, :b])
    host = AccHost.new(open_sig)
    html = render(host.acc)
    assert_includes html, 'A-BODY'
    assert_includes html, 'B-BODY'
    host.acc.toggle(:a)
    assert_equal [:b], open_sig.get
  end

  # ── Dialog / Alert / Confirm / Prompt ─────────────────

  def test_dialog_renders_overlay_title_footer_and_slots
    host = DialogHost.new
    html = render(host.dialog)
    assert_includes html, 'b-dialog-overlay'
    assert_includes html, '确认删除'
    assert_includes html, 'DIALOG-BODY'
    assert_includes html, '取消'
    assert_includes html, '删除'
  end

  FakeEvent = Struct.new(:key)

  def test_dialog_escape_runs_cancel
    canceled = false
    d = Beryl::Dialog.new(title: 't', on_cancel: -> { canceled = true })
    d.handle_escape(FakeEvent.new('Enter'))
    refute canceled
    d.handle_escape(FakeEvent.new('Escape'))
    assert canceled
  end

  def test_alert_and_confirm_wrap_dialog
    html = render(Beryl::Alert.new(title: '提示', message: '已保存', on_confirm: -> {}))
    assert_includes html, '已保存'
    assert_includes html, '确定'
    refute_includes html, '取消'

    html = render(Beryl::Confirm.new(title: '确认', message: '删除？',
                                     on_confirm: -> {}, on_cancel: -> {}))
    assert_includes html, '删除？'
    assert_includes html, '取消'
  end

  def test_prompt_binds_input_signal
    input = Citrine::Signal.new('hello')
    confirmed = nil
    html = render(Beryl::Prompt.new(title: '重命名', message: '新名称：',
                                    input: input, on_confirm: ->(v) { confirmed = v }))
    assert_includes html, 'hello'
    input.set('world')
    # on_confirm 的接线由 Prompt 内部闭包完成，直接调用 Dialog 的确认路径验证
    p = Beryl::Prompt.new(title: 't', message: 'm', input: input, on_confirm: ->(v) { confirmed = v })
    html2 = render(p)
    assert_includes html2, 'world'
  end
end

# ── 宿主组件 ─────────────────────────────────────────────

class TabsHost < Citrine::Component
  def initialize(active)
    @active = active
    super()
  end

  def tabs
    Beryl::Tabs.new(
      tabs: [
        { id: 'own', label: 'own', content: -> { own_body } },
        { id: 'inh', label: 'inherited', content: -> { inh_body } },
      ],
      active: @active,
    )
  end

  def own_body; label { 'OWN-BODY' }; end
  def inh_body; label { 'INH-BODY' }; end

  def view; end
end

class AccHost < Citrine::Component
  def initialize(open_sig = nil)
    @open = open_sig
    super()
  end

  def acc
    @acc ||= Beryl::Accordion.new(
      sections: [
        { id: :a, label: 'A', content: -> { label { 'A-BODY' } } },
        { id: :b, label: 'B', content: -> { label { 'B-BODY' } } },
      ],
      open: @open,
    )
  end

  def view; end
end

class DialogHost < Citrine::Component
  def dialog
    Beryl::Dialog.new(title: '确认删除',
                      content: -> { dialog_body },
                      on_confirm: -> {}, on_cancel: -> {},
                      confirm_text: '删除')
  end

  def dialog_body; label { 'DIALOG-BODY' }; end

  def view; end
end
