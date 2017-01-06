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
require 'yaml'
require 'ipaddr'
require 'bumblebee/interface'

module Bumblebee
  class Config
    attr_accessor :hostname, :hostname_prefix, :domain, :cluster, :interfaces, :access_key_id, :secret_access_key
    def initialize(cfg_file)
      config = YAML.load_file(cfg_file)
      self.hostname = config['hostname']
      self.hostname_prefix = config['hostname_prefix'] || "flight-"
      self.domain = config['domain']
      self.cluster = config['cluster'] unless config['cluster'].to_s.empty?
      self.interfaces = (config['interfaces'] || []).map(&Interface.method(:new))
      self.access_key_id = config['access_key_id']
      self.secret_access_key = config['secret_access_key']
    end

    def hostname
      @hostname ||= determine_name
    end

    def fqdn
      @fqdn ||= [hostname, cluster, domain].compact.join('.')
    end

    private
    def determine_name
      intf = interfaces.find {|intf| intf.authoritative?} || interfaces.first
      if intf.nil?
        # no interfaces defined, query platform
        ipaddr = Bumblebee.interface_ip('eth0').to_s
        netmask = Bumblebee.interface_network('eth0').split('/')[1].to_i
      else
        ipaddr = intf.ipaddr.to_s
        netmask = IPAddr.new(intf.netmask).to_i.to_s(2).count("1")
      end

      numeral = ipaddr.to_s.split('.').last.to_i
      prefix = if netmask < 24
                 network = IPAddr.new("#{ipaddr}/#{netmask}")
                 first_net = network.to_s.split('.')[2].to_i
                 (ipaddr.split('.')[2].to_i - first_net + 97).chr
               end
      # take into account the 3 addresses at the beginning of the
      # subnet are reserved on AWS.
      numeral -= 3 if Bumblebee.platform.aws? && (prefix.nil? || prefix == 'a')
      "#{hostname_prefix}#{prefix}#{sprintf('%03d',numeral)}"
    end
  end
end
