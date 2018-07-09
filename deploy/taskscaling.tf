variable "cpuUsageHighEvaluation_periods" {
  default = "2"
}
variable "cpuUsageLowEvaluation_periods" {
  default = "7"
}

variable "cpuUsageHighPeriod" {
  default = "60"
}
variable "cpuUsageLowPeriod" {
  default = "60"
}

variable "cpuUsageHighThreshold" {
  default = "75"
}
variable "cpuUsageLowThreshold" {
  default = "15"
}

variable "statisticType" {
  default = "Average"
}

variable "numOfTaskScaleUp" {
  default = "1"
}
variable "numOfTaskScaleDown" {
  default = "-1"
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_usage_high" {
  alarm_name              = "${var.serviceName}-cpu-usage-above-${var.cpuUsageHighThreshold}"
  alarm_description       = "This alarm monitors ${var.serviceName} cpu usage for scaling up"
  comparison_operator     = "GreaterThanOrEqualToThreshold"
  evaluation_periods      = "${var.cpuUsageHighEvaluation_periods}"
  metric_name             = "CPUUtilization"
  namespace               = "AWS/ECS"
  period                  = "${var.cpuUsageHighPeriod}"
  statistic               = "${var.statisticType}"
  threshold               = "${var.cpuUsageHighThreshold}"
  alarm_actions           = ["${aws_appautoscaling_policy.cpu_usage_scale_up.arn}"]

  dimensions {
    ServiceName           = "${var.serviceName}"
    ClusterName           = "${var.ecs_cluster_name}"
  }
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_usage_low" {
  alarm_name              = "${var.serviceName}-cpu-usage-below-${var.cpuUsageLowThreshold}"
  alarm_description       = "This alarm monitors ${var.serviceName} cpu usage for scaling down"
  comparison_operator     = "LessThanOrEqualToThreshold"
  evaluation_periods      = "${var.cpuUsageLowEvaluation_periods}"
  metric_name             = "CPUUtilization"
  namespace               = "AWS/ECS"
  period                  = "${var.cpuUsageLowPeriod}"
  statistic               = "${var.statisticType}"
  threshold               = "${var.cpuUsageLowThreshold}"
  alarm_actions           = ["${aws_appautoscaling_policy.cpu_usage_scale_down.arn}"]

  dimensions {
    ServiceName           = "${var.serviceName}"
    ClusterName           = "${var.ecs_cluster_name}"
  }
}

resource "aws_appautoscaling_policy" "cpu_usage_scale_up" {
  name                    = "${var.serviceName}-cpu-scale-up-policy"
  resource_id             = "service/${var.ecs_cluster_name}/${aws_ecs_service.meetup-service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = "${var.numOfTaskScaleUp}"
    }
  }

  depends_on = ["aws_appautoscaling_target.appautoscaling_target"]
}

resource "aws_appautoscaling_policy" "cpu_usage_scale_down" {
  name                    = "${var.serviceName}-cpu-scale-down-policy"
  resource_id             = "service/${var.ecs_cluster_name}/${aws_ecs_service.meetup-service.name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"
  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment = "${var.numOfTaskScaleDown}"
    }
  }
  depends_on = ["aws_appautoscaling_target.appautoscaling_target"]
}
