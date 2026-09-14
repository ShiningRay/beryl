# frozen_string_literal: true

require 'rake/testtask'

CITRINE = ENV.fetch('CITRINE_PATH', '../citrine')

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib' << File.join(CITRINE, 'lib')
  t.test_files = FileList['test/**/*_test.rb']
end

desc 'Opal 编译验收：demo 页可编译（renderer/DSL 的浏览器侧语法门）'
task :compile do
  sh "bundle exec opal -c -I#{File.join(CITRINE, 'lib')} -Ilib -o examples/demo.js examples/demo.rb"
end

task default: %i[test compile]
