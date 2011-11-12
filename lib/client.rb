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
require 'yaml'

CONFIG = YAML.load_file('/wc/config/git.yml')

# Message helper
def message(level, message)
  $stderr << "#{level.to_s.upcase}: #{message}\n"
  exit(1) if [:error].include?(level)
end

# Was the right command issued?
cmd = /^git-(upload|receive)-pack '([^']*)'$/.match(ENV["SSH_ORIGINAL_COMMAND"])
unless cmd
  message(:error, 'Invalid command.')
end

# Information
REPOS = CONFIG["paths"]["repositories"]
ACTION = cmd[1]
REPO = cmd[2]
USER = ARGV[0]

# Authorize
socket = UNIXSocket.new(CONFIG["paths"]["socket"])
socket.write("#{USER}|#{REPO}|#{ACTION}")
unless socket.getc.to_s == "1"
  message(:error, 'Invalid authorization.')
end

# Pass to Git
path = File.join(REPOS, REPO)
unless File.exists?(path)
  message(:error, 'Invalid repository.')
end
exec("git #{ACTION}-pack #{path}")
