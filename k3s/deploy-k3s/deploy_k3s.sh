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

echo -e " \033[34;5m         K3S Cluster Deployment Script              \033[0m"
echo
echo

declare -A nodes

#########################################################################################################
#                                SET YOUR PARAMETERS IN THIS SECTION                                    #
#########################################################################################################
###                                         App Versions                                              ###
#########################################################################################################
# Installing Rancher from the stable channel. Highest currently compatible k3s version is v1.26.10+k3s2 #
kube_vip_version="v0.6.3" # Kube-VIP Version
metallb_version="v0.13.12" # metallb version
k3sVersion="v1.26.10+k3s2" # K3S Version
cert_manager_version="v1.13.2" # Cert Manager Version
#########################################################################################################
###                                             Nodes                                                 ###
#########################################################################################################
# IMPORTANT:
# Master Nodes must be named "master#" in the next section
# Nodes to be used for longhorn storage must be named "storage#" in the next section
# Non-Longhorn Worker nodes must be named "worker#" in the next section

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

#########################################################################################################
###                                     Inner Script Variables                                        ###
#########################################################################################################

#  ╔════════════════════╗
#  ║   Main Variables   ║
#  ╚════════════════════╝
use_ssh_passphrase="true"               
# If your ssh-key has a passphrase, set this to true

copy_ssh_id="false"                     
# Set this to true to copy the ssh-key into the nodes. False if the nodes already have the keys

cert_name=id_rsa                        
# The file name for your ssh-key, expected to be in the .ssh or home directory of user running  script

no_SHKC="true"                          
# Set this to true to disable StrictHostKeyChecking for the script.
                           
after_SHKC="ask"                        
# Set this to ask to enable StrictHostKeyChecking after the script is done.
# Other options are yes, ask, and accept-new

keep_manifestes="true"                  
# Set this to true to keep a copy of all manifest files in the manifests folder

user=user                             
# the name of the user on the remote machines

interface=eth0                          
# connection interface on the hosts. You can check this by running 'ip a' on the hosts

vip=192.168.10.50                       
# the desired Virtual IP for the master nodes

lbrange=192.168.10.51-192.168.10.75     
# The desired range to be available for load balancing services

display_passwords_on_completion="true"
# If set to true, will display all passwords at the end of the script, otherwise
# will display all other information and instructions ommiting passwords

#  ╔═══════════════════════╗
#  ║   Rancher Variables   ║
#  ╚═══════════════════════╝

install_rancher="true"                  
# Set this to true to install rancher on the cluster. Set this to false to skip rancher installation
# If you set this to false, you will need to install rancher manually. 
# Will install cert-manager

rancher_hostname="rancher.local"        
# The hostname you want to use for rancher

rancher_bootstrap_password="admin"      
# The password you want to use for rancher. Will be changed on first login

expose_rancher="true"
# Set this to true to expose rancher using a load balancer. Set this to false to skip exposing rancher

#  ╔════════════════════════╗
#  ║   Longhorn Variables   ║
#  ╚════════════════════════╝                                   

install_longhorn="true"                 
# Set this to true to install longhorn on the cluster. Set this to false to skip longhorn installation
# If you set this to false, you will need to install longhorn manually. Will only install if Rancher is
# installed with the above variable set to true

#  ╔═══════════════════════╗
#  ║   Traefik Variables   ║
#  ╚═══════════════════════╝   

install_traefik="true"                  
# Whether to install traefik for ingress. cert-manager will be upgraded using custom file

traefik_ip=192.168.10.60                
# The IP address you want to use for traefik. This IP must be available on the network and within the
# range of the load balancer range defined in base variables

traefik_username="admin"                
# The username you want to use for traefik Will be hashed and base64 encoded with password

traefik_password="password"             
# The password you want to use for traefik. Will be hashed and base64 encoded with username

traefik_domain="your.domain.tld"
# The domain you want to use for traefik. You MUST own this domain and have it setup in
# cloudflare BEFORE running this script.

traefik_cf_token="lkjsgdf48fsdFSD89743ASDF978"
# Setup a token in cloudflare by visiting:
# https://dash.cloudflare.com/profile/api-tokens
# Create an API TOKEN (NOT API KEY) with the following permissions:
# Zone - Zone - Read
# Zone - DNS - Edit
# include - All Zones

