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
require 'bumblebee/cli'
require 'bumblebee/platform'
require 'bumblebee/config'

module Bumblebee
  class << self
    def platform
      @platform ||= Platform.new
    end

    def config
      @config ||= Config.new(ENV['BUMBLEBEE_CONFIG'] || '/opt/bumblebee/etc/cluster.yml')
    end

    def interface_ip(name)
      `ip -o -4 address show dev #{name} | head -n 1 | sed 's/.*inet \\(\\S*\\)\\/.*/\\1/g'`.chomp
    end

    def interface_network(name)
      `ip -o -4 address show dev #{name} | head -n 1 | grep ' brd ' | sed 's/.*inet \(\S*\) brd.*/\1/g'`.chomp
    end

    def interface_exists?(name)
      system("ip -o -4 link show #{name} 1>/dev/null 2>/dev/null")
    end
  end
end
