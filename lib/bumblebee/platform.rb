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
require 'aws-sdk'
require 'ec2_metadata'

module Bumblebee
  class Platform
    def openstack?
      type == 'openstack'
    end

    def aws?
      type == 'aws'
    end

    def instance_id
      @instance_id ||= if aws?
                         Ec2Metadata[:instance_id]
                       else
                         local_ip
                       end
   end

    def local_ip
      @local_ip ||= Ec2Metadata[:local_ipv4]
    end

    def ec2
      @ec2 ||= begin
                 region = Ec2Metadata[:placement][:availability_zone][0..-2]
                 credentials = if Bumblebee.config.access_key_id
                                 Aws::Credentials.new(Bumblebee.config.access_key_id,
                                                      Bumblebee.config.secret_access_key)
                               else
                                 Aws::InstanceProfileCredentials.new
                               end
                 Aws::EC2::Client.new(region: region,
                                      credentials: credentials,
                                      retry_limit: 10)
               end
    end

    def type
      @type ||= if File.exists?('/sys/hypervisor/uuid') &&
                   File.read('/sys/hypervisor/uuid')[0..2] == 'ec2'
                  'aws'
                else
                  'openstack'
                end
    end

    def create(iface)
      if aws?
        nic_id =
          begin
            ec2.create_network_interface(
              {
                subnet_id: iface.subnet_id,
                description: "#{iface.subnet_name} interface for #{instance_id}",
                private_ip_address: iface.ipaddr.to_s
              }
            )
          rescue Aws::EC2::Errors::InvalidIPAddressInUse, Aws::EC2::Errors::InvalidParameterValue
            # increment IP address and try again
            if IPAddr === iface.ipaddr
              iface.ipaddr = iface.ipaddr.succ
              retry
            else
              raise
            end
          end.network_interface.network_interface_id

        attachment_id = ec2.attach_network_interface(
          {
            network_interface_id: nic_id,
            instance_id: instance_id,
            device_index: iface.device_index,
          }
        ).attachment_id

        ec2.modify_network_interface_attribute(
          {
            network_interface_id: nic_id,
            attachment: {
              attachment_id: attachment_id,
              delete_on_termination: true
            }
          }
        )
      end
    end

    def allocate_ip(iface)
      if aws?
        subnets = ec2.describe_subnets.subnets
        if subnet = subnets.find{|s| s.subnet_id == iface.subnet_id}
          IPAddr.new(IPAddr.new(subnet.cidr_block).to_i + 4, family = Socket::AF_INET)
        else
          raise "Unable to find subnet for interface"
        end
      end
    end
  end
end