traefik_secret="domain-tls"             
# Name of the secret you want to use for traefik

traefik_letsencrypt_email="user@domain.tld"
# The email address you want to use for getting SSL from LetsEncrypt.
# Does not need to match your cloudflare account email address

traefik_cloudflare_email="user@domain.tld"
# This email is used as part of the challenge to verify ownership of the domain.
# This email must match the email address of the cloudflare account you are using for the domain                       

#  ╔══════════════════════╗
#  ║   Pihole Variables   ║
#  ╚══════════════════════╝ 
                                        
install_pihole="true"                   
# Whether to install pihole for DNS. Requires traefik to be installed.

pihole_volume_capacity="3Gi"           
# The volume capacity to use for pihole

pihole_webpassword="password"         
# The password you want to use for pihole

pihole_timezone="America/New_York"     
# The timezone you want to use for pihole
# Find your timezone here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

pihole_ip="192.168.10.75"
# This will be your DNS server IP address
# The IP address you want to use for pihole. This IP must be available on the network and within the
# range of the load balancer range defined in base variables

#########################################################################################################
###      !!!!!                    DO NOT TOUCH PAST HERE OR THINGS BLOW UP                 !!!!!      ###
#########################################################################################################

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

# Set all storage* nodes into a storage array
declare -A storage

# Iterate through nodes and filter storage nodes
for key in "${!nodes[@]}"; do
    if [[ $key == storage* ]]; then
        storage[$key]=${nodes[$key]}
    fi
done

# Set all worker* nodes into a worker array
declare -A workers

# Iterate through nodes and filter worker nodes
for key in "${!nodes[@]}"; do
    if [[ $key == worker* ]]; then
        workers[$key]=${nodes[$key]}
    fi
done


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

echo -e "\e[36mStorage Nodes:\e[0m"
for key in $(printf "%s\n" "${!storage[@]}" | sort); do
    echo -e "\e[36m$key: ${storage[$key]}\e[0m"
done

echo

echo -e "\e[32mWorker Nodes:\e[0m"
for key in $(printf "%s\n" "${!workers[@]}" | sort); do
    echo -e "\e[32m$key: ${workers[$key]}\e[0m"
done

echo
echo -e "\e[31m    _   _   __   ___  __  _  _  __  _   __   _  \e[0m"
echo -e "\e[31m   | | | | /  \ | _ \|  \| || ||  \| | / _] / \ \e[0m"
echo -e "\e[31m   | 'V' || /\ || v /| | ' || || | ' || [/\ \_/ \e[0m"
echo -e "\e[31m   !_/ \_!|_||_||_|_\|_|\__||_||_|\__| \__/ (_) \e[0m"
echo

# Pause and warn user that proceeding will install k3s on all nodes listed
echo -e "\e[31mThis will install k3s on all the hosts listed above\e[0m"
echo -e "\e[31mPress CTRL+C to CANCEL\e[0m. \e[32mPress enter to continue...\e[0m"
read -p ""

# Refresh time in case it's off
sudo timedatectl set-ntp off
sudo timedatectl set-ntp on

if [ $no_SHKC = "true" ] ; then
    echo -e "\e[32;5mDisabling StrictHostKeyChecking\e[0m"
    echo "StrictHostKeyChecking no" > $HOME/.ssh/config
fi

# if use_ssh_passphrase, then check if id_rsa is in .ssh folder if not run from home folder
if [ $use_ssh_passphrase = "true" ] ; then
    if [ ! -f $HOME/.ssh/id_rsa ] ; then
        echo "$cert_name not found in $HOME/.ssh folder, checking home folder"
        if [ ! -f $HOME/id_rsa ] ; then
            echo "$cert_name not found in home folder, exiting"
            exit 1
        else
            echo "$cert_name found in home folder, copying to $HOME/.ssh"
            cp $HOME/{$cert_name,$cert_name.pub} $HOME/.ssh
            chmod 600 $HOME/.ssh/$cert_name
            chmod 644 $HOME/.ssh/$cert_name.pub
        fi
    fi
    ssh_agent_output=$(eval ssh-agent -s)
    export SSH_AGENT_PID=$(echo "$ssh_agent_output" | grep -oP 'SSH_AGENT_PID=\K\d+')
    echo "Storing ssh-agent pid: $SSH_AGENT_PID to kill later"
    ssh-add $HOME/.ssh/$cert_name
