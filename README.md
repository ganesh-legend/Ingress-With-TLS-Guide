# Ingress-With-TLS-Guide-on-AWS

## Introduction
1) We are using **Kind K8s cluster** for this demonstration.
2) We are using **Let's encrypt** which is free open source zero benefit **Certificate Authority** to issue **certificate**.

#

## Notes: 
1) Don't try it on **local machine**. You will waste your time by putting your efforts. Local machine has **private IP** and you will not get certificate against private IP.
2) Here we are using **kind k8s cluster** and it also has private IP like **minikube k8s cluster** but kind supports **port-forwarding to Host(EC2 instance)** by passing **config file** while creating kind cluster which minikube doesn't do. So, we can use Host public IP as ingress IP. So, certificate will be issued to **domain name** when we map this IP in **Domain provider interface.**
3) Make sure 80 and 443 port are available for your EC2 instance in security group.
4) While following given steps, you should have patience. Take it carefully.

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
##### You are done here for cluster creation.

#

### 4) Deploy ingress controller

You will get yml file named **deploy_ingress_nginx_controller_on_kind.yml** in this repo to deploy ingress controller. execute next command
```bash
kubectl apply -f deploy_ingress_nginx_controller_on_kind.yml
```
check if ingress controller pod is running using next command.
```bash
kubectl get all -n ingress-nginx
```

#

### 5) Deploy Cert-Manager 

You will get yml file named **deploying_cert-manager_on_kind.yaml** in this repo to deploy cert-manager controller. execute next command
```bash
kubectl apply -f deploying_cert-manager_on_kind.yaml
```
check if cert manager pods are running using next command.
```bash
kubectl get all -n cert-manager
```

#

### 6) Create ingress yaml file 

You will get yml file named **ingress.yaml** in this repo to create ingress resource.
You can make changes in this file as per your requirements.

or

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-apps-ingress
  namespace: default  # Ensure this is the namespace where your services and Ingress are defined
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"  # Should match the name of your ClusterIssuer
    acme.cert-manager.io/http01-edit-in-place: "true"
spec:
  ingressClassName: nginx  # Ensure this matches the class name of your Ingress Controller
  tls:
  - hosts:
    - ekart.ganeshpawar.one
    - nginx.ganeshpawar.one  # The domain for which you want to use TLS
    secretName: tls-secret  # Must match the secret name defined in the Certificate resource
  rules:
  - host: ekart.ganeshpawar.one  # The domain to route traffic to
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ekart-app-service  # Ensure this matches the name of your service
            port:
              number: 80  # Ensure this matches the port your service listens on
  - host: nginx.ganeshpawar.one  # The domain to route traffic to
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service  # Ensure this matches the name of your service
            port:
              number: 80  # Ensure this matches the port your service listens on
```

#

### 7) Create staging and production ClusterIssuer to generate certificate.

You will get yml file named **staging-issuer.yaml** in this repo to create staging resource.
You will get yml file named **prod-issuer.yaml** in this repo to create ingress resource.
You can make changes in this file as per your requirements.

or 

staging-issuer.yaml
```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: admin@gmail.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging  # Ensure this matches the secret used for the private key
    solvers:
    - http01:
        ingress:
          class: nginx  # Make sure this matches the class of your Ingress Controller
```

prod-issuer.yaml
```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod  # Ensure this matches the secret used for the private key
    solvers:
    - http01:
        ingress:
          class: nginx  # Make sure this matches the class of your Ingress Controller
```

#

### 8) Deploy some deployments and services

i) You will get deployment.yml and service.yml file. Deploy those using next commands

```bash
kubectl apply -f deployment.yml
kubectl apply -f service.yml
```

ii) You will get nginx-dep-svc.yaml file. Deploy this using next command

```bash
kubectl apply -f nginx-dep-svc.yaml
```


#

### 9) Map IPv4 of host machine in domain name provider. 
1) Go to your domain name provider and add records.
2) If you have multiple host names (e.g. nginx.ganeshpawar.one, demo.ganeshpawar.one) in ingress.yml file then you need add records for this in your domain name provider with same IP.

#

### 10) Demonstration of Ingress and staging-issuer

First, You need to deploy staging issuer yaml file.

```bash
kubectl apply -f staging-issuer.yaml
```
to know about staging issuer is in TRUE state.
```bash
kubectl get clusterissuer
```

then deploy ingress yaml file.

```bash
kubectl apply -f ingress.yaml
```

to know ingress deployed
```bash
kubectl get ing
```

once you deploy these two resources
Wait for while until certificate will get into TRUE state. It will take some time. So, have some patience.

To check secret is created.
```bash
kubectl get secret
```

To check certificate in TRUE state, you run below command

```bash
kubectl get certificate
```

Now if the certificate in TRUE state. DO next stage.

#

### 11) Demonstration of ingress and prod issuer 

First, You need to deploy prod issuer yaml file.

```bash
kubectl apply -f prod-issuer.yaml
```
to know about prod issuer is in TRUE state.
```bash
kubectl get clusterissuer
```

then edit and deploy ingress yaml file.

```bash
vi ingress.yaml
```

change one line's field in ingress yaml

```bash
cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

again apply to ingress yaml

```bash
kubectl apply -f ingress.yaml
```

once you deploy these two resources
Wait for while until certificate will get into TRUE state. It will take some time. So, have some patience.

To check secret is created.
```bash
kubectl get secret
```

To check certificate in TRUE state, you run below command

```bash
kubectl get certificate
```

Now if the certificate in TRUE state then your Let's Encrypt certificate is issued to your domain names.

##### Note: Certificates are issued against domain names not IP addresses.

Type your domain names in your browser and see your domain name is having secure connection.

### Some Command for troubleshooting......

```bash
kubectl describe certificate
```

```bash
kubectl get certificaterequest
```

```bash
kubectl describe certificaterequest
```

```bash
kubectl describe certificate
```

```bash
kubectl logs pod cert_manager-pod-name -n cert-manager
```


## Thanks, we are done here........!
## Happy Learning...😊
