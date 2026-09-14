# frozen_string_literal: true

source 'https://rubygems.org'

gemspec
# citrine 未发 gem：本地/CI 经 path 引用。CI 用 CITRINE_PATH 指向 checkout 的兄弟目录
gem 'citrine', path: ENV.fetch('CITRINE_PATH', '../citrine')

# Opal 编译验收（rake compile）在本地与 CI 都要能用
gem 'opal', '~> 1.8', require: false