fi

# Install k3sup if not installed
if ! command -v k3sup version &> /dev/null
then
    echo -e "\e[31;5mk3sup not found, installing\e[0m"
    curl -sLS https://get.k3sup.dev | sh
    sudo install k3sup /usr/local/bin/
else
    echo -e "\e[32;5mk3sup already installed\e[0m"
fi

# Install Kubectl if not installed
if ! command -v kubectl version &> /dev/null
then
    echo -e "\e[31;5mKubectl not found, installing\e[0m"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
else
    echo -e "\e[32;5mKubectl already installed\e[0m"
fi

# Install htpasswd if not installed
if ! command -v htpasswd &> /dev/null
then
    echo -e "\e[31;5mhtpasswd not found, installing\e[0m"
    sudo apt install apache2-utils -y
else
    echo -e "\e[32;5mhtpasswd already installed\e[0m"
fi

# Copy ssh-id to all nodes in sorted order if copy_ssh_id is true
if [ $copy_ssh_id = "true" ] ; then
    for node in $(printf "%s\n" "${!nodes[@]}" | sort); do
        echo -e "\e[32mCopying ssh-id to $node\e[0m"
        ssh-copy-id -i $HOME/.ssh/$cert_name.pub $user@${nodes[$node]}
    done
fi

# Install policycoreutils on all nodes if not already installed using apt install and NEEDRESTART_MODE=a
echo -e "\e[32mInstalling policycoreutils on all nodes\e[0m"
for node in $(printf "%s\n" "${!nodes[@]}" | sort); do    
    # Check if policycoreutils is installed, if not, install it
    if ssh $user@${nodes[$node]} 'dpkg -s policycoreutils &> /dev/null'; then
        echo -e "\e[32mpolicycoreutils already installed on $node\e[0m"
    else
        ssh $user@${nodes[$node]} 'sudo NEEDRESTART_MODE=a apt install -y policycoreutils'
        echo -e "\e[32mpolicycoreutils installed on $node\e[0m"
    fi
done

#####################################
#    K3S INSTALLATION - MASTER 1    #
#####################################

# Install K3S on master1 node using k3sup
echo -e "\e[32mInstalling K3S on master1\e[0m"
mkdir $HOME/.kube # Create .kube folder if it doesn't exist
k3sup install \
  --ip ${nodes[master1]} \
  --user $user \
  --tls-san $vip \
  --cluster \
  --k3s-version $k3sVersion \
  --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=${nodes[master1]}" \
  --merge \
  --sudo \
  --local-path $HOME/.kube/config \
  --ssh-key $HOME/.ssh/$cert_name \
  --context k3s-ha
echo -e "\033[32;5mFirst Node bootstrapped successfully!\033[0m"

################################
#     KUBE-VIP INSTALLATION    #
################################

