# frozen_string_literal: true

# Beryl — Citrine 之上的桌面式 UI 组件库。
# 分层与库法则见 docs/PLAN.md。
#
# 控件层（widgets/window）纯 CRuby 可测；renderer 依赖 Opal 环境
# （citrine/dom + native），仅在浏览器侧加载。
require 'citrine'
require_relative 'beryl/widgets'
require_relative 'beryl/window'
require_relative 'beryl/renderer' if defined?(Opal)
