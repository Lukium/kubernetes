# Coming Soon

Full readme coming soon, in the meantime, the script is well commented and should be suffucient for general use.

## IMPORTANT:
- Remember to set +x permission on the script before running
- Run from $HOME

## Features:
Deploy in one shot:
- K3S to master, storage(longhorn), and worker(non-longhorn) nodes
- Kube-VIP for HA on the master nodes
- MetalLB for loadbalancing services
- Rancher (including cert-manager) using bootstrap password/domain/desired IP set by user in script then exposes it on desired IP using MetalLB
- Longhorn on any nodes setup as storage nodes
- Traefik (including letsencrypt certificates) using domain/secret/user/pass/cf_token/email/desired IP provided in script (the script will automatically hash and base64 encode the user:pass combo), then expose it on desired IP using MetalLB
- PiHole using desired storage capacity/webpassword/timezone/desired IP set by user in script, then exposes it on desired IP using MetalLB

### Additionaly:
- No file editing is needed as everything that would need to be edited in any manifest is set in the script and applied at runtime
- User can choose which components to install, but I have not added much error handling. So installing certain combinations of components will definitely break things (for example trying to install pihole without installing traefik or longhorn)
- It has an option to keep all manifest files, that way if the user needs to change something they should be able to easily modify and redeploy the yaml
- Deployments for same components have been set into single yaml files for ease of editing
- ssh-key passphrase only needs to be entered once if there's one

Things I'm probably gonna work in the future:
- Add some error handling
- Add authentik
- Add an option to run subsequent installs using the currently saved files.

This script is heavily inspired by [Jim's Garage - Youtube](https://youtube.com/@jims-garage) | [Jim's Garage - Github](https://github.com/JamesTurland/JimsGarage/tree/main/Kubernetes/K3S-Deploy)
