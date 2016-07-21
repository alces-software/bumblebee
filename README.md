# Bumblebee :honeybee:

Launch static environments in the Cloud :cloud:

## Install :rocket:

* CentOS/el 7:

```
$ curl -sL http://git.io/bumblebee-installer | /bin/bash
```

## Build an image :cloud:

### EC2 AMI

Using the Alces image creator: 

* Create the AMI

```bash
$ ./ami-creator -k $YOURAWSKEY -b 1.4.1 -i static -t static
```

* Load the AMI into the CloudFormation template for your desired region, e.g.: 

```json
"Mappings": {
    "AWSRegionArch2AMI": {
        "eu-west-1": {
            "HVM64": "ami-123456"
        }
    }
}
```

* The CloudFormation contains default example settings for two nodes, once you have checked the settings, and verified your CloudFormation parameters - launch the CloudFormation template

### OpenStack image

Using an Alces build machine:

* Check out the `imageware` repository, then switch to the `static` branch. Create the image:

```bash
$ ./makeimage static $VERSION
```

* Copy the image to your preferred OpenStack installation using your transfer method of choice

* Once authenticated against the environment - upload the image to Glance: 

```bash
$ glance image-upload \
    --container-format bare \
    --disk-format qcow2 \
    --min-disk 1 \
    --file $PATHTOIMAGE \
    --is-public true \
    --name bumblebee \
    --human-readable \
    --progress
```

* The Heat template contains default example settings for two nodes, once you have checked the settings, and verified your Heat template parameters - launch the Heat template. 

## Configuration options

The Bumblebee configurator service reads from the configuration file written at start-up by cloud-init - located at `/opt/bumblebee/etc/cluster.yml`

An example configuration file looks like the following:

```yaml
instance:
  cluster: myclustername
  domain: alces.network
  profile: login1
interfaces:
  eth1:
    name: eth1
    ipaddr: 10.75.10.10
    netmask: 255.255.255.0
    primary_interface: true
    subnetname: %CLUSTERNAME%-build
    subnetid: (aws specific)
  eth2:
    name: eth2
    ipaddr: 10.75.20.10
    netmask: 255.255.255.0
    subnetname: %CLUSTERNAME%-prv
    subnetid: (aws specific)
```

You can configure as many or as few interfaces as you wish to meet your desired network requirements. 

### Using pre-defined static IP addresses

To use a pre-defined, static IP address for each deployed node - the `ipaddr` and `netmask` fields must be filled in - for example:

```yaml
ipaddr: 10.75.20.10
netmask: 255.255.255.0
```

If you wish to obtain an IP address using your networks DHCP server - simply remove the `ipaddr` value, or line entirely: 

```yaml
ipaddr:
netmask: 255.255.255.0
```
