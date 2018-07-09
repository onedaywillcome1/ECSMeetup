resource "aws_alb" "meetup-alb" {
  name            = "${var.ecs_cluster_name}-ALB"
  internal        = false
  security_groups = ["${aws_security_group.meetup-alb-sg.id}"]
  subnets         = ["${var.publicsubnet}"]
  tags {
    Name          = "${var.ecs_cluster_name}-alb"
  }
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_alb_target_group" "meetup-alb-tg" {
  name     = "${var.ecs_cluster_name}-TG"
  port     = "${var.container_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpcid}"

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = "60"
    timeout = "30"
    unhealthy_threshold = "3"
    healthy_threshold = "3"
  }

  tags {
    Name   = "${var.ecs_cluster_name}-tg"
  }
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_alb_listener" "meetup-alb-listener" {
  load_balancer_arn = "${aws_alb.meetup-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action  {
    target_group_arn = "${aws_alb_target_group.meetup-alb-tg.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "meetup-alb-sg" {
  name        = "${var.ecs_cluster_name}-alb-sg"
  description = "Allows ports for meetup alb"
  vpc_id      = "${var.vpcid}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

