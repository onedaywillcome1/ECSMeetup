terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "meetup-ecs-demo-12345"
    key = "meetupdemo"
  }
}

provider "aws" {
  region = "${var.aws_region}"
}

data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["*-amazon-ecs-optimized"]
  }
}

resource "aws_ecs_cluster" "meetup-cluster" {
  name = "${var.ecs_cluster_name}"
}

resource "aws_launch_configuration" "ecs" {
  image_id             = "${data.aws_ami.ecs_ami.id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.meetup-security-group.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.meetup-cluster-profile.name}"

  user_data = <<EOF
    #cloud-config
    runcmd:
      - mkdir -p /etc/ecs
      - echo ECS_CLUSTER=${aws_ecs_cluster.meetup-cluster.name} > /etc/ecs/ecs.config
      - echo ECS_ENGINE_TASK_CLEANUP_WAIT_DURATION=30m >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "meetup-ecs-asg" {
  name = "${var.ecs_cluster_name}-ASG"
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  vpc_zone_identifier = ["${var.privatesubnet}"]
  min_size = "${var.minInstanceNum}"
  max_size = "${var.maxInstanceNum}"
  desired_capacity = "${var.desiredInstanceNum}"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "MeetupECS-ASG"
  }
}

resource "aws_iam_instance_profile" "meetup-cluster-profile" {
  name = "ecs-${var.ecs_cluster_name}-profile"
  role = "${aws_iam_role.meetup-cluster-role.name}"
}

resource "aws_iam_role" "meetup-cluster-role" {
  name = "ecs-${var.ecs_cluster_name}-role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
 {
   "Effect": "Allow",
   "Principal": {
     "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
  }
  ]
 }
EOF
}


resource "aws_iam_role_policy" "meetup-cluster-policy" {
  name = "ecs-${var.ecs_cluster_name}-policy"
  role = "${aws_iam_role.meetup-cluster-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "cloudwatch:*",
        "s3:*",
        "sns:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_security_group" "meetup-security-group" {
  name = "ecs-${var.ecs_cluster_name}-sg"
  description = "Allows ports 32768-65535 for clusters"
  vpc_id = "${var.vpcid}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

