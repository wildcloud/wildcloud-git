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

require 'wildcloud/logger'
require 'wildcloud/logger/middleware/console'
require 'wildcloud/logger/middleware/amqp'
require 'wildcloud/logger/middleware/json'

require 'wildcloud/git/configuration'

module Wildcloud
  module Git

    def self.logger
      return @logger if @logger
      @logger = Wildcloud::Logger::Logger.new
      @logger.application = ['wildcloud', 'git', self.configuration['node']['name']].join('.')
      @logger.level = self.configuration['logger']['level'].to_s.to_sym if self.configuration['logger'] && self.configuration['logger']['level']
      @logger.add(Wildcloud::Logger::Middleware::Console)
      @logger
    end

    def self.logger_add_amqp(amqp)
      @logger.add(Wildcloud::Logger::Middleware::Json)
      @logger.add(Wildcloud::Logger::Middleware::Amqp,
                  :exchange => AMQP::Channel.new(amqp).topic('wildcloud.logger'),
                  :routing_key => proc { |message| message[:application] }
      )
    end

  end
end
