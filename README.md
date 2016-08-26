# Bumblebee :honeybee:

Interface configuration and management for Cloud instances, for use with an Alces directory appliance. 

## Install

*(as root)*

```bash
curl -sL https://git.io/bumblebee-installer | /bin/bash
```

## Configuration

Multiple interface configurations can be provided for multiple networks, using the following example configuration file: 

```yaml
instance:
  domain: bigtown.alces.network
  cluster: littlevillage
  profile: login1
interfaces:
  eth0:
    name: eth0
    ipaddr:
    netmask: 255.255.255.0
    skip_create: true
    subnetname: bigtown-prv
    subnetid: sub-123456
  eth1:
    name: eth1
    ipaddr:
    netmask: 255.255.255.0
    primary_interface: true
    subnetname: littlevillage-api
    subnetid: sub-123457
    interface_id:
    attachment_id:
```

### `instance`

#### `domain`

Enter the domain of your IPA realm, e.g. `bigtown.alces.network`

#### `cluster`

If the instance is part of a compute environment - enter the cluster name, else - leave this field blank.

#### `profile`

Enter the desired profile or instance name - for example `login1` with a `domain` `bigtown.alces.network` and `cluster` `littlevillage` would set the instance hostname `login1.littlevillage.bigtown.alces.network`

### `interfaces`

#### `name`

Enter the interface name for each interface 

#### `ipaddr`

Optionally choose to set an IP address for the instance on the network used for that interface. If no IP address is set - the configurator will use the platforms DHCP server to gather its IP adress. 

#### `netmask`

Enter the netmask for the network used, this will typically be `255.255.255.0`

#### `skip_create`

The `skip_create` option allows you to skip creation of an interface. This is typically only useful for the instance default interface. The `skip_create` option will prevent the interface configurator from attempting to perform any platform-specific creation of network interfaces etc. 

Set this option to `true` to skip interface creation, or leave the field blank

#### `primary_interface`

This option should only be used once - and is used to identify the instances primary interface. When used with an Alces directory appliance, the `primary_interface` option should be used on the interface connected to the infrastructure private network.

#### `subnetname`

This option is purely for cosmetic and logging purposes and used to identify which network each interface belongs to.

#### `subnetid`

This option provides the interface configurator the required information needed to manage its network interfaces on a given network.

#### `interface_id` *AWS only*

This option should be left blank, and is used by the interface configurator to save details of each network interfaces attachment information

#### `attachment_id` *AWS only*

This option should be left blank, and is used by the interface configurator to save details of each network interfaces attachment information

