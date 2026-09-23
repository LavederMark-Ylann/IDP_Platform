Fresh after Ubuntu 26.04 install through WSL

#Config
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
lsmod | grep br_netfilter

ls /run/containerd/containerd.sock
```
/run/containerd/containerd.sock
```
sudo ufw allow 6443/tcp
sudo apt install cri-tools

# Install Containerd
sudo apt install -y apt-transport-https ca-certificates curl gpg gnupg lsb-release ufw
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg*
sudo apt update
sudo apt install -y containerd.io

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet


#Installation
sudo kubeadm init
preflight Some fatal errors occurred:
ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
sudo sysctl -w net.ipv4.ip_forward=1

sudo kubeadm init
error: error execution phase wait-control-plane: cannot obtain client without bootstrap: could not bootstrap the admin user in file admin.conf: unable to create ClusterRoleBinding: Post "https://172.30.230.200:6443/apis/rbac.authorization.k8s.io/v1/clusterrolebindings?timeout=10s": dial tcp 172.30.230.200:6443: connect: connection refused
To see the stack trace of this error execute with --v=5 or higher

#investigating
sudo ls -la /etc/kubernetes/manifests/
```
drwxrwxr-x 2 root root 4096 Sep 21 14:49 .
drwxrwxr-x 4 root root 4096 Sep 21 14:49 ..
-rw-r--r-- 1 root root    0 Aug 26 20:11 .kubelet-keep
-rw------- 1 root root 2608 Sep 21 14:49 etcd.yaml
-rw------- 1 root root 3964 Sep 21 14:49 kube-apiserver.yaml
-rw------- 1 root root 3115 Sep 21 14:49 kube-controller-manager.yaml
-rw------- 1 root root 1726 Sep 21 14:49 kube-scheduler.yaml
```
sudo ss -lntp | grep 6443
```
(nothing, so answers)
```
sudo journalctl -u kubelet -n 100 --no-pager
```
Sep 21 15:54:22 Blaikies kubelet[11569]: E0921 15:54:22.223283   11569 run.go:72] "command failed" err="failed to run Kubelet: running with swap on is not supported, please disable swap or set --fail-swap-on flag to false"
Sep 21 15:54:22 Blaikies systemd[1]: kubelet.service: Main process exited, code=exited, status=1/FAILURE
Sep 21 15:54:22 Blaikies systemd[1]: kubelet.service: Failed with result 'exit-code'.
```
Turns out, the warning in the beginning
```
[WARNING Swap]: swap is supported for cgroup v2 only. The kubelet must be properly configured to use swap. Please refer to https://kubernetes.io/docs/concepts/architecture/nodes/#swap-memory, or disable swap on the node
```
![[Pasted image 20260921160025.png]]
cgroupv1 has been deprecated since 1.35, so kubeadm should bootstart a cluster with v2. Even though, it seems like the swap has to be configured, but then the [link given](https://kubernetes.io/docs/concepts/architecture/nodes/#swap-memory) looks dead, as the anchor doesn't go to any title and the term "swap" isn't present in the wiki page.
To fix this :
swapon --show
```
NAME     TYPE      SIZE USED PRIO
/dev/sdc partition   5G   0B   -2
```

sudo swapoff -a
swapon --show
```
(nothing)
```

Following this, another error has appeared
```
Sep 21 16:03:53 Blaikies kubelet[11673]: I0921 16:03:53.460419   11673 kubelet.go:3343] "Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
```

As crictl returned the 4 containers making the control plane, I thought that restarting the service would have been enough, which proved me right

```
sudo crictl ps
WARN[0000] Config "/etc/crictl.yaml" does not exist, trying next: "/usr/bin/crictl.yaml"
WARN[0000] runtime connect using default endpoints: [unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead.
WARN[0000] Image connect using default endpoints: [unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock unix:///var/run/cri-dockerd.sock]. As the default settings are now deprecated, you should set the endpoint instead.
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD                                NAMESPACE
8077f4e779285       1fabf80a1273a       12 minutes ago      Running             kube-scheduler            0                   ef40383acc748       kube-scheduler-blaikies            kube-system
b0dbf2cb289f8       364b3c3d9ec19       12 minutes ago      Running             kube-controller-manager   0                   8ecc0be81797c       kube-controller-manager-blaikies   kube-system
f01beeda167a3       bec5f0e1e2eeb       12 minutes ago      Running             kube-apiserver            0                   040c7c1663048       kube-apiserver-blaikies            kube-system
c7cf76b6213ae       270fbeb697171       12 minutes ago      Running             etcd                      0                   cbc9a9e1ef53b       etcd-blaikies                      kube-system
```
sudo crictl logs f01beeda167a3
```
...
I0921 06:55:07.164705       1 storage_scheduling.go:189] created PriorityClass system-node-critical with value 2000001000
I0921 06:55:07.170211       1 storage_scheduling.go:189] created PriorityClass system-cluster-critical with value 2000000000
I0921 06:55:07.170241       1 storage_scheduling.go:205] all system priority classes are created successfully or already exist.
I0921 06:55:07.786117       1 controller.go:667] quota admission added evaluator for: roles.rbac.authorization.k8s.io
I0921 06:55:07.833140       1 controller.go:667] quota admission added evaluator for: rolebindings.rbac.authorization.k8s.io
I0921 06:55:07.962859       1 alloc.go:329] "allocated clusterIPs" service="default/kubernetes" clusterIPs={"IPv4":"10.96.0.1"}
W0921 06:55:07.972584       1 lease.go:270] Resetting endpoints for master service "kubernetes" to [172.30.230.200]
I0921 06:55:07.976609       1 controller.go:667] quota admission added evaluator for: endpoints
I0921 06:55:07.983808       1 controller.go:667] quota admission added evaluator for: endpointslices.discovery.k8s.io
I0921 06:55:08.831988       1 controller.go:667] quota admission added evaluator for: serviceaccounts
I0921 06:55:14.927892       1 cidrallocator.go:278] updated ClusterIP allocator for Service CIDR 10.96.0.0/12
I0921 06:55:14.931321       1 cidrallocator.go:278] updated ClusterIP allocator for Service CIDR 10.96.0.0/12
I0921 07:05:06.164773       1 cidrallocator.go:278] updated ClusterIP allocator for Service CIDR 10.96.0.0/12
```
sudo systemctl restart kubelet

But as many errors came up, I thought it would be better to do a fresh installation to be sure nothing else got corrupted on the way.

sudo kubeadm reset -f

sudo kubeadm init
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join :6443 --token token \
        --discovery-token-ca-cert-hash sha256:hash
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes
```
NAME       STATUS     ROLES           AGE     VERSION
blaikies   NotReady   control-plane   7h50m   v1.37.0
```
Now it seems like everything works in order.

The next step will be setting up local stack in this newly created Kubernetes cluster.