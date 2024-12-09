# Ingress-With-TLS-Guide-on-AWS

## Notes: 
1) Don't try it on local machine. You will waste your time by putting your efforts. Local machine has private IP and you will not get certificate against private IP.
2) Here we are using **kind k8s cluster** and it also has private IP alike minikube but it supports port-forwarding to Host(EC2 instance) by passing config file while creating kind cluster. So, we can use Host public IP as ingress IP. So, certificate will be issued to **domain name**.
3) While following given steps, you should have patience. Take it carefully.
#

### Prerequisite:
1) **AWS EC2 instance** with **t2.large** or **t3.large** instance type.
2) Your personal **domain** from domain provider (like **Godaddy**,**Route53**)

#

Assuming that we have all things mentioned in above.
Let's start 
