#!/bin/bash
clear

echo
echo -e " \033[31;5m  ██╗     ██╗   ██╗██╗  ██╗██╗██╗   ██╗███╗   ███╗  \033[0m"
echo -e " \033[31;5m  ██║     ██║   ██║██║ ██╔╝██║██║   ██║████╗ ████║  \033[0m"
echo -e " \033[31;5m  ██║     ██║   ██║█████╔╝ ██║██║   ██║██╔████╔██║  \033[0m"
echo -e " \033[31;5m  ██║     ██║   ██║██╔═██╗ ██║██║   ██║██║╚██╔╝██║  \033[0m"
echo -e " \033[31;5m  ███████╗╚██████╔╝██║  ██╗██║╚██████╔╝██║ ╚═╝ ██║  \033[0m"
echo -e " \033[31;5m  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝  \033[0m"
echo

echo -e " \033[34;5m             K3S Cluster Wipe Script                \033[0m"
echo
echo

declare -A nodes

#######################################
# SET YOUR PARAMETERS IN THIS SECTION #
#######################################

use_ssh_passphrase="true" # If your ssh-key has a passphrase, set this to true
copy_ssh_id="false"       # Set this to true to copy the ssh-key into the nodes. False if the nodes already have the keys
cert_name=id_rsa          # The file name for your ssh-key, expected to be in the .ssh or home directory of user running this script
user=lukium               # the name of the user on the remote machines
wipe_config="true"        # Set this to true to wipe the k3s config files on this node. False if you want to keep the config files
                          # If you will be installing k3s again from this node, set this to true, otherwise, the new install will fail
                          # This will delete the ~/.kube folder and all files in it

# IMPORTANT: Master Nodes must be named "master#" in the next section
# feel free to name other nodes anything you like for organizational purposes.

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

############################################
# DO NOT TOUCH PAST HERE OR THINGS BLOW UP #
############################################

# Set all nodes that are master nodes in their own array
declare -A masters

# Iterate through nodes and filter master nodes
for key in "${!nodes[@]}"; do
    if [[ $key == master* ]]; then
        masters[$key]=${nodes[$key]}
    fi
done

# Set all nodes that are not masters into agents array
declare -A agents

# Iterate through nodes and filter agent nodes
for key in "${!nodes[@]}"; do
    if [[ $key != master* ]]; then
        agents[$key]=${nodes[$key]}
    fi
done

echo -e "\033[34;5mNode List:\e[0m"
echo

echo -e "\e[33mMaster Nodes:\e[0m"
for key in $(printf "%s\n" "${!masters[@]}" | sort); do
    echo -e "\e[33m$key: ${masters[$key]}\e[0m"
done

echo

echo -e "\e[35mAgent Nodes:\e[0m"
for key in $(printf "%s\n" "${!agents[@]}" | sort); do
    echo -e "\e[35m$key: ${agents[$key]}\e[0m"
done

echo
echo -e "\e[31m    _   _   __   ___  __  _  _  __  _   __  \e[0m"
echo -e "\e[31m   | | | | /  \ | _ \|  \| || ||  \| | / _] \e[0m"
echo -e "\e[31m   | 'V' || /\ || v /| | ' || || | ' || [/\ \e[0m"
echo -e "\e[31m   !_/ \_!|_||_||_|_\|_|\__||_||_|\__| \__/ \e[0m"
echo

# Pause and warn user in red text that proceeding will wipe all nodes
echo -e "\e[31mThis will wipe k3s from all the hosts listed above\e[0m"
echo -e "\e[31mPress CTRL+C to CANCEL\e[0m. \e[32mPress enter to continue...\e[0m"
read -p ""


# if use_ssh_passphrase, then check if id_rsa is in .ssh folder if not run from home folder
if [ $use_ssh_passphrase = "true" ] ; then
    if [ ! -f ~/.ssh/id_rsa ] ; then
        echo "$cert_name not found in ~/.ssh folder, checking home folder"
        if [ ! -f ~/id_rsa ] ; then
            echo "$cert_name not found in home folder, exiting"
            exit 1
        else
            echo "$cert_name found in home folder, copying to ~/.ssh"
            cp ~/{$cert_name,$cert_name.pub} ~/.ssh
            chmod 600 ~/.ssh/$cert_name
            chmod 644 ~/.ssh/$cert_name.pub
        fi
    fi
    ssh_agent_output=$(eval ssh-agent -s)
    export SSH_AGENT_PID=$(echo "$ssh_agent_output" | grep -oP 'SSH_AGENT_PID=\K\d+')
    echo "Storing ssh-agent pid: $SSH_AGENT_PID to kill later"
    ssh-add ~/.ssh/$cert_name
fi

# Copy ssh-id to all nodes in sorted order if copy_ssh_id is true
if [ "$copy_ssh_id" = true ] ; then
    for node in $(printf "%s\n" "${!nodes[@]}" | sort); do
        echo -e "\e[32mCopying ssh-id to $node\e[0m"
        ssh-copy-id -i ~/.ssh/$cert_name.pub $user@${nodes[$node]}
    done
fi

# Wipe all masters in sorted order using /usr/local/bin/k3s-uninstall.sh script if it exists on the node and echo that the node was wiped otherwise let the user know that k3s is not installed
for node in $(printf "%s\n" "${!masters[@]}" | sort); do    
    echo -e "\e[31mWiping $node\e[0m"
    if ssh $user@${masters[$node]} '[ -f /usr/local/bin/k3s-uninstall.sh ]'; then
        ssh $user@${masters[$node]} 'sudo /usr/local/bin/k3s-uninstall.sh'
        echo -e "\e[32m$node wiped\e[0m"
    else
        echo -e "\e[31mk3s not installed on $node\e[0m"
    fi    
done

# Wipe all agents in sorted order using /usr/local/bin/k3s-agent-uninstall.sh script if it exists on the node and echo that the node was wiped otherwise let the user know that k3s is not installed
for node in $(printf "%s\n" "${!agents[@]}" | sort); do    
    echo -e "\e[31mWiping $node\e[0m"
    if ssh $user@${agents[$node]} '[ -f /usr/local/bin/k3s-agent-uninstall.sh ]'; then
        ssh $user@${agents[$node]} 'sudo /usr/local/bin/k3s-agent-uninstall.sh'
        echo -e "\e[32m$node wiped\e[0m"
    else
        echo -e "\e[31mk3s not installed on $node\e[0m"
    fi    
done

# Wipe the config files on this node if wipe_config is true
if [ $wipe_config = "true" ] ; then
    echo -e "\e[31mWiping config files on this node\e[0m"
    # Delete the ~/.kube folder only if it exists, otherwise, let the user know that it does not exist
    if [ -d ~/.kube ] ; then
        rm -rf ~/.kube
        echo -e "\e[32mConfig files wiped\e[0m"
    else
        echo -e "\e[31m~/.kube folder does not exist\e[0m"
    fi    
fi

echo -e "\e[32mAll nodes wiped\e[0m"

# Kill the ssh-agent
if [ $use_ssh_passphrase = "true" ] ; then
    echo "Killing ssh-agent with PID: $SSH_AGENT_PID"
    kill $SSH_AGENT_PID
fi

# Unset all variables
unset use_ssh_passphrase copy_ssh_id cert_name user nodes masters agents node ssh_agent_output SSH_AGENT_PID

echo -e "\e[32mssh-agent killed and variables unset\e[0m"
