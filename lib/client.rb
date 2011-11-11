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

# Authenticate
socket = UNIXSocket.new(CONFIG["paths"]["socket"])
socket.write("#{USER}|#{REPO}|#{ACTION}")
unless socket.getc.to_s == "1"
  message(:error, 'Invalid authentication.')
end

# Pass to Git
path = File.join(REPOS, REPO)
unless File.exists?(path)
  message(:error, 'Invalid repository.')
end
exec("git #{ACTION}-pack #{path}")
