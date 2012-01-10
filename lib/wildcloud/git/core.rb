# Copyright 2011 Marek Jelen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'wildcloud/git/configuration'
require 'wildcloud/git/logger'

require 'amqp'
require 'json'

module Wildcloud
  module Git
    class Core

      def initialize
        Git.logger.info('Core', 'Starting')

        # Define basic variables
        @access = {}
        @keys = {}

        # Connect to AMQP
        Git.logger.info('Core', 'Connecting to broker')
        @amqp = AMQP.connect(Git.configuration['amqp'])
        Git.logger_add_amqp(@amqp)

        # Communication infrastructure
        @channel = AMQP::Channel.new(@amqp)
        @topic = @channel.topic('wildcloud.git')
        @queue = @channel.queue("wildcloud.git.#{Git.configuration['node']['name']}")
        @queue.bind(@topic, :routing_key => 'nodes')
        @queue.bind(@topic, :routing_key => "node.#{Git.configuration['node']['name']}")

        # Request synchronization
        Git.logger.info('Core', 'Requesting synchronization')
        publish({ :node => Git.configuration['node']['name'], :type => :sync })

        # Listen for task
        @queue.subscribe do |metadata, message|
          handle(metadata, message)
        end
      end

      def authorize(username, repository, action)
        return 1 if username == 'wildcloud.platform.master.key'
        return 0 unless @access[username] && @access[username].include?(repository)
        1
      end

      def handle(metadata, message)
        Git.logger.debug('Core', "Got message: #{message}")
        message = JSON.parse(message)
        method = "handle_#{message['type']}".to_sym
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

      def handle_add_platform_key(data)
        @platform_keys ||= []
        @platform_keys << data['key'] unless @platform_keys.include?(data['key'])
        sync_keys
      end

      def handle_remove_platform_key(data)
        (@platform_keys ||= []).delete(data['key'])
        sync_keys
      end

      def handle_create_repository(data)
        path = File.join(Git.configuration['paths']['repositories'], data['repository'])
        `git init --bare #{path} --template #{File.expand_path('../../template', __FILE__)}`
        pre_receive = File.read(File.expand_path('../pre-receive.rb', __FILE__))
        pre_receive = "#!#{Git.configuration['paths']['ruby']}\n#{pre_receive}"
        hook_path = File.join(path, 'hooks', 'pre-receive')
        File.open(hook_path, 'w') do |file|
          file.write(pre_receive)
        end
        File.chmod(0700, hook_path)
      end

      def handle_destroy_repository(data)
        `rm -rf #{File.join(Git.configuration['paths']['repositories'], data['repository'])}`
      end

      def handle_authorize_repository(data)
        (@access[data['username']] ||= []) << data['repository']
      end

      def handle_unauthorize_repository(data)
        repos = @access[data['username']]
        repos.delete(data['repository']) if repos
      end

      def sync_keys
        Git.logger.info('Core', 'Synchronizing keys')
        data = ""
        client = File.expand_path('../client.rb', __FILE__)
        ks = us = 0
        @platform_keys.each do |key|
          data << "command=\"source /etc/profile && wildcloud-git-client 'wildcloud.platform.master.key'\" #{key}\n"
        end if @platform_keys
        @keys.each do |username, keys|
          us += 1
          keys.each do |key|
            data << "command=\"source /etc/profile && wildcloud-git-client #{username}\" #{key}\n"
            ks += 1
          end
        end if @keys
        File.open('./.ssh/authorized_keys', 'w') do |file|
          file.write(data)
        end
        Git.logger.info('Core', "Data synchronized (#{us} users, #{ks} keys)")
      end

      def publish(message)
        Git.logger.debug('Core', "Publishing #{message.inspect}")
        @topic.publish(JSON.dump(message), :routing_key => 'master')
      end

    end
  end
end

