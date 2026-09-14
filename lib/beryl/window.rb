# frozen_string_literal: true

module Beryl
  # L3 · 窗口框：桌面式面板外壳——标题栏（拖动/右键菜单/置顶/点击）
  # + 内容插槽 + 可选缩放手柄。
  #
  # 插槽模式（库法则 F2）：content / tools 是 Proc prop，闭包保留父组件
  # 上下文——插槽内调用的 box/label/button 由父组件 emit（owner 归属父），
  # 因此插槽内容的信号订阅挂在父组件上，与 WindowFrame 自身解耦。
  class WindowFrame < Citrine::Component
    prop :title, type: String, default: ''
    prop :subtitle, type: String, default: ''
    prop :accent, type: String, default: '#4f8cff'
    prop :css_class, type: String, default: ''
    prop :body_class, type: String, default: ''
    prop :geometry         # { 'px' =>, 'py' =>, 'pw' =>?, 'ph' =>? }
    prop :z_index
    prop :resizable, default: true
    prop :on_move          # ->(ev{ x, y })
    prop :on_resize        # ->(ev{ w, h })
    prop :on_front         # ->(el)
    prop :on_menu          # ->(ev) 右键标题栏
    prop :on_head_click    # ->(ev) 左键标题栏
    prop :on_body_click
    prop :content          # Proc 插槽：主体内容
    prop :tools            # Proc 插槽：标题栏尾部（如 ✕ 按钮）

    def view
      head_opts = { drag_move: on_move, on_menu: on_menu, on_click: on_head_click }.compact
      body_opts = { on_click: on_body_click }.compact
      frame_opts = { on_front: on_front }.compact

      # 类名沿用应用侧既有 CSS（panel/panel-head/...）；b- 前缀 token 化在 M5 主题系统时统一迁移
      box(css_class: "panel #{css_class}".strip, direction: :column,
          style: frame_style, **frame_opts) do
        box(css_class: 'panel-head', **head_opts) do
          box(css_class: 'dot', style: { background: accent })
          label(css_class: 'title', style: { font_weight: 600 }) { title }
          label(css_class: 'wclass') { subtitle }
          tools.call if tools
        end
        box(css_class: "panel-body #{body_class}".strip, direction: :column, **body_opts) do
          content.call if content
        end
        box(css_class: 'rs-handle', drag_resize: on_resize) if resizable && on_resize
      end
    end

    private

    def frame_style
      style = { position: 'absolute', left: "#{geometry['px']}px", top: "#{geometry['py']}px" }
      style[:width] = "#{geometry['pw']}px" if geometry['pw']
      style[:height] = "#{geometry['ph']}px" if geometry['ph']
      style[:z_index] = z_index if z_index
      style
    end
  end
end
