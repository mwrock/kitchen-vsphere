# -*- encoding: utf-8 -*-
#
# Author:: Matt Wrock (<matt@mattwrock.com>)
#
# Copyright (C) 2014, Matt Wrock
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

require 'benchmark'
require 'fog'
require 'kitchen'
require 'etc'
require 'ipaddr'
require 'socket'

module Kitchen
  module Driver
    # Vsphere driver for Kitchen.
    class Vsphere < Kitchen::Driver::SSHBase
      default_config :public_key_path, File.expand_path('~/.ssh/id_rsa.pub')
      default_config :username, 'root'
      default_config :port, '22'
      default_config :use_ipv6, false
      default_config :upload_public_ssh_key, true

      def create(state)
        config[:server_name] ||= generate_name(instance.name)
        server = create_server(state)
        state[:hostname] = server.public_ip_address
        wait_for_sshd(state[:hostname], config[:username],
          { :port => config[:port] }) ; info '(ssh ready)'
        if config[:upload_public_ssh_key]
          upload_public_ssh_key(state, config, server)
        end
      rescue ::Fog::Errors::Error, Excon::Errors::Error => ex
        raise ActionFailed, ex.message
      end

      def destroy(state)
        return if state[:server_id].nil?

        server = compute.servers.get(state[:server_id])
        server.destroy unless server.nil?
        info "VSphere instance <#{state[:server_id]}> destroyed."
        state.delete(:server_id)
        state.delete(:hostname)
      end

      private

      def compute
        config[:authentication][:provider] = 'vsphere'
        ::Fog::Compute.new(config[:authentication].dup)
      end

      def convert_to_strings(objay)
        if objay.kind_of?(Array)
          objay.map { |v| convert_to_strings(v) }
        elsif objay.kind_of?(Hash)
          Hash[objay.map { |(k, v)| [k.to_s, convert_to_strings(v)] }]
        else
          objay
        end
      end

      def create_server(state)
        server_configed = config[:server_create] || {}
        server_configed = server_configed.dup
        server_configed[:name] = config[:server_name]
        server_configed = convert_to_strings(server_configed)
        clone_results = compute.vm_clone(server_configed)
        server = compute.servers.get(clone_results['new_vm']['id'])
        state[:server_id] = server.id
        info "VSphere instance <#{state[:server_id]}> created."
        server.wait_for { print '.'; tools_state != 'toolsNotRunning' && public_ip_address }
        puts "\n(server ready)"
        server
      end

      def generate_name(base)
        # Generate what should be a unique server name
        sep = '-'
        pieces = [
          base,
          Etc.getlogin,
          Socket.gethostname,
          Array.new(8) { rand(36).to_s(36) }.join
        ]
        until pieces.join(sep).length <= 64 do
          if pieces[2].length > 24
            pieces[2] = pieces[2][0..-2]
          elsif pieces[1].length > 16
            pieces[1] = pieces[1][0..-2]
          elsif pieces[0].length > 16
            pieces[0] = pieces[0][0..-2]
          end
        end
        pieces.join sep
      end

      def upload_public_ssh_key(state, config, server)
        ssh = ::Fog::SSH.new(state[:hostname], config[:username],
          { :password => config[:password] })
        pub_key = open(config[:public_key_path]).read
        ssh.run([
          %{mkdir .ssh},
          %{echo "#{pub_key}" >> ~/.ssh/authorized_keys},
          %{passwd -l #{config[:username]}}
        ])
      end
    end
  end
end

# vim: ai et ts=2 sts=2 sw=2 ft=ruby
