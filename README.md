# Distance calculator

Simple web service that accepts two distances and returns the total distance deployed on AWS.

User must specify units for both **and** a return unit for their sum.

## Todo

1. [] create the webapp - python + flask

   1. [] create basic working version
   1. [] fix to adhere to the goals

1. [] dockerize the app
1. [] create a free tier host in AWS to host and test the app
1. [] improve it

   1. [] create IaC
   1. [] create K8S manifest
   1. [] maintainability - move to helm chart
   1. [] reliability - move to ECS/Fargate? EKS?
   1. [] improve the app
