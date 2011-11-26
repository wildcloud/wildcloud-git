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

# Libraries
require "socket"

# Somehow merge with ../../git/configuration.rb
require 'yaml'
module Wildcloud
  module Git
    def self.configuration
      return @configuration if @configuration
      file = '/etc/wildcloud/git.yml'
      unless File.exists?(file)
        file = './git.yml'
      end
      @configuration = YAML.load_file(file)
    end
  end
end

# Constants
repositories = Wildcloud::Git.configuration["paths"]["repositories"]
user = ENV["GIT_USERNAME"]
socket = UNIXSocket.new(Wildcloud::Git.configuration["paths"]["socket"])

# One line per ref
$stdin.each_line do |line|
  from, to, ref = line.split(" ")
  ref.sub!("refs/heads/", "")
  repo = File.expand_path(".").sub(repositories, "")
  socket.write("push|#{user}|#{to}|#{ref}|#{repo}\n")
end

socket.close
