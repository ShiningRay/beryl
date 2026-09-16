# frozen_string_literal: true

# Beryl — Citrine 之上的桌面式 UI 组件库。
# 分层与库法则见 docs/PLAN.md；一个组件一个文件（snake_case 对应类名）。
#
# 控件层全部纯 CRuby 可测；renderer 依赖 Opal 环境（citrine/dom + native），
# 仅在浏览器侧加载，并为 Beryl::Timer 注入 setTimeout 后端。
require 'citrine'
require_relative 'beryl/support'
require_relative 'beryl/overlay'       # Overlay 定位算法（纯几何）

# ── 动作 ──────────────────────────────────────────────
require_relative 'beryl/button'
require_relative 'beryl/button_group'

# ── 浮层 ──────────────────────────────────────────────
require_relative 'beryl/popover'
require_relative 'beryl/tooltip'

# ── 菜单 ──────────────────────────────────────────────
require_relative 'beryl/menu'
require_relative 'beryl/menu_bar'      # 依赖 Beryl::Menu（运行期）

# ── 表单 ──────────────────────────────────────────────
require_relative 'beryl/select'
require_relative 'beryl/multi_select'
require_relative 'beryl/radio_group'
require_relative 'beryl/switch'
require_relative 'beryl/slider'
require_relative 'beryl/number_input'
require_relative 'beryl/search_input'
require_relative 'beryl/input'
require_relative 'beryl/checkbox'
require_relative 'beryl/checkbox_group'
require_relative 'beryl/combobox'
require_relative 'beryl/color_picker'
require_relative 'beryl/date_picker'
require_relative 'beryl/field'
require_relative 'beryl/form'          # 依赖 Beryl::Button（运行期）

# ── 导航与展示 ────────────────────────────────────────
require_relative 'beryl/tabs'
require_relative 'beryl/accordion'
require_relative 'beryl/table'
require_relative 'beryl/list'
require_relative 'beryl/tree'
require_relative 'beryl/kv'
require_relative 'beryl/breadcrumb'
require_relative 'beryl/pagination'
require_relative 'beryl/divider'
require_relative 'beryl/toolbar'
require_relative 'beryl/status_bar'
require_relative 'beryl/icon'

# ── 反馈与弹层 ────────────────────────────────────────
require_relative 'beryl/dialog'
require_relative 'beryl/alert'         # < Dialog
require_relative 'beryl/confirm'       # < Dialog
require_relative 'beryl/prompt'        # < Dialog
require_relative 'beryl/toast'
require_relative 'beryl/notification'
require_relative 'beryl/progress'
require_relative 'beryl/spinner'
require_relative 'beryl/badge'
require_relative 'beryl/tag'
require_relative 'beryl/empty_state'

# ── 桌面外壳 ──────────────────────────────────────────
require_relative 'beryl/window_frame'
require_relative 'beryl/window_manager'
require_relative 'beryl/taskbar'

require_relative 'beryl/renderer' if defined?(Opal)