# Install Kube-VIP for High Availability
if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mCreating Manifest Directory for kube-vip: $HOME/kubernetes/manifests/kube-vip\e[0m"
    mkdir -p $HOME/kubernetes/manifests/kube-vip # Create directory for kube-vip manifest
fi

echo -e "\e[32mInstalling Kube-VIP on Cluster\e[0m"

kubectl k3s-ha # Set context to k3s-ha

kubectl apply -f https://kube-vip.io/manifests/rbac.yaml # Install RBAC
if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mStoring RBAC manifest in $HOME/kubernetes/manifests/kube-vip-rbac.yaml\e[0m"
    curl -sO https://kube-vip.io/manifests/rbac.yaml # Download kube-vip manifest
    mv $HOME/rbac.yaml $HOME/kubernetes/manifests/kube-vip/rbac.yaml # Move kube-vip manifest to directory
fi

curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/kube-vip/kube-vip.yaml # Download kube-vip manifest
sed -i.bak 's/$kube_vip_version/'"$kube_vip_version"'/g; s/$interface/'"$interface"'/g; s/$vip/'"$vip"'/g' kube-vip.yaml
rm kube-vip.yaml.bak # Remove backup file

scp -i $HOME/.ssh/$cert_name $HOME/kube-vip.yaml $user@${nodes[master1]}:~/kube-vip.yaml # Copy kube-vip manifest to master1
ssh $user@${nodes[master1]} 'sudo mkdir -p /var/lib/rancher/k3s/server/manifests' # Create directory for kube-vip manifest
ssh $user@${nodes[master1]} 'sudo mv $HOME/kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml' # Move kube-vip manifest to directory
if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mStoring kube-vip.yaml in $HOME/kubernetes/manifests/kube-vip.yaml\e[0m"
    mv $HOME/kube-vip.yaml $HOME/kubernetes/manifests/kube-vip/kube-vip.yaml # Move kube-vip manifest to directory
else
    rm $HOME/kube-vip.yaml # Remove kube-vip manifest from local machine
fi

kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml
if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mStoring kube-vip-cloud-controller.yaml in $HOME/kubernetes/manifests/kube-vip-cloud-controller.yaml\e[0m"
    curl -sO https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml # Download kube-vip manifest
    mv $HOME/kube-vip-cloud-controller.yaml $HOME/kubernetes/manifests/kube-vip/kube-vip-cloud-controller.yaml # Move kube-vip manifest to directory
else
    rm $HOME/kube-vip-cloud-controller.yaml # Remove kube-vip manifest from local machine
fi

# Apply the load balancer range to kube-vip
kubectl create configmap -n kube-system kubevip --from-literal range-global=$lbrange

echo -e "\033[32;5mKube-VIP installed successfully!\033[0m"

################################
#     METALLB INSTALLATION     #
################################

# Install MetalLB for Load Balancing
echo -e "\e[32mInstalling MetalLB on Cluster\e[0m"
if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mCreating Manifest Directory for MetalLB: $HOME/kubernetes/manifests/metallb\e[0m"
    mkdir -p $HOME/kubernetes/manifests/metallb # Create directory for MetalLB manifest
fi

# Create MetalLB namespace
echo -e "\e[32mCreating MetalLB Namespace\e[0m"
kubectl create namespace metallb-system
echo -e "\033[32;5mMetalLB Namespace created successfully!\033[0m"

# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$metallb_version/config/manifests/metallb-native.yaml

# Wait until a pod has been created for the metallb system, suppress output
echo -e "\e[32mWaiting for MetalLB pod to be created\e[0m"
while [ "$(kubectl get pods -n metallb-system -o jsonpath='{.items[0].metadata.name}' 2>/dev/null )" = "" ]; do
    echo -e "\e[32mMetalLB pod not created, waiting 3 seconds\e[0m"
    sleep 3
done

# Wait for MetalLB to be ready
echo -e "\e[32mWaiting for MetalLB to be ready\e[0m"
kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=component=controller \
                --timeout=120s

# Download ipAddressPool and configure using lbrange above
curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/metallb/metallb.yaml # Download MetalLB manifest
sed -i.bak 's/$lbrange/'"$lbrange"'/g' metallb.yaml # Replace $lbrange with lbrange variable
rm metallb.yaml.bak # Remove backup file

# Apply MetalLB manifest
kubectl apply -f metallb.yaml

if [ $keep_manifestes = "true" ] ; then
    echo -e "\e[32mStoring metallb manifests in $HOME/kubernetes/manifests/metallb\e[0m"    
    curl -sO https://raw.githubusercontent.com/metallb/metallb/$metallb_version/config/manifests/metallb-native.yaml # Download MetalLB manifest
    mv $HOME/metallb-native.yaml $HOME/kubernetes/manifests/metallb/metallb-native.yaml # Move MetalLB manifest to directory
    mv $HOME/metallb.yaml $HOME/kubernetes/manifests/metallb/metallb.yaml # Move MetalLB manifest to directory
else
    rm $HOME/metallb-native.yaml # Remove MetalLB manifest from local machine
    rm $HOME/metallb.yaml # Remove MetalLB manifest from local machine
fi

# Installation complete
echo -e "\033[32;5mMetalLB installed successfully!\033[0m"

#####################################
# K3S INSTALLATION - OTHER MASTERS  #
#####################################

# Install K3S on additional Master Nodes using k3sup
echo -e "\e[32mInstalling K3S on additional Master Nodes:\e[0m"
for node in $(printf "%s\n" "${!masters[@]}" | sort | tail -n +2); do
    echo -e "\e[32mWorking on $node: ${masters[$node]}\e[0m"
    k3sup join \
    --ip ${masters[$node]} \
    --user $user \
    --sudo \
    --k3s-version $k3sVersion \
    --server \
    --server-ip ${nodes[master1]} \
    --ssh-key $HOME/.ssh/$cert_name \
    --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=${masters[$node]}" \
    --server-user $user
    echo -e "\033[32;5mMaster $node joined successfully!\033[0m"
done

#####################################
#    K3S INSTALLATION - WORKERS     #
#####################################

echo -e "\e[32mInstalling K3S on Worker Nodes:\e[0m"
for node in $(printf "%s\n" "${!workers[@]}" | sort); do
    echo -e "\e[32mWorking on $node: ${workers[$node]}\e[0m"
    k3sup join \
    --ip ${workers[$node]} \
    --user $user \
    --sudo \
    --k3s-version $k3sVersion \
    --server-ip ${nodes[master1]} \
    --k3s-extra-args "--node-label longhorn=true --node-label worker=true" \
    --ssh-key $HOME/.ssh/$cert_name
    echo -e "\033[32;5mAgent $node joined successfully!\033[0m"
done

# Main K3S Cluster is now installed and ready for use
echo -e "\e[32mK3S Cluster is now installed and ready for use\e[0m"
echo -e "\e[32mAdditional Installations will now proceed if enabled\e[0m"

#####################################
#       RANCHER INSTALLATION        #
#####################################

if [ $install_rancher = "true" ] ; then
    echo -e "\e[32mInstalling Rancher\e[0m"
    # Install Rancher using helm
    echo -e "\e[32mInstalling Helm\e[0m"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 # Download Helm install script
    chmod 700 get_helm.sh # Make script executable
    ./get_helm.sh # Run Helm install script
    echo -e "\e[32mHelm installed successfully\e[0m"

    echo -e "\e[32mAdding Repos for Rancher and Cert Manager Helm Repo\e[0m"
    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable # Rancher Helm Repo
    helm repo add jetstack https://charts.jetstack.io # Cert Manager Helm Repo
    helm repo update # Update Helm Repos
    echo -e "\e[32mRepos added successfully\e[0m"

    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$cert_manager_version/cert-manager.crds.yaml
    if [ $keep_manifestes = "true" ] ; then
        echo -e "\e[32mStoring cert-manager.crds.yaml in $HOME/kubernetes/manifests/cert-manager/cert-manager.crds.yaml\e[0m"
        curl -sO https://github.com/cert-manager/cert-manager/releases/download/$cert_manager_version/cert-manager.crds.yaml
        mkdir -p $HOME/kubernetes/manifests/cert-manager # Create directory for cert-manager manifest
        mv $HOME/cert-manager.crds.yaml $HOME/kubernetes/manifests/cert-manager/cert-manager.crds.yaml # Move cert-manager manifest to directory
    fi

    echo -e "\e[32mInstalling Cert Manager\e[0m"
    helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace # Install Cert Manager
    echo -e "\e[32mCert Manager installed successfully\e[0m"

    echo -e "\e[32mInstalling Rancher\e[0m"
    helm install rancher rancher-stable/rancher \
    --namespace cattle-system \
    --create-namespace \
    --set hostname=$rancher_hostname \
    --set bootstrapPassword=$rancher_bootstrap_password # Install Rancher

    kubectl -n cattle-system rollout status deploy/rancher # Wait for Rancher to be ready
    echo -e "\e[32mRancher installed successfully\e[0m"

fi

#####################################
#       LONGHORN INSTALLATION       #
#####################################

if [ $install_longhorn = "true" ] ; then
    echo -e "\e[32mInstalling Longhorn\e[0m"
    echo -e "\e[32mInstalling open-iscsi if not already installed\e[0m"
    if ! command -v sudo service open-iscsi status &> /dev/null; then
        sudo apt install -y open-iscsi
    else
        echo -e "\e[32mopen-iscsi already installed\e[0m"
    fi

    echo -e "\e[32mInstalling on Storage Nodes\e[0m"
    for node in $(printf "%s\n" "${!storage[@]}" | sort); do
        echo -e "\e[32mWorking on $node: ${storage[$node]}\e[0m"
        k3sup join \
        --ip ${storage[$node]} \
        --user $user \
        --sudo \
        --k3s-version $k3sVersion \
        --server-ip ${nodes[master1]} \
        --k3s-extra-args "--node-label \"longhorn=true\"" \
        --ssh-key $HOME/.ssh/$cert_name
        echo -e " \033[32;5mAgent $node joined successfully!\033[0m"
    done

    kubectl apply -f https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/longhorn/longhorn.yaml
    if [ $keep_manifestes = "true" ] ; then
        echo -e "\e[32mStoring longhorn.yaml in $HOME/kubernetes/manifests/longhorn/longhorn.yaml\e[0m"
        mkdir -p $HOME/kubernetes/manifests/longhorn # Create directory for longhorn manifest
        curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/longhorn/longhorn.yaml # Download longhorn manifest
        mv $HOME/longhorn.yaml $HOME/kubernetes/manifests/longhorn/longhorn.yaml # Move longhorn manifest to directory
    fi

    echo -e "\e[32mLonghorn installed successfully\e[0m"    
fi

#####################################
#       TRAEFIK INSTALLATION        #
#####################################

if [ $install_traefik = "true" ] ; then
    if [ $keep_manifestes = "true" ] ; then        
        mkdir -p $HOME/kubernetes/manifests/traefik # Create directory for traefik manifest
    fi

    # Hash and base64 encode username and password for traefik using htpasswd
    echo -e "\e[32mHashing and base64 encoding username and password for traefik\e[0m"
    traefik_username_hash=$(echo $traefik_password | htpasswd -ni $traefik_username | base64)
    echo -e "\e[32mInstalling Traefik\e[0m"
    echo -e "\e[32mLoading Helm Repos and updating them\e[0m"
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo add emberstack https://emberstack.github.io/helm-charts # required to share certs for CrowdSec
    helm repo add crowdsec https://crowdsecurity.github.io/helm-charts
    helm repo update
    echo -e "\e[32mHelm Repos loaded and updated successfully\e[0m"

    echo -e "\e[32mCreating namespace\e[0m"
    kubectl create namespace traefik
    echo -e "\e[32mNamespace created successfully\e[0m"

    echo -e "\e[32mDownloading traefik files\e[0m"

    curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/traefik/Helm/traefik-values.yaml    
    sed -i.bak 's/$traefik_ip/'"$traefik_ip"'/g' traefik-values.yaml
    rm traefik-values.yaml.bak

    curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/traefik/traefik.yaml
    sed -i.bak \
    -e 's/$traefik_username_hash/'"$traefik_username_hash"'/g' \
    -e 's/$traefik_secret/'"$traefik_secret"'/g' \
    -e 's/$traefik_domain/'"$traefik_domain"'/g' traefik.yaml
    rm traefik.yaml.bak

    curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/traefik/Helm/cert-manager-values.yaml
    mv cert-manager-values.yaml $HOME/

    curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/traefik/cert-manager.yaml
    sed -i.bak \
    -e 's/$traefik_cf_token/'"$traefik_cf_token"'/g' \
    -e 's/$traefik_letsencrypt_email/'"$traefik_letsencrypt_email"'/g' \
    -e 's/$traefik_cloudflare_email/'"$traefik_cloudflare_email"'/g' \
    -e 's/$traefik_secret/'"$traefik_secret"'/g' \
    -e 's/$traefik_domain/'"$traefik_domain"'/g' cert-manager.yaml
    rm cert-manager.yaml.bak

    mv cert-manager.yaml $HOME/

    echo -e "\e[32mTraefik files downloaded successfully and modified\e[0m"
    
    echo -e "\e[32mInstalling Traefik\e[0m"
    helm install --namespace=traefik traefik traefik/traefik -f traefik-values.yaml
    kubectl apply -f $HOME/traefik.yaml

    echo -e "\e[32mUpgrading cert-manager\e[0m"
    helm upgrade \
    cert-manager \
    jetstack/cert-manager \
    --namespace cert-manager \
    --values cert-manager-values.yaml
    kubectl apply -f $HOME/cert-manager.yaml

    # If install_rancher is true, install the rancher ingress route
    if [ $install_rancher = "true" ] ; then
        echo -e "\e[32mInstalling Rancher Ingress\e[0m"
        curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/traefik/rancher-ingress.yaml
        sed -i.bak \
        -e 's/$traefik_secret/'"$traefik_secret"'/g' \
        -e 's/$traefik_domain/'"$traefik_domain"'/g' rancher-ingress.yaml
        rm rancher-ingress.yaml.bak
        kubectl apply -f rancher-ingress.yaml
    fi

    if [ $keep_manifestes = "true" ] ; then
        echo -e "\e[32mStoring traefik files in $HOME/kubernetes/manifests/traefik\e[0m"
        mv $HOME/traefik-values.yaml $HOME/kubernetes/manifests/traefik/traefik-values.yaml
        mv $HOME/traefik.yaml $HOME/kubernetes/manifests/traefik/traefik.yaml
        mv $HOME/cert-manager-values.yaml $HOME/kubernetes/manifests/cert-manager/cert-manager-values.yaml
        mv $HOME/cert-manager.yaml $HOME/kubernetes/manifests/cert-manager/cert-manager.yaml
        if [ $install_rancher = "true" ] ; then
            mv $HOME/rancher-ingress.yaml $HOME/kubernetes/manifests/traefik/rancher-ingress.yaml
        fi
    else
        rm $HOME/traefik-values.yaml
        rm $HOME/traefik.yaml
        rm $HOME/cert-manager-values.yaml
        rm $HOME/cert-manager.yaml
        if [ $install_rancher = "true" ] ; then
            rm $HOME/rancher-ingress.yaml
        fi
    fi

    echo -e "\e[32mTraefik installed successfully\e[0m"
fi

#####################################
#        PIHOLE INSTALLATION        #
#####################################

if [ $install_pihole = "true" ] ; then
    if [ $keep_manifestes = "true" ] ; then
        echo -e "\e[32mCreating Manifest Directory for pihole: $HOME/kubernetes/manifests/pihole\e[0m"
        mkdir -p $HOME/kubernetes/manifests/pihole # Create directory for pihole manifest
    fi

    echo -e "\e[32mInstalling PiHole\e[0m"
    
    echo -e "\e[32mCreating namespace\e[0m"
    kubectl create namespace pihole
    echo -e "\e[32mNamespace created successfully\e[0m"

    echo -e "\e[32mDownloading PiHole files\e[0m"
    curl -sO https://raw.githubusercontent.com/Lukium/kubernetes/main/k3s/deploy-k3s/manifests/pihole/pihole.yaml
    sed -i.bak \
    -e 's/$traefik_secret/'"$traefik_secret"'/g' \
    -e 's/$traefik_domain/'"$traefik_domain"'/g' \
    -e 's/$pihole_volume_capacity/'"$pihole_volume_capacity"'/g' \
    -e 's/$pihole_webpassword/'"$pihole_webpassword"'/g' \
    -e 's|$pihole_timezone|'"$pihole_timezone"'|g' \
    -e 's/$pihole_ip/'"$pihole_ip"'/g' pihole.yaml
    rm pihole.yaml.bak

    echo -e "\e[32mPiHole files downloaded successfully and modified\e[0m"

    echo -e "\e[32mInstalling PiHole\e[0m"
    kubectl apply -f pihole.yaml
    if [ $keep_manifestes = "true" ] ; then
        echo -e "\e[32mStoring pihole.yaml in $HOME/kubernetes/manifests/pihole/pihole.yaml\e[0m"
        mv $HOME/pihole.yaml $HOME/kubernetes/manifests/pihole/pihole.yaml # Move pihole manifest to directory
    else
        rm $HOME/pihole.yaml
    fi    
    echo -e "\e[32mPiHole installed successfully\e[0m"
fi

if [ $expose_rancher = "true" ] ; then
    echo -e "\e[32mExposing the Rancher Service\e[0m"
    kubectl expose deployment rancher \
    --name rancher-lb \
    --port=443 \
    --type=LoadBalancer \
    -n cattle-system
    echo -e "\e[32mRancher Service exposed successfully\e[0m"
fi

# Kill ssh-agent if use_ssh_passphrase is true
if [ $use_ssh_passphrase = "true" ] ; then
    echo -e "\e[32mKilling ssh-agent\e[0m"
    kill $SSH_AGENT_PID
fi

# Apply StrictHostKeyChecking after script is done based on after_SHKC variable
if [ $no_SHKC = "true" ] ; then
    echo -e "\e[32mApplying StrictHostKeyChecking = $after_SHKC according to after_SHKC variable\e[0m"
    echo "StrictHostKeyChecking $after_SHKC" > $HOME/.ssh/config
fi

# Make recommendations to the user
echo -e "\e[32m   ___  ___  ___  __   __ __  __ __  ___  __  _  __    __  _____  _   __   __  _   __  \e[0m";
echo -e "\e[32m  | _ \| __|/ _/ /__\ |  V  ||  V  || __||  \| || _\  /  \|_   _|| | /__\ |  \| |/' _/ \e[0m";
echo -e "\e[32m  | v /| _|| \__| \/ || \_/ || \_/ || _| | | ' || v || /\ | | |  | || \/ || | ' |\`._\ \e[0m";
echo -e "\e[32m  |_|_\|___|\__/ \__/ |_| |_||_| |_||___||_|\__||__/ |_||_| |_|  |_| \__/ |_|\__||___/ \e[0m";
echo
echo

kubectl get svc -A | grep -e LoadBalancer -e EXTERNAL-IP
echo -e "\e[32mYou should see all your services and their IPs above\e[0m"

echo -e "\e[32mThe following assumes a full install. It's up to you to make adjustments if you did not install all components.\e[0m"
echo -e "\e[32m1. Go to the pihole web interface by visiting http://$pihole_ip/admin\e[0m"
if [ $display_passwords_on_completion = "true" ] ; then
    echo -e "\e[32m2. Login with the password you set for pihole: $pihole_webpassword\e[0m"
else
    echo -e "\e[32m2. Login with the password you set for pihole\e[0m"
fi
echo -e "\e[32m3. Navigate to Local DNS > DNS Records then add the following:\e[0m"
echo -e "\e[32m   - rancher.$traefik_domain with the IP: $traefik_ip\e[0m"
echo -e "\e[32m   - traefik.$traefik_domain with the IP: $traefik_ip\e[0m"
echo -e "\e[32m   - pihole.$traefik_domain with the IP: $traefik_ip\e[0m"
echo -e "\e[32m4. Set your router to use $pihole_ip as your DNS server\e[0m"
echo -e "\e[32m5. Test if you Pihole DNS is working. If so:\e[0m"
echo -e "\e[32m6. Setup the Rancher UI at https://rancher.$traefik_domain\e[0m"
if [ $display_passwords_on_completion = "true" ] ; then
    echo -e "\e[32m   - Use the bootstrap password you set for rancher: $rancher_bootstrap_password\ to setup your passworde[0m"
else
    echo -e "\e[32m   - Use the bootstrap password you set for rancher to setup your password\e[0m"
fi
echo -e "\e[32m   - You will probably want to navigate to the Longhorn UI from within Rancher, then:\e[0m"
echo -e "\e[32m     - Click on Node > Select all Worker (non storage) Nodes > Click Edit Node > Disable Node Scheduling\e[0m"
echo -e "\e[32m7. You can view your traefik dashboard by visiting: https://traefik.$traefik_domain/dashboard/\e[0m"
if [ $display_passwords_on_completion = "true" ] ; then
    echo -e "\e[32m   - Use the username and password you set for traefik: username: $traefik_username password: $traefik_password \e[0m"
else
    echo -e "\e[32m   - Use the username and password you set for traefik: username: $traefik_username\e[0m"
fi
echo -e "\e[32m8. You can view your pihole dashboard by visiting: https://pihole.$traefik_domain/admin\e[0m"

# Unset all variables set in this script
echo -e "\e[32mUnsetting all variables\e[0m"
unset nodes masters agents storage workers k3sVersion cert_manager_version install_rancher rancher_hostname rancher_bootstrap_password install_longhorn install_traefik traefik_ip traefik_username traefik_password traefik_domain traefik_cf_token traefik_secret traefik_letsencrypt_email traefik_cloudflare_email install_pihole pihole_volume_capacity pihole_webpassword pihole_timezone pihole_ip use_ssh_passphrase copy_ssh_id cert_name no_SHKC after_SHKC keep_manifestes user interface vip lbrange ssh_agent_output SSH_AGENT_PID traefik_username_hash
