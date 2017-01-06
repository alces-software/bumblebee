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
require 'bumblebee/route'

module Bumblebee
  class Interface
    attr_accessor :name, :subnet_name, :subnet_id, :ipaddr, :netmask, :routes
    attr_accessor :is_skip, :is_primary, :is_dhcp, :is_authoritative, :device_index
    def initialize(metadata)
      self.name = metadata['name']
      self.subnet_name = metadata['subnet_name'] || metadata['subnetname']
      self.subnet_id = metadata['subnet_id'] || metadata['subnetid']
      self.ipaddr = metadata['ipaddr'] unless metadata['ipaddr'].to_s.empty?
      self.is_dhcp = (metadata['dhcp'] == true)
      self.netmask = metadata['netmask']
      self.is_primary = (metadata['primary'] == true)
      self.is_skip = (metadata['skip_create'] == true)
      self.is_authoritative = (metadata['authoritative'] == true)
      self.device_index = metadata['name'][-1]
      self.routes = (metadata['routes'] || []).map(&Route.method(:new)) || []
    end

    def ipaddr
      @ipaddr ||=
        if dhcp?
          Bumblebee.interface_ip(name)
        else
          allocate_ip
        end
    end

    def dhcp?
      is_dhcp
    end

    def skip?
      is_skip
    end

    def primary?
      is_primary
    end

    def authoritative?
      is_authoritative
    end

    def configure
      unless skip?
        Bumblebee.platform.create(self) unless Bumblebee.interface_exists?(name)
        update_firewall
        ifup
      end
    end

    def update_firewall
      system(%(sed -i '/#APPLIANCERULES#/a -A INPUT -i #{name} -j ACCEPT' /etc/sysconfig/iptables))
      system(%(systemctl restart iptables))
    end

    def ifup
      File.open("/etc/sysconfig/network-scripts/ifcfg-#{name}", 'w') do |f|
        f.puts %(DEVICE="#{name}")
        f.puts %(ONBOOT="yes")
        f.puts %(TYPE="Ethernet")
        if dhcp?
          f.puts %(BOOTPROTO="dhcp")
          f.puts %(PEERDNS="no")
          f.puts %(PEERROUTES="no")
          f.puts %(DEFROUTE="no")
        else
          f.puts %(BOOTPROTO="none")
          f.puts %(IPADDR="#{ipaddr}")
          f.puts %(NETMASK="#{netmask}")
        end
      end
      if routes.any?
        routes.each_with_index do |route, c|
          File.open("/etc/sysconfig/network-scripts/route-#{name}", 'w') do |f|
            f.puts %(ADDRESS#{c}="#{route.address}")
            f.puts %(NETMASK#{c}="#{route.netmask}")
            f.puts %(GATEWAY#{c}="#{route.gateway}")
          end
        end
      end
      system(%(/bin/bash -c 'while ! /sbin/ip link show "#{name}"; do sleep 1; done'))
      system(%(/sbin/ifup #{name} > /dev/null))
    end

    def allocate_ip
      Bumblebee.platform.allocate_ip(self)
    end
  end
end
