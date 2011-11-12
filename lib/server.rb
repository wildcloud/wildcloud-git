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

CONFIG = YAML.load_file('/wc/config/git.yml')

module GitServer

  include EventMachine::Protocols::LineText2

  def receive_line(data)
    type, username, repository, action = data.split("|", 4)
    case type
      when 'auth'
        send_data(Core.authorize(username, repository, action))
    end
    close_connection_after_writing
  end

end

class Core

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
        `git init --bare #{File.join(CONFIG["paths"]["repositories"], message["repository"])} --template #{CONFIG["paths"]["repository.template"]}`
     when 'repository.authorize'
        (@access[username] ||= []) << message["repository"]
      when 'repository.unauthorize'
        repos = @access[username]
        repos.delete(message["repository"]) if repos
    end
  end

  def self.sync_keys
    data = ""
    @keys.each do |username, keys|
      keys.each do |key|
        data << "command=\"#{CONFIG["paths"]["ruby"]} #{File.expand_path("../client.rb", __FILE__)} #{username}\" #{key}\n"
      end
    end
    File.open("./.ssh/authorized_keys", "w") do |file|
      file.write(data)
    end
  end

  def self.start
    EventMachine.start_server(CONFIG["paths"]["socket"], GitServer)
    @started = true
  end

end

EventMachine.run do
  CONNECTION = AMQP.connect(CONFIG["amqp"])
  CHANNEL = AMQP::Channel.new(CONNECTION)
  TOPIC = CHANNEL.topic('wildcloud.git')
  QUEUE = CHANNEL.queue("wildcloud.git.#{CONFIG["node"]["name"]}").bind(TOPIC, :routing_key => "nodes").bind(TOPIC, :routing_key => "node.#{CONFIG["node"]["name"]}")
  TOPIC.publish(CONFIG["node"]["name"], :routing_key => "manager", :type => "sync")
  QUEUE.subscribe do |metadata, message|
    Core.handle(metadata, message)
  end
  Core.start
end
