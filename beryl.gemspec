# frozen_string_literal: true

Gem::Specification.new do |spec|
  # RubyGems 上 beryl 之名已被他人占用（2018 年的 Web framework），发布名用 citrine-beryl；
  # require 名保持 'beryl'（lib/beryl.rb），消费者 gem 'citrine-beryl' + require 'beryl'
  spec.name = 'citrine-beryl'
  spec.version = '0.2.0'
  spec.authors = ['ShiningRay']
  spec.email = ['tsowly@hotmail.com']

  spec.summary = '桌面式 UI 组件库（Citrine 之上）'
  spec.description = 'Beryl：Citrine 信号内核之上的桌面式 UI 组件库——窗口框、窗口管理器、' \
                     '菜单、z 序、任务栏与控件目录。第一个消费者是 RubyWorld。'
  spec.homepage = 'https://github.com/ShiningRay/beryl'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7'

  spec.files = Dir['lib/**/*.rb', 'assets/*.css', 'docs/*.md', 'README.md', 'LICENSE']
  # citrine 尚未发布 gem：本地经 path / Opal -I 引用，发布后切换为正式依赖
  # spec.add_runtime_dependency 'citrine', '>= 0.1'

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
end
