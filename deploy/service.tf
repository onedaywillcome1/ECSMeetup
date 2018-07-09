data "template_file" "meetup-task-definition" {
  template = "${file("task_definition.json")}"

  vars {
    image_url       = "${var.image_url}"
    td_name         = "${var.serviceName}"
    loggroup_region = "${var.aws_region}"
    service_name    = "${var.serviceName}"
    container_port  = "${var.container_port}"
    memorySoftLimit = "${var.memorySoftLimit}"
    memoryHardLimit = "${var.memoryHardLimit}"
    cpu             = "${var.cpu}"
  }
}

resource "aws_ecs_task_definition" "meetup-taskdefinition" {
  family                = "${var.serviceName}"
  container_definitions = "${data.template_file.meetup-task-definition.rendered}"
  depends_on = [
    "data.template_file.meetup-task-definition"
  ]
}

resource "aws_ecs_service" "meetup-service" {
  name            = "${var.serviceName}"
  cluster         = "${var.ecs_cluster_name}"
  task_definition = "${var.serviceName}"
  iam_role        = "${aws_iam_role.meetup-cluster-role.arn}"
  desired_count   = "${var.desiredTaskNum}"


  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.meetup-alb-tg.arn}"
    container_name   = "${var.serviceName}"
    container_port   = "${var.container_port}"
  }

  depends_on = [
    "aws_ecs_task_definition.meetup-taskdefinition",
    "aws_alb_target_group.meetup-alb-tg",
    "aws_alb.meetup-alb"
  ]
}

resource "aws_appautoscaling_target" "appautoscaling_target" {
  max_capacity       = "${var.maxTaskNum}"
  min_capacity       = "${var.minTaskNum}"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.meetup-service.name}"
  role_arn           = "${aws_iam_role.meetup-cluster-role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_cloudwatch_log_group" "service_log_group" {
  name = "${var.serviceName}-LogGroup"
}
