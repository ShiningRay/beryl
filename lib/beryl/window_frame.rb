# frozen_string_literal: true

module Beryl
  class WindowFrame < Citrine::Component
    prop :title, type: String, default: ''
    prop :subtitle, type: String, default: ''
    prop :accent, type: String, default: '#4f8cff'
    prop :css_class, type: String, default: ''
    prop :body_class, type: String, default: ''
    prop :geometry         # { 'px' =>, 'py' =>, 'pw' =>?, 'ph' =>? }
    prop :z_index
    prop :resizable, default: true
    prop :min_w, type: Numeric, default: 160
    prop :min_h, type: Numeric, default: 70
    prop :drag_scale         # 世界缩放倍率（ZUI 相机 zoom，Numeric 或 callable），
                             # 透传拖拽/缩放手柄：屏幕位移 ÷ drag_scale = 布局位移
    prop :active, default: nil          # true/false/nil（nil 保持旧外观）
    prop :minimized, default: false     # true 时整个窗口不渲染
    prop :maximized, default: false     # 最大化态：□ 控制钮变还原图标 ⧉（由 WindowManager 注入）
    prop :closable, default: false
    prop :minimizable, default: false
    prop :maximizable, default: false
    prop :on_move          # ->(ev{ x, y, w, h })
    prop :on_resize        # ->(ev{ x, y, w, h })
    prop :on_front         # ->(el)
    prop :on_menu          # ->(ev) 右键标题栏
    prop :on_head_click    # ->(ev) 左键标题栏
    prop :on_head_dblclick # ->(ev) 双击标题栏（最大化切换由 WindowManager 接线）
    prop :on_close
    prop :on_minimize
    prop :on_maximize
    prop :on_body_click
    prop :content          # Proc 插槽：主体内容
    prop :tools            # Proc 插槽：标题栏尾部（如自定义按钮）
    prop :shape, default: nil  # 异形窗口：clip-path 值（'polygon(...)'/'circle(50%)' 等）。
                               # 设置后结构变为 .panel-wrap（定位/z 序/drop-shadow 阴影）
                               # 包 .panel（clip-path 裁剪）——box-shadow 会被 clip-path
                               # 裁掉，阴影必须由包裹层的 filter 承担（跟随裁剪轮廓）；
                               # 拖拽/缩放手柄经 drag_pane 改投包裹层，几何仍是矩形包围盒

    RESIZE_DIRS = %w[n e s w ne nw se sw].freeze

    def view
      return if minimized

      # 异形：外包 .panel-wrap（定位/z 序/阴影），.panel 在包裹层 block 内部 emit——
      # 先建节点再塞 block 会让节点 emit 两次，第二次以 to_s 文本泄漏（F 系踩坑同款）
      if shape
        box(css_class: "panel-wrap #{css_class}".strip, style: wrap_style,
            **{ on_front: on_front }.compact) do
          emit_panel('.panel-wrap', {})
          nil # 块返回值不外泄（emit_panel 返回 Node，泄漏会被渲染成可见文本）
        end
      else
        emit_panel(nil, { on_front: on_front }.compact)
      end
    end

    # .panel 本体：标题栏 + 内容插槽 + 缩放手柄。必须在最终父节点的 block 内
    # 调用（DSL 按动态上下文 emit）；pane 非 nil 时拖拽/缩放改投该选择器祖先
    def emit_panel(pane, frame_opts)
      head_opts = {
        drag_move: on_move, on_menu: on_menu, on_click: on_head_click,
        on_dblclick: on_head_dblclick, drag_scale: drag_scale, drag_pane: pane,
      }.compact
      body_opts = { on_click: on_body_click }.compact

      # 类名沿用应用侧既有 CSS（panel/panel-head/...）；b- 前缀 token 化在 M5 主题系统时统一迁移
      box(css_class: frame_class, direction: :column,
          style: pane ? shaped_panel_style : frame_style, **frame_opts) do
        box(css_class: 'panel-head', **head_opts) do
          box(css_class: 'dot', style: { background: accent })
          label(css_class: 'title', style: { font_weight: 600 }) { title }
          # 弹簧：把尾部（副标题/工具/控制钮）推到右侧——不依赖副标题的 auto margin，
          # 没有副标题时按钮也保持在右端（激活态样式更不能动布局）
          box(style: { flex: 1 })
          label(css_class: 'wclass') { subtitle } unless subtitle.empty?
          tools.call if tools
          render_controls
        end
        box(css_class: "panel-body #{body_class}".strip, direction: :column, **body_opts) do
          content.call if content
        end
        render_handles(pane)
      end
    end

    def frame_class
      cls = "panel #{css_class}".strip
      cls += ' is-active' if active == true
      cls += ' is-inactive' if active == false
      cls
    end

    def render_controls
      return unless closable || minimizable || maximizable

      row(css_class: 'b-win-controls', gap: 4) do
        if minimizable
          box(css_class: 'b-win-btn', tip: '最小化',
              on_click: ->(e) { e.stop_propagation; on_minimize&.call }) { '−' }
        end
        if maximizable
          # 最大化态按钮变还原图标（⧉），tooltip 同步——切换入口就是同一颗按钮
          box(css_class: maximized ? 'b-win-btn is-maximized' : 'b-win-btn',
              tip: maximized ? '还原' : '最大化',
              on_click: ->(e) { e.stop_propagation; on_maximize&.call }) do
            maximized ? '⧉' : '□'
          end
        end
        if closable
          box(css_class: 'b-win-btn', tip: '关闭',
              on_click: ->(e) { e.stop_propagation; on_close&.call }) { '✕' }
        end
      end
    end

    def render_handles(pane = nil)
      return unless resizable && on_resize

      RESIZE_DIRS.each do |d|
        box(**{ css_class: "rs-handle rs-#{d}",
                drag_resize: on_resize, drag_dir: d,
                drag_min: [min_w, min_h], drag_scale: drag_scale,
                drag_pane: pane }.compact)
      end
    end

    private

    # 异形窗口的阴影：box-shadow 画矩形外框且被 clip-path 裁掉，
    # 包裹层用 drop-shadow 滤镜——跟随裁剪后的轮廓
    def wrap_style
      frame_style.merge(filter: 'drop-shadow(0 12px 28px rgba(0,0,0,.35))')
    end

    # 异形模式的内层 .panel：铺满包裹层，裁剪只作用于它
    def shaped_panel_style
      { clip_path: shape, width: '100%', height: '100%' }
    end

    def frame_style
      style = { position: 'absolute', left: "#{geometry['px']}px", top: "#{geometry['py']}px" }
      style[:width] = "#{geometry['pw']}px" if geometry['pw']
      style[:height] = "#{geometry['ph']}px" if geometry['ph']
      style[:z_index] = z_index if z_index
      style
    end
  end
end
