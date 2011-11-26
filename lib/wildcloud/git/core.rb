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

require 'wildcloud/git/configuration'
require 'wildcloud/git/logger'

require 'yajl'
require 'amqp'

module Wildcloud
  module Git
    class Core

      def initialize
        Git.logger.info("(Core) Starting")

        # Define basic variables
        @access = {}
        @keys = {}

        # Connect to AMQP
        Git.logger.info("(Core) Connecting to broker")
        @amqp = AMQP.connect(Git.configuration["amqp"])
        @channel = AMQP::Channel.new(@amqp)

        # Communication infrastructure
        @topic = @channel.topic('wildcloud.git')
        @queue = @channel.queue("wildcloud.git.#{Git.configuration["node"]["name"]}")
        @queue.bind(@topic, :routing_key => "nodes")
        @queue.bind(@topic, :routing_key => "node.#{Git.configuration["node"]["name"]}")

        # Request synchronization
        Git.logger.info("(Core) Requesting synchronization")
        @topic.publish(Yajl::Encoder.encode({ :node => Git.configuration["node"]["name"], :type => :sync }), :routing_key => "manager")

        # Listen for task
        @queue.subscribe do |metadata, message|
          handle(metadata, message)
        end
      end

      def authorize(username, repository, action)
        return 0 unless @access[username] && @access[username].include?(repository)
        return 1
      end

      def handle(metadata, message)
        Git.logger.debug("(Core) Got message: #{message}")
        message = Yajl::Parser.parse(message)
        method = "handle_#{message["type"]}".to_sym
        if respond_to?(method)
          send(method, message)
        else

        end
      end

      def handle_sync(data)
        @access = data['access']
        @keys = data['keys']
        sync_keys
      end

      def handle_add_key(data)
        (@keys[data['username']] ||= []) << data['key']
        sync_keys
      end

      def handle_remove_key(data)
        keys = @keys[data['username']]
        if keys
          keys.delete(data['key'])
          sync_keys
        end
      end

      def handle_create_repository(data)
        `git init --bare #{File.join(Git.configuration['paths']['repositories'], data['repository'])} --template #{File.expand_path('../../template', __FILE__)}`
      end

      def handle_destroy_repository(data)
        `rm -rf #{File.join(Git.configuration['paths']['repositories'], data['repository'])}`
      end

      def handle_authorize_repository(data)
        (@access[data['username']] ||= []) << data['epository']
      end

      def handle_unauthorize_repository(data)
        repos = @access[data['username']]
        repos.delete(data['repository']) if repos
      end

      def sync_keys
        Git.logger.info("(Core) Synchronizing keys")
        data = ""
        client = File.expand_path("../client.rb", __FILE__)
        ks = us = 0
        @keys.each do |username, keys|
          us += 1
          keys.each do |key|
            data << "command=\"#{Core.configuration["paths"]["ruby"]} #{client} #{username}\" #{key}\n"
            ks += 1
          end
        end
        File.open("./.ssh/authorized_keys", "w") do |file|
          file.write(data)
        end
        Core.logger.info("(Core) Data synchronized (#{us} users, #{ks} keys)")
      end

    end
  end
end

