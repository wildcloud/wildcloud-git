#!/usr/bin/env ruby
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
        @command = /^git-(upload|receive)-pack '([^']*)'$/.match(ENV["SSH_ORIGINAL_COMMAND"])
        message(:error, 'Invalid command.') unless @command
      end

      def parse_information
        @repositories = Git.configuration["paths"]["repositories"]
        @action = @command[1]
        @repository = @command[2]
        @user = ARGV[0]
      end

      def setup_environment
        ENV["GIT_USERNAME"] = @user
      end

      def authorize
        socket = UNIXSocket.new(Git.configuration["paths"]["socket"])
        socket.write("auth|#{@user}|#{@repository}|#{@action}\n")
        unless socket.getc.to_s == "1"
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

if $0 == __FILE__
  $: << File.expand_path('../../..', __FILE__)
  require 'wildcloud/git/configuration'
  git = Wildcloud::Git::Client.new
  git.check_command
  git.parse_information
  git.setup_environment
  git.authorize
  git.run_git
end
