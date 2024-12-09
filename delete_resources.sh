#!/bin/bash

kubectl delete -f issuer.yaml
kubectl delete -f certificate.yaml
kubectl delete -f ingress.yaml
