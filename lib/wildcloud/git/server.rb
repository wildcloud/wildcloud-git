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

require 'amqp'
require 'yajl'

require 'wildcloud/git/configuration'
require 'wildcloud/git/logger'
require 'wildcloud/git/core'
require 'wildcloud/git/protocol'

module Wildcloud
  module Git
    class Server

      def self.start
        Git.logger.info('(Server) Starting')
        @core = Wildcloud::Git::Core.new
        EventMachine.start_server(Git.configuration['paths']['socket'], Wildcloud::Git::Protocol, @core)
        Git.logger.info('(Server) Started')
      end

    end
  end
end
