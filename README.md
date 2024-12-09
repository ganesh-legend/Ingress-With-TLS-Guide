# Ingress-With-TLS-Guide-on-AWS

## Introduction
1) We are using **Kind K8s cluster** for this demonstration.
2) We are using **Let's encrypt** which is free open source zero benefit **Certificate Authority** to issue **certificate**.

#

## Notes: 
1) Don't try it on **local machine**. You will waste your time by putting your efforts. Local machine has **private IP** and you will not get certificate against private IP.
2) Here we are using **kind k8s cluster** and it also has private IP like **minikube k8s cluster** but kind supports **port-forwarding to Host(EC2 instance)** by passing **config file** while creating kind cluster which minikube doesn't do. So, we can use Host public IP as ingress IP. So, certificate will be issued to **domain name** when we map this IP in **Domain provider interface.**
3) While following given steps, you should have patience. Take it carefully.

#

### Prerequisite:
1) **AWS EC2 instance Ubuntu 22.04.LTS** with **t2.large** or **t3.large** instance type.
2) Your personal **domain** from domain provider (like **Godaddy**,**Route53**)

#

Assuming that we have all things mentioned in above.
Let's start 

### 1) Use Terminal (_to connect to server_)
Connect to server using any tool like **putty, mobaxterm** and  run given command to update package repository.
```bash
sudo apt-get update
```

#

### 2) Install Docker 
_Note: Always install docker from official docker page_

We need docker to be installed because **Kind cluster** run as **docker container**.
For the time, Copy from here
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER
```
After installing docker,
You need to disconnect from your terminal and reconnect. _(Basically you will get access to docker.)_

### 3) Install kubectl, kind and create cluster using port-forwarding config file.

1) Kubectl is a tool to communicate with cluster.
```bash
sudo snap install kubectl --classic
```

2) Kind is a tool to create local K8s cluster.
```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

3) Cluster creation with port-forwading to Host using config file.
i) -----> create file with name **kind-ingress-config**  _(file name can be any)_
```bash
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```
ii) -----> create cluster
```bash
kind create cluster --name=kind-ingress-cluster --config=kind-ingress-config
```
##### You will be done here for cluster creation.
