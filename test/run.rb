require 'minitest/unit'
require 'minitest/spec'
require 'minitest/mock'

require 'bundler/setup'

$: << File.expand_path('../../lib', __FILE__)

Dir.glob(File.join(File.expand_path("..", __FILE__), 'test_*.rb')) do |test|
  require test
end

MiniTest::Unit.autorun
