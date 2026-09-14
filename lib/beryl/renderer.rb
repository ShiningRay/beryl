# frozen_string_literal: true

require 'native'
require 'citrine/dom'

module Beryl
  # L1 · 输入原语集：在 Citrine::DomRenderer 之上补齐桌面交互。
  # 每个原语以节点 prop 声明（与 on_click 同级）。
  class Renderer < Citrine::DomRenderer
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

    # 通用拖拽：drag_move / drag_resize——按住本节点拖动父面板；
    # 期间直接改 style（零重渲染），松手回调 {x, y, w, h}
    def setup_drag(node)
      move_handler = node.props[:drag_move]
      resize_handler = node.props[:drag_resize]
      handler = move_handler || resize_handler
      return unless handler

      el = node.dom
      pane = el[:parentElement]
      is_move = !move_handler.nil?
      doc = Native(`document`)

      el.addEventListener("mousedown", ->(raw) {
        ev = Native(raw) # Opal 传给 proc 的是裸 JS 事件，须包 Native 才能用 [:key] 访问
        next if ev[:button] != 0

        ev.preventDefault
        sx = ev[:clientX]
        sy = ev[:clientY]
        ol = pane[:offsetLeft]
        ot = pane[:offsetTop]
        ow = pane[:offsetWidth]
        oh = pane[:offsetHeight]
        on_move = nil
        on_up = ->(_raw2) {
          doc.removeEventListener("mousemove", on_move)
          doc.removeEventListener("mouseup", on_up)
          payload = Native(`({x: #{pane[:offsetLeft]}, y: #{pane[:offsetTop]}, w: #{pane[:offsetWidth]}, h: #{pane[:offsetHeight]}})`)
          node.owner.handle_event(handler, payload)
        }
        on_move = ->(raw2) {
          e2 = Native(raw2)
          dx = e2[:clientX] - sx
          dy = e2[:clientY] - sy
          if is_move
            pane[:style][:left] = "#{ol + dx}px"
            pane[:style][:top] = "#{ot + dy}px"
          else
            pane[:style][:width] = "#{[160, ow + dx].max}px"
            pane[:style][:height] = "#{[70, oh + dy].max}px"
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
  end
end
