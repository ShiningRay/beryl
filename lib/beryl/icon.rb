# frozen_string_literal: true

module Beryl
  # 最小图标集：unicode 字形映射（资产嵌入方案等 M5 主题系统再定）
  module Icon
    GLYPHS = {
      close: '✕', plus: '+', minus: '−', check: '✓',
      caret_right: '▸', caret_down: '▾', chevron_left: '‹', chevron_right: '›',
      search: '🔍', folder: '▤', file: '▢', gear: '⚙', star: '★', dot: '•',
    }.freeze

    def self.[](name)
      GLYPHS[name] || name.to_s
    end
  end
end
