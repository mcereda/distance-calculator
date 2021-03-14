variable "ec2_instance_profile" {
  default     = ""
  description = "(Optional) The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. Ensure your credentials have the correct permission to assign the instance profile according to the EC2 documentation, notably iam:PassRole. If not specified, a new one with RO permissions on EC2 instances will be created."
}
variable "ec2_instance_type" {
  default = "t2.micro"
  description = "(Optional) The type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance. Defaults to t2.micro."
}
variable "ec2_name" {
  default     = null
  description = " (Optional, Forces new resource) The name of the security group. If omitted, Terraform will assign a random, unique name."
}
variable "ec2_sg_name" {
  default     = null
  description = " (Optional, Forces new resource) The name of the security group. If omitted, Terraform will assign a random, unique name."
}
variable "ec2_sg_tags" {
  default     = {}
  description = "(Optional) A mapping of tags to assign to the new SG."
}
variable "ec2_subnet_id" {
  default     = ""
  description = "(Optional) The VPC Subnet ID to launch the new EC2 instance in. If no value is given, a new one will be created."
}
variable "ec2_tags" {
  default     = {}
  description = "(Optional) A mapping of tags to assign to the new EC2 instance."
}
variable "lb_name" {
  default     = null
  description = "(Optional) The name of the new LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen. If not specified, Terraform will autogenerate a name beginning with tf-lb"
}
variable "lb_security_groups" {
  default     = []
  description = "(Optional) A list of security group IDs to assign to the new LB."
}
variable "lb_subnet_ids" {
  default     = []
  description = "(Optional) A list of subnet IDs to attach to the new LB. Subnets cannot be updated for Load Balancers of type network. Changing this value for load balancers of type network will force a recreation of the resource."
}
variable "lb_tags" {
  default     = {}
  description = "(Optional) A mapping of tags to assign to the new LB."
}
variable "vpc_id" {
  default     = ""
  description = "(Optional) The VPC Subnet ID to launch the new EC2 instance in. If no value is given, a new one will be created."
}
