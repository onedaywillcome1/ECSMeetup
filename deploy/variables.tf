variable "ecs_cluster_name" {
  default = "Meetup-Demo"
}
variable "serviceName" {
 default = "MeetupHelloWorld"
}
variable "aws_region" {
  default = "us-east-1"
}
variable "key_name" {
  default = "ECSMeetupDemo"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "instance_type" {
  default = "t2.medium"
}
variable "minInstanceNum" {
  default = "1"
}
variable "desiredInstanceNum" {
  default = "1"
}
variable "maxInstanceNum" {
  default = "2"
}
variable "privatesubnet" {
  type = "list"
  default = ["subnet-0514bd2b","subnet-f8e290b2"]
}
variable "publicsubnet" {
  type = "list"
  default = ["subnet-71e24a5f","subnet-e8ff8da2"]
}
variable "vpcid" {
  default = "vpc-94e615ee"
}

variable "image_url" {
  default = "603826100439.dkr.ecr.us-east-1.amazonaws.com/meetuphelloworld:latest"
}

variable "container_port" {
  default = "8080"
}
variable "memorySoftLimit" {
  default = "750"
}
variable "memoryHardLimit" {
  default = "850"
}

variable "cpu" {
  default = "750"
}
variable "desiredTaskNum" {
  default = "2"
}
variable "maxTaskNum" {
  default = "3"
}
variable "minTaskNum" {
  default = "1"
}
variable "priority_number" {
  default = "1"
}
variable "listener_url" {
  default = ""
}




