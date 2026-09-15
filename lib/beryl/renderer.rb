# backtick_javascript: true
# frozen_string_literal: true

require 'native'
require 'citrine/dom'
require_relative 'support'

module Beryl
  # L1 · 输入原语集：在 Citrine::DomRenderer 之上补齐桌面交互。
  # 每个原语以节点 prop 声明（与 on_click 同级），全部只在浏览器侧生效，
  # SSR（StringRenderer#setup_widget 为 no-op）自动忽略。
  class Renderer < Citrine::DomRenderer
    # Timer 后端注入：L2 的 Beryl::Timer 借此获得 setTimeout，自身保持纯 CRuby（F5）
    Beryl::Timer.backend = ->(ms, blk) { `setTimeout(#{blk.to_n}, #{ms})` }
    Beryl::Timer.cancel_backend = ->(handle) { `clearTimeout(#{handle})` }

    # DevTools 入口：抓住渲染树的根节点（VDOM 层）
    def mount_component(component, element)
      root = super
      @root_node = root
      root
    end

    def root_node
      @root_node
    end

    private

    def setup_widget(node)
      super
      setup_text_area(node) if node.type == :textarea
      setup_drag(node)
      setup_front(node)
      setup_menu(node)
      setup_hover(node)
      setup_dblclick(node)
      setup_wheel(node)
      setup_scroll(node)
      setup_tabindex(node)
      setup_autofocus(node)
      setup_tip(node)
      setup_data_drag(node)
      setup_auto_dismiss(node)
    end

    # 多行代码输入：value 双向绑定（Signal）；on_submit 在 Cmd/Ctrl+Enter 触发
    def setup_text_area(node)
      el = node.dom
      el[:spellcheck] = false
      signal = node.props[:value]
      if signal.is_a?(Citrine::Signal)
        node.owned_effects << Citrine::Effect.create { el[:value] = signal.get }
        el.addEventListener("input", ->(_event) { signal.set(el[:value]) })
      end
      submit = node.props[:on_submit]
      return unless submit

      el.addEventListener("keydown", ->(event) {
        ev = Native(event)
        if (ev[:metaKey] || ev[:ctrlKey]) && ev[:key] == "Enter"
          ev.preventDefault
          node.owner.handle_event(submit)
        end
      })
    end

    # 通用拖拽：drag_move / drag_resize——按住本节点拖动父面板（或 drag_pane
    # 选择器命中的祖先）；期间直接改 style（零重渲染），松手回调 {x, y, w, h}。
    # drag_dir: 八向缩放方位（n/e/s/w/ne/nw/se/sw，默认 se）；
    # drag_min: [w, h] 最小尺寸；drag_clamp: 拖动限制在视口内（留 60×30 可见）；
    # drag_scale: 世界缩放倍率（如 ZUI 相机 zoom，Numeric 或 callable，
    #   mousedown 时取值一次）——屏幕指针位移 ÷ scale 才等于布局位移。
    def setup_drag(node)
      move_handler = node.props[:drag_move]
      resize_handler = node.props[:drag_resize]
      handler = move_handler || resize_handler
      return unless handler

      el = node.dom
      sel = node.props[:drag_pane]
      pane = sel ? el.closest(sel) : nil
      pane = el[:parentElement] if pane.nil?
      is_move = !move_handler.nil?
      dir = node.props[:drag_dir] || 'se'
      min_w, min_h = node.props[:drag_min] || [160, 70]
      clamp_move = node.props[:drag_clamp] ? true : false
      drag_scale = node.props[:drag_scale]
      doc = Native(`document`)

      el.addEventListener("mousedown", ->(raw) {
        ev = Native(raw) # Opal 传给 proc 的是裸 JS 事件，须包 Native 才能用 [:key] 访问
        next if ev[:button] != 0

        ev.preventDefault
        sx = ev[:clientX]
        sy = ev[:clientY]
        # mousedown 时取值：手势期间冻结（与 sx/sy 同语义），支持传 callable 取动态 zoom
        scale = drag_scale.respond_to?(:call) ? drag_scale.call : drag_scale
        base = {
          left: pane[:offsetLeft], top: pane[:offsetTop],
          w: pane[:offsetWidth], h: pane[:offsetHeight],
        }
        viewport = { w: Native(`window`)[:innerWidth], h: Native(`window`)[:innerHeight] }
        moved = false   # 纯点击（未超过阈值）不算拖拽：mouseup 不回调，几何不回写
        sdx = 0         # 屏幕像素位移（相对手势起点；moved 阈值按屏幕口径判定）
        sdy = 0
        # 手势中途 view 可能重渲染并替换面板节点（如 mousedown 触发 on_front/focus），
        # 本监听器仍持有旧 pane——最终几何一律按「mousedown 基准 + 指针位移」纯数学
        # 计算（核心在 Beryl::DragGeometry，CRuby 可测），不读旧节点现状；
        # mousemove 的样式跟随在旧节点已脱离文档时自动跳过
        compute_geom = lambda {
          Beryl::DragGeometry.compute(base, sdx, sdy,
                                      scale: scale, move: is_move, dir: dir,
                                      min: [min_w, min_h], clamp: clamp_move,
                                      viewport: viewport)
        }
        on_move = nil
        on_up = ->(_raw2) {
          doc.removeEventListener("mousemove", on_move)
          doc.removeEventListener("mouseup", on_up)
          next unless moved

          g = compute_geom.call
          node.owner.handle_event(handler, { x: g[:left], y: g[:top], w: g[:w], h: g[:h] })
        }
        on_move = ->(raw2) {
          e2 = Native(raw2)
          sdx = e2[:clientX] - sx
          sdy = e2[:clientY] - sy
          moved = true if sdx.abs > 1 || sdy.abs > 1
          next unless pane[:isConnected]   # 旧面板已被重渲染替换：样式跟随降级，松手仍回写正确几何

          g = compute_geom.call
          if is_move
            pane[:style][:left] = "#{g[:left]}px"
            pane[:style][:top] = "#{g[:top]}px"
          else
            pane[:style][:width] = "#{g[:w]}px"
            pane[:style][:height] = "#{g[:h]}px"
            pane[:style][:left] = "#{g[:left]}px"
            pane[:style][:top] = "#{g[:top]}px"
          end
        }
        doc.addEventListener("mousemove", on_move)
        doc.addEventListener("mouseup", on_up)
      })
    end

    # 点击置顶：mousedown 即把节点提到最前；handler 收到节点自身 DOM 元素
    def setup_front(node)
      handler = node.props[:on_front]
      return unless handler

      node.dom.addEventListener("mousedown", ->(_raw) {
        node.owner.handle_event(handler, node.dom)
      })
    end

    # 右键菜单：contextmenu → preventDefault → handler 收到 Native 事件
    def setup_menu(node)
      handler = node.props[:on_menu]
      return unless handler

      node.dom.addEventListener("contextmenu", ->(raw) {
        ev = Native(raw)
        ev.preventDefault
        node.owner.handle_event(handler, ev)
      })
    end

    # 悬停：handler 收到 true（进入）/ false（离开）
    def setup_hover(node)
      handler = node.props[:on_hover]
      return unless handler

      el = node.dom
      el.addEventListener("mouseenter", ->(_raw) { node.owner.handle_event(handler, true) })
      el.addEventListener("mouseleave", ->(_raw) { node.owner.handle_event(handler, false) })
    end

    # 双击：handler 收到 Native 事件（标题栏双击最大化等）
    def setup_dblclick(node)
      handler = node.props[:on_dblclick]
      return unless handler

      node.dom.addEventListener("dblclick", ->(raw) {
        node.owner.handle_event(handler, Native(raw))
      })
    end

    # 滚轮：handler 收到 {delta_x, delta_y}（不 preventDefault，页面滚动照常）
    def setup_wheel(node)
      handler = node.props[:on_wheel]
      return unless handler

      node.dom.addEventListener("wheel", ->(raw) {
        ev = Native(raw)
        payload = Native(`({delta_x: #{ev[:deltaX]}, delta_y: #{ev[:deltaY]}})`)
        node.owner.handle_event(handler, payload)
      })
    end

    # 滚动：handler 收到 {top, left}（List 虚拟滚动用）
    def setup_scroll(node)
      handler = node.props[:on_scroll]
      return unless handler

      el = node.dom
      el.addEventListener("scroll", ->(_raw) {
        payload = Native(`({top: #{el[:scrollTop]}, left: #{el[:scrollLeft]}})`)
        node.owner.handle_event(handler, payload)
      })
    end

    # tabindex / autofocus：让容器参与焦点链（Menu 键盘导航的前提）
    def setup_tabindex(node)
      idx = node.props[:tabindex]
      return unless idx

      node.dom[:tabIndex] = idx
    end

    def setup_autofocus(node)
      return unless node.props[:autofocus]

      node.dom.focus
    end

    # 原生 tooltip：mouseenter 时挂一个 .b-tip 到 body，mouseleave 移除
    # tooltip（L1 tip 原语）：mouseenter 挂气泡、mouseleave 摘除。
    # 气泡是 body 上的 fixed 元素——**节点在悬停中被卸载/重渲时（关窗、形态
    # 切换、响应式重跑）mouseleave 不会触发**，气泡永久留在屏幕上（实测
    # 「关掉窗口后 tip 到处都在」）。两道保险：
    #   ① 回收挂进 node.owned_effects 的 cleanup——节点销毁时随 Effect
    #      dispose 执行（Renderer#dispose → owned_effects 逐个 dispose）；
    #   ② 挂新气泡前先清扫全部残留 .b-tip（同刻只应存在一个提示）。
    def setup_tip(node)
      tip = node.props[:tip]
      return unless tip

      el = node.dom
      doc = Native(`document`)
      tip_el = nil
      node.owned_effects << Citrine::Effect.create(track_cleanup: true) {
        -> { tip_el.remove if tip_el; tip_el = nil }
      }
      el.addEventListener("mouseenter", ->(_raw) {
        r = el.getBoundingClientRect
        Native(`document.querySelectorAll('.b-tip').forEach(function(e){e.remove()})`) # ②
        div = doc.createElement("div")
        div[:className] = "b-tip"
        div[:textContent] = tip.to_s
        div[:style][:left] = "#{r[:left] > 4 ? r[:left] : 4}px"
        div[:style][:top] = "#{r[:bottom] + 6}px"
        doc[:body].appendChild(div)
        tip_el = div
      })
      el.addEventListener("mouseleave", ->(_raw) {
        tip_el.remove if tip_el
        tip_el = nil
      })
    end

    # 数据拖放：drag_payload 使节点可拖（dragstart 时存入 DragBus）；
    # on_drop 的 handler 在 drop 时收到 DragBus.take（同文档内任意 Ruby 对象）
    def setup_data_drag(node)
      payload = node.props[:drag_payload]
      drop_handler = node.props[:on_drop]
      return unless payload || drop_handler

      el = node.dom
      if payload
        el[:draggable] = true
        el.addEventListener("dragstart", ->(_raw) { Beryl::DragBus.current = payload })
      end
      return unless drop_handler

      el.addEventListener("dragover", ->(raw) { Native(raw).preventDefault })
      el.addEventListener("drop", ->(raw) {
        ev = Native(raw)
        ev.preventDefault
        node.owner.handle_event(drop_handler, Beryl::DragBus.take)
      })
    end

    # 自动消失（Toast 等）：auto_dismiss 毫秒后触发 on_dismiss；
    # 节点已脱离文档则忽略（组件卸载后定时器不再打扰）
    def setup_auto_dismiss(node)
      ms = node.props[:auto_dismiss]
      handler = node.props[:on_dismiss]
      return unless ms && handler

      el = node.dom
      Beryl::Timer.after(ms) {
        next unless el[:isConnected]

        node.owner.handle_event(handler)
      }
    end
  end
end
