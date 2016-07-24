# Automated IPA setup with Alces Flight Trigger

## Prerequisites :scroll:
* Directory server set up
* Alces Flight Trigger service running
* Fresh cluster to join IPA realm

## Setting up Flight Trigger :computer:

* Store each of the directory scripts with appropriate permissions (executable) in the `/opt/clusterware/var/lib/triggers/` directory - when nodes or clusters join and leave - these scripts will be run using the parameters provided

## Available actions (manual) :fireworks:

### Adding a cluster :package:

When a login instance boots, it should trigger the `addcluster` script - which informs IPA to add a new cluster with the name provided to the Trigger service. 

This can be performed manually using the following example command:

```bash
CLUSTER=$(hostname -d | cut -d . -f 1); /opt/clusterware/opt/jq/bin/jq -n "{ \"options\": { \"cluster\": \"$CLUSTER\" }, \"args\": [ ], \"input\": \"\" }" | http $DIRECTORYIP:25278/trigger/addcluster --auth alces:password
```

### Adding a cluster node to an existing domain :gift:

A cluster node can use the Trigger service to perform creation of records with the following example command: 

```bash
clientname=$(hostname -s) cluster=$(hostname -d | cut -d . -f 1) ipaddr=$(hostname -i); /opt/clusterware/opt/jq/bin/jq -n "{ \"options\": { \"clientname\": \"$clientname\", \"ipaddr\": \"$ipaddr\", \"cluster\": \"$cluster\", \"onetimepass\": \"moose\" }, \"args\": [ ], \"input\": \"\" }" | http $DIRECTORY:25278/trigger/addnode --auth alces:password
```

### Removing a cluster node from a domain :fire:

When a node leaves, it should trigger the `removenode` script - removing all records from the IPA service. This can be performed manually with the following example command:

```bash
clientname=$(hostname -s) cluster=$(hostname -d | cut -d . -f 1) ipaddr=$(hostname -i); /opt/clusterware/opt/jq/bin/jq -n "{ \"options\": { \"clientname\": \"$clientname\", \"cluster\": \"$cluster\" }, \"args\": [ ], \"input\": \"\" }" | http $DIRECTORY:25278/trigger/removenode
```

### Removing a cluster from the IPA service
When a cluster is destroyed, the login node should trigger the `removecluster` script - removing the DNS zones and associated records for that cluster. This can be performed manually with the following example command: 

```bash
