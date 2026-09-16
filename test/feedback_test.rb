# frozen_string_literal: true

require 'minitest/autorun'
require 'beryl'

class FeedbackTest < Minitest::Test
  def render(component)
    Citrine.render(component)
  end

  def test_toast_new_and_legacy_contracts
    legacy = render(Beryl::Toast.new(data: { 'msg' => 'saved', 'kind' => 'info' }))
    assert_includes legacy, 'saved'
    assert_includes legacy, 'b-toast info'

    modern = render(Beryl::Toast.new(msg: 'boom', kind: 'error'))
    assert_includes modern, 'boom'
    assert_includes modern, 'b-toast error'
  end

  def test_toast_action_button
    html = render(Beryl::Toast.new(msg: '已更新', action_label: '撤销'))
    assert_includes html, '撤销'
    assert_includes html, 'b-toast-action'
  end

  def test_timer_sync_backend
    fired = false
    Beryl::Timer.backend = ->(_ms, blk) { blk.call }
    begin
      Beryl::Timer.after(5) { fired = true }
      assert fired
    ensure
      Beryl::Timer.backend = nil
    end
  end

  def test_progress_pct_and_indeterminate
    html = render(Beryl::Progress.new(value: 42))
    assert_includes html, 'width:42.0%'
    sig = Citrine::Signal.new(75.5)
    assert_includes render(Beryl::Progress.new(value: sig)), 'width:75.5%'
    assert_includes render(Beryl::Progress.new(value: 200)), 'width:100%'    # 顶格
    assert_includes render(Beryl::Progress.new(value: -5)), 'width:0%'
    assert_includes render(Beryl::Progress.new(value: 10, indeterminate: true)), 'is-indeterminate'
  end

  def test_spinner_badge_empty_state
    assert_includes render(Beryl::Spinner.new(text: '加载中')), '加载中'
    assert_includes render(Beryl::Badge.new(text: 'v2', kind: 'info')), 'b-badge-info'
    assert_includes render(Beryl::Badge.new(text: 'v2')), 'b-badge'
    empty = render(EmptyHost.new)
    assert_includes empty, '∅'
    assert_includes empty, '暂无数据'
    assert_includes empty, 'EMPTY-ACTION'
  end

  # ── Notification（M7）───────────────────────────────

  def test_notification_title_msg_kind_and_close
    html = render(Beryl::Notification.new(title: '构建完成', msg: '耗时 3s', kind: 'success',
                                          on_close: -> {}))
    assert_includes html, 'b-notification success'
    assert_includes html, '构建完成'
    assert_includes html, '耗时 3s'
    assert_includes html, 'b-notification-x'
  end

  def test_notification_action_and_style_merge
    html = render(Beryl::Notification.new(title: 'n', action_label: '查看',
                                          style: { top: '46px' }))
    assert_includes html, 'b-notification-action'
    assert_includes html, '查看'
    assert_includes html, 'top:46px'
    assert_includes html, 'z-index:4300'   # 缺省 z 序保留，消费者 style 只叠加
  end

  def test_notification_without_optional_parts
    html = render(Beryl::Notification.new(title: '纯标题'))
    refute_includes html, 'b-notification-x'
    refute_includes html, 'b-notification-action'
  end

  def test_badge_css_class_passthrough
    html = render(Beryl::Badge.new(text: '持', css_class: 'badge-hold'))
    assert_includes html, 'b-badge badge-hold'
  end

  # ── Tag（M7）────────────────────────────────────────

  def test_tag_kind_and_close
    html = render(Beryl::Tag.new(text: 'Ruby', kind: 'info', closable: true, on_close: -> {}))
    assert_includes html, 'b-tag b-tag-info'
    assert_includes html, 'Ruby'
    assert_includes html, 'b-tag-x'
  end

  def test_tag_checkable_controlled_toggle
    sig = Citrine::Signal.new(false)
    got = nil
    tag = Beryl::Tag.new(text: 't', checkable: true, checked: sig, on_toggle: ->(v) { got = v })
    refute_includes render(tag), 'is-checked'
    tag.toggle
    assert_equal true, got
    sig.set(true)
    assert_includes render(tag), 'is-checked'
  end
end

class EmptyHost < Citrine::Component
  def view
    Beryl::EmptyState.new(message: '暂无数据', icon: '∅',
                          action: -> { empty_action }).view
  end

  def empty_action
    label { 'EMPTY-ACTION' }
  end
end
