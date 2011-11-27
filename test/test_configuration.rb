require 'wildcloud/git/configuration'

class TestConfiguration < MiniTest::Unit::TestCase

  def test_configuration
    assert Wildcloud::Git.configuration.kind_of?(Hash)
  end

end
