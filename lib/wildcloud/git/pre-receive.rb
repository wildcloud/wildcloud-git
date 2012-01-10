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

require 'yaml'
require 'socket'

$: << File.expand_path('../../..', __FILE__)
require 'wildcloud/git/configuration'

# Constants
repositories = Wildcloud::Git.configuration['paths']['repositories']
user = ENV['GIT_USERNAME']
socket = UNIXSocket.new(Wildcloud::Git.configuration['paths']['socket'])

# One line per ref
$stdin.each_line do |line|
  from, to, ref = line.split(' ')
  ref.sub!('refs/heads/', '')
  repo = File.expand_path('.').sub(repositories, '')
  socket.write("push|#{user}|#{to}|#{ref}|#{repo}\n")
end

socket.close
