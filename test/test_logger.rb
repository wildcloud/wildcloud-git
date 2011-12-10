require 'wildcloud/git/logger'

class TestLogger < MiniTest::Unit::TestCase

  def test_logger
    assert Wildcloud::Git.logger.respond_to?(:info)
  end

end
