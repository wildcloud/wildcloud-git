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

require 'amqp'
require 'json'

require 'wildcloud/git/configuration'
require 'wildcloud/git/logger'
require 'wildcloud/git/core'
require 'wildcloud/git/protocol'

module Wildcloud
  module Git
    class Server

      def self.start
        Git.logger.info('Server', 'Starting')
        @core = Wildcloud::Git::Core.new
        EventMachine.start_server(Git.configuration['paths']['socket'], Wildcloud::Git::Protocol, @core)
        Git.logger.info('Server', 'Started')
      end

    end
  end
end
