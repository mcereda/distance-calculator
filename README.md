# Distance calculator

Simple web service that accepts two distances and returns the total distance deployed on AWS.

User must specify units for both **and** a return unit for their sum.

## Todo

1. create the webapp - python + flask

   1. done - create basic working version
   1. fix to adhere to the goals

1. done - dockerize the app
1. done - create a free tier host in AWS to host
1. test the app
1. improve it

   1. done - create IaC
   1. create K8S manifest
   1. maintainability - move to helm chart
   1. reliability - move to ECS/Fargate? EKS?
   1. improve the app

## Current status

The LoadBalancer seems unable to connect to the app, but I need to configure remote access to the host to debug.

## Testbench configuration

- awscli 2.0.60
- terraform 0.14.7
