#!/bin/bash

kubectl apply -f issuer.yaml
sleep 5
kubectl apply -f certificate.yaml
sleep 2
kubectl apply -f ingress.yaml
