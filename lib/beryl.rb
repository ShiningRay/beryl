# frozen_string_literal: true

# Beryl — Citrine 之上的桌面式 UI 组件库。
# 分层与库法则见 docs/PLAN.md。
#
# 控件层（menu/form/tabs/dialog/feedback/display/window）纯 CRuby 可测；
# renderer 依赖 Opal 环境（citrine/dom + native），仅在浏览器侧加载，
# 并为 Beryl::Timer 注入 setTimeout 后端。
require 'citrine'
require_relative 'beryl/support'
require_relative 'beryl/button'
require_relative 'beryl/overlay'
require_relative 'beryl/menu'
require_relative 'beryl/form'
require_relative 'beryl/tabs'
require_relative 'beryl/dialog'
require_relative 'beryl/feedback'
require_relative 'beryl/display'
require_relative 'beryl/window'
require_relative 'beryl/renderer' if defined?(Opal)
