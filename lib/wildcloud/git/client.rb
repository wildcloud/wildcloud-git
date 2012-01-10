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

require 'socket'

module Wildcloud
  module Git
    class Client

      def initialize
      end

      # Message helper
      def message(level, message)
        $stderr << "#{level.to_s.upcase}: #{message}\n"
        exit(1) if [:error].include?(level)
      end

      # Was the right command issued?
      def check_command
        @command = /^git-(upload|receive)-pack '([^']*)'$/.match(ENV['SSH_ORIGINAL_COMMAND'])
        message(:error, 'Invalid command.') unless @command
      end

      def parse_information
        message(:info, 'Parsing request')
        @repositories = Git.configuration['paths']['repositories']
        @action = @command[1]
        @repository = @command[2]
        @user = ARGV[0]
      end

      def setup_environment
        message(:info, 'Setting up environment')
        ENV['GIT_USERNAME'] = @user
      end

      def authorize
        message(:info, 'Checking authorization')
        socket = UNIXSocket.new(Git.configuration['paths']['socket'])
        socket.write("auth|#{@user}|#{@repository}|#{@action}\n")
        unless socket.getc.to_s == '1'
          message(:error, 'Invalid authorization.')
        end
        socket.close
      end

      def run_git
        path = File.join(@repositories, @repository)
        unless File.exists?(path)
          message(:error, 'Invalid repository.')
        end
        exec("git #{@action}-pack #{path}")
      end

    end
  end
end