# Beryl 组件演示（浏览器）
# 运行：在 citrine 仓库执行 bin/citrine dev <本目录绝对路径>
require_relative '../lib/beryl'
require 'citrine/browser'

class Demo < Citrine::Component
  state :menu, default: nil
  state :toast, default: nil

  def view
    Beryl::WindowFrame.new(
      title: 'Beryl Demo',
      subtitle: 'WindowFrame + Menu + Toast',
      geometry: { 'px' => 40, 'py' => 40, 'pw' => 420, 'ph' => 200 },
      on_move: ->(_ev) {},
      on_menu: ->(ev) { self.menu = { 'x' => ev[:clientX], 'y' => ev[:clientY] } },
      content: -> {
        box(direction: :column, gap: 10, style: { padding: '12px' }) do
          label { '右键标题栏弹菜单；点按钮出 toast' }
          button(on_click: :fire_toast) { 'Toast!' }
        end
      },
    ).view
    Beryl::Menu.new(items: [{ 'label' => '打个招呼', 'action' => -> { fire_toast } }],
                    x: menu && menu['x'] || 0, y: menu && menu['y'] || 0,
                    on_close: -> { self.menu = nil }).view if menu
    Beryl::Toast.new(data: toast).view if toast
  end

  def fire_toast
    self.toast = { 'msg' => 'hello from beryl', 'kind' => 'info' }
  end
end

Beryl::Renderer.mount_at('app', Demo.new)
