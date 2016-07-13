# Bumblebee

## Node requirements
###IAM Policies
The following IAM policies should be attached to each node. Alternatively, AWS keys with the appropriate permissions could be used. 

 * `ec2:AttachNetworkInterface` - used to attach both the `build` and `prv` network interfaces for each host
 * `ec2:CreateNetworkInterface` - used to create both the `build` and `prv` network interfaces for each host
 * `ec2:DeleteNetworkInterface` - used to cleanly delete each of the interfaces when a clean shutdown of a node is performed
 * `ec2:DetachNetworkInterface` - used to detach a network interface prior to deleting when a clean shutdown of a node is  performed
 * `ec2:ModifyNetworkInterfaceAttribute` - used to add the `DeleteOnTerminate` tag to each of the created interfaces to    ensure a clean stack destroy
