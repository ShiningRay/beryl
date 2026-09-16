# frozen_string_literal: true

module Beryl
  # L3 · 任务栏：窗口切换条。当前激活窗口再点 → 最小化；最小化/后台窗口点 → 还原置顶。
  class Taskbar < Citrine::Component
    prop :wm                   # WindowManager
    prop :height, type: Numeric, default: 40

    def view
      row(css_class: 'b-taskbar', gap: 6,
          style: { position: 'fixed', left: '0', right: '0', bottom: '0',
                   height: "#{height}px", z_index: 4000 }) do
        wm.each_window do |r|
          button(css_class: taskbar_class(r), on_click: ->(_e) { activate(r.id) }) do
            r.title
          end
        end
      end
    end

    def taskbar_class(r)
      cls = 'b-taskbtn'
      cls += ' is-active' if wm.active?(r.id)
      cls += ' is-minimized' if wm.minimized?(r.id)
      cls
    end

    def activate(id)
      if wm.active?(id)
        wm.toggle_min(id)
      else
        wm.focus(id)
      end
    end
  end
end
