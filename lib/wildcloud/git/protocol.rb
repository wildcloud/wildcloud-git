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

module Wildcloud
  module Git
    module Protocol

      include EventMachine::Protocols::LineText2

      def initialize(core)
        @core = core
      end

      def receive_line(data)
        type, data = data.split("|", 2)
        method = "handle_#{type}".to_sym
        if respond_to?(method)
          send(method, data)
        else
          close_connection
        end
      end

      def handle_auth(data)
        username, repository, action = data.split("|", 3)
        send_data(@core.authorize(username, repository, action))
        close_connection_after_writing
      end

      def handle_push(data)
        user, commit, ref, repository = data.split("|", 4)
        @core.publish({ :type => 'push', :user => user, :commit => commit, :ref => ref, :repository => repository })
      end

    end
  end
end
