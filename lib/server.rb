# Copyright (C) 2011 Marek Jelen
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'bundler/setup'

require 'amqp'
require 'yajl'
require 'yaml'
require 'logger'

module GitServer

  include EventMachine::Protocols::LineText2

  def receive_line(data)
    type, data = data.split("|", 2)
    case type
      when 'auth'
        username, repository, action = data.split("|", 3)
        send_data(Core.authorize(username, repository, action))
        close_connection_after_writing
      when 'push'
        user, commit, ref, repository = data.split("|", 4)
        message = { :user => user, :commit => commit, :ref => ref, :repository => repository }
        TOPIC.publish(Yajl::Encoder.encode(message), :routing_key => "manager", :type => "push")
    end
  end

end

class Core

  def self.configuration
    @configuration ||= YAML.load_file('/wc/config/git.yml')
  end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.setup
    @access = {}
    @keys = {}
  end

  setup

  def self.authorize(username, repository, action)
    return 0 unless @access[username] && @access[username].include?(repository)
    return 1
  end

  def self.handle(metadata, message)
    Core.logger.debug("(Core) Got message: #{message}")
    username = metadata.headers["username"] if metadata.headers
    message = Yajl::Parser.parse(message)
    case metadata.type
      when 'sync'
        @access = message["access"]
        @keys = message["keys"]
        self.sync_keys
      when 'key.add'
        (@keys[username] ||= []) << message["key"]
        self.sync_keys
      when 'key.remove'
        keys = @keys[username]
        if keys
          keys.delete(message["key"])
          self.sync_keys
        end
      when 'repository.create'
        `git init --bare #{File.join(Core.configuration["paths"]["repositories"], message["repository"])} --template #{File.expand_path("../../template", __FILE__)}`
      when 'repository.destroy'
        `rm -rf #{File.join(Core.configuration["paths"]["repositories"], message["repository"])}`
      when 'repository.authorize'
        (@access[username] ||= []) << message["repository"]
      when 'repository.unauthorize'
        repos = @access[username]
        repos.delete(message["repository"]) if repos
    end
  end

  def self.sync_keys
    Core.logger.info("(Core) Synchronizing data")
    data = ""
    @keys.each do |username, keys|
      keys.each do |key|
        data << "command=\"#{Core.configuration["paths"]["ruby"]} #{File.expand_path("../client.rb", __FILE__)} #{username}\" #{key}\n"
      end
    end
    File.open("./.ssh/authorized_keys", "w") do |file|
      file.write(data)
    end
    Core.logger.info("(Core) Data synchronized")
  end

  def self.start
    EventMachine.start_server(Core.configuration["paths"]["socket"], GitServer)
    @started = true
    Core.logger.info("(Core) Git server started")
  end

end

EventMachine.run do
  Core.logger.info("(AMQP) Connecting to broker")
  CONNECTION = AMQP.connect(Core.configuration["amqp"])
  CHANNEL = AMQP::Channel.new(CONNECTION)
  TOPIC = CHANNEL.topic('wildcloud.git')
  QUEUE = CHANNEL.queue("wildcloud.git.#{Core.configuration["node"]["name"]}").bind(TOPIC, :routing_key => "nodes").bind(TOPIC, :routing_key => "node.#{Core.configuration["node"]["name"]}")
  Core.logger.info("(Core) Requesting sync")
  TOPIC.publish(Core.configuration["node"]["name"], :routing_key => "manager", :type => "sync")
  QUEUE.subscribe do |metadata, message|
    Core.handle(metadata, message)
  end
  Core.logger.info("(Core) Starting git server")
  Core.start
end
