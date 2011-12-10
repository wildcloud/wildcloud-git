require 'eventmachine'
require 'wildcloud/git/protocol'

class MockHandler

  include Wildcloud::Git::Protocol

  def initialize(core)
    super(core)
    reset
  end

  def reset
    @data = ""
    @closed = false
  end

  def closed
    @closed
  end

  def data
    @data
  end

  def close_connection_after_writing
    @closed = true
  end

  def send_data(data)
    @data << data
  end

end

class MockCore

  def initialize
    reset
  end

  def reset
    @message = nil
  end

  def message
    @message
  end

  def authorize(username, repository, action)
    case username
      when 'user'
        '0'
      when 'user2'
        '1'
    end
  end

  def publish(message)
    @message = message
  end
end

describe Wildcloud::Git::Protocol do

  describe 'when auth request received' do
    it 'must unauthenticate' do
      @core = MockCore.new
      @handler = MockHandler.new(@core)
      @handler.receive_line('auth|user|repo|action')
      @handler.data.must_equal("0")
      @handler.closed.must_equal(true)
    end
    it 'must authenticate' do
      @core = MockCore.new
      @handler = MockHandler.new(@core)
      @handler.receive_line('auth|user2|repo|action')
      @handler.data.must_equal("1")
      @handler.closed.must_equal(true)
    end
  end

  describe 'when push request received' do
    it 'must publish message' do
      @core = MockCore.new
      @handler = MockHandler.new(@core)
      @handler.receive_line('push|user|commit|ref|repo')
      @core.message.must_equal({ :type => 'push', :user => 'user', :commit => 'commit', :ref => 'ref', :repository => 'repo' })
    end
  end

end
