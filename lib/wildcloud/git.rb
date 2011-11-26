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

if $0 == __FILE__
  $: << File.expand_path('../..', __FILE__)
  require 'bundler/setup'
  require 'wildcloud/git/server'
  require 'eventmachine'
  EventMachine.run do
    Wildcloud::Git::Server.start
  end
end
