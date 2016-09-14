#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Bumblebee.
#
# Alces Bumblebee is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Bumblebee is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Bumblebee, please visit:
# https://github.com/alces-software/bumblebee
#==============================================================================
require 'aws-sdk'

module Bumblebee
  class Configurator
    class << self
      def configure
        configure_interfaces
        configure_names
      end

      def configure_names
        # Configure hostname and /etc/hosts
        system("hostnamectl set-hostname #{config.fqdn}")
        system("hostnamectl set-hostname --transient #{config.fqdn}")
        system(%(sed -i "/.*127.0.0.1 #{config.hostname}.*/d" /etc/hosts))
        system(%(sed -i "/.*::1 #{config.hostname}.*/d" /etc/hosts))
      end

      def configure_interfaces
        if config.interfaces.any?
          primary = nil
          config.interfaces.each do |iface|
            iface.configure
            primary = iface if iface.primary?
          end
          update_etc_hosts(primary.ipaddr.to_s) if primary
        else
          update_etc_hosts(Bumblebee.platform.local_ip)
        end
      end

      def update_etc_hosts(ipaddr)
        File.open('/etc/hosts', 'a') do |f|
          f.puts "#{ipaddr} #{config.fqdn} #{config.hostname}"
        end
      end

      def config
        Bumblebee.config
      end
    end
  end
end
