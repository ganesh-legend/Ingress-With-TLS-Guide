# Ingress-With-TLS-Guide-on-AWS

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

### 1) Install Docker 
_Note: Always install docker from official docker page_

Kind cluster run as docker container.
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

