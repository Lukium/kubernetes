# K3S Cluster Wipe

## Variables:
- use_ssh_passphrase: ["true"|"false"] = If the ssh-key used for connecting to the host machines is protected by a passphrase, set this to "true" and the script will query you for your passphrase a single time, register it with ssh-agent, then when the script is done, kill the ssh-agent.
- copy_ssh_id: ["true"|"false"] = Set this to "true" to copy the ssh-key into each host. The key should either be in the home directory of the user running this script or in their ~/.ssh folder. If the hosts already have the key, or if you do not wish to copy the keys to the hosts, then set this to "false".
- cert_name: [default="id_rsa"] = The name of the ssh-key file to be used by the script. Both the private key and public key should be present, with the public key having a .pub extension and the private key with no extension, either in the home or ~/.ssh folder of the user running this script.
- user: ["<username>"] = The username that will be connected to on the host machines.
- wipe_config: [default="true"] = If true, it will delete the ~/.kube folder on the node running this script. Seems especially necessary if a new k3s install will be taking place from this node, otherwise the new install will fail. You should only need to set this to "false" if for some reason you will need to backup the ~/.kube folder for some purpose

## Nodes Array:
### VERY IMPORTANT: master nodes MUST be declared as `master#` for example: `nodes[master1]=192.168.10.171`

The nodes array is the list of hosts that the script will connect to for wiping the cluster. Each node should declaration has 3 parts:
- array: node (same for all nodes)
- node key: [node type][node number] Examples: master1, master2, worker4, storage3 **Master nodes must be named master**
- node IP address: [IPv4 node IP] Examples: 192.168.1.10, 10.10.6.100

An example list of nodes would look something like this:
nodes[master1]=192.168.10.171  
nodes[master2]=192.168.10.172  
nodes[master3]=192.168.10.173  
nodes[storage1]=192.168.10.181  
nodes[storage2]=192.168.10.182  
nodes[storage3]=192.168.10.183  
nodes[worker1]=192.168.10.191  
nodes[worker2]=192.168.10.192  
nodes[worker3]=192.168.10.193  
nodes[worker4]=192.168.10.194  
nodes[worker5]=192.168.10.195  

## Process:
1. The script first splits the nodes into a **masters** and **agents** arrays due to different scripts being used to uninstall k3s depending on node type
2. The script lists to the user the master and agent nodes
3. The script pauses and warns the user that proceeding will wipe k3s from all listed nodes
4. If use_ssh_passphrase = "true", the Script will ask for user's passphrase and register it with ssh-agent. It will also store the ssh-agent's PID to kill at the end of the script
5. If copy_ssh_id = "true", the Script will copy the ssh-key to all hosts
6. The Script will iterate through the masters array and run the /usr/local/bin/k3s-uninstall.sh in each node if the uninstall script is present, otherwise will notify the user that k3s is not installed on the node
7. The Script will iterate through the agents array and run the /usr/local/bin/k3s-agent-uninstall.sh in each node if the uninstall script is present, otherwise will notify the user that k3s is not installed on the node
8. If wipe_config = "true", the Script will rm -rf the ~/.kube folder on the machine running the Script
9. If use_ssh_passphrase = "true", the Script will kill the ssh-agent storing the user's passphrase using the previously stored PID
10. The Script will unset all variables set by it
