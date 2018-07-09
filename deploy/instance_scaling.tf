variable "numOfInstanceScaleUp" {
  default = "1"
}
variable "numOfInstanceScaleDown" {
  default = "-1"
}


resource "aws_autoscaling_policy" "instance_scale_up_policy" {
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.meetup-ecs-asg.name}"
  cooldown               = "300"
  name                   = "${aws_ecs_cluster.meetup-cluster.name}-ASG-ScaleUp-Policy"
  scaling_adjustment     = "${var.numOfInstanceScaleUp}"
  depends_on = ["aws_autoscaling_group.meetup-ecs-asg"]
}

resource "aws_autoscaling_policy" "instance_scale_down_policy" {
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.meetup-ecs-asg.name}"
  cooldown               = "300"
  name                   = "${aws_ecs_cluster.meetup-cluster.name}-ASG-ScaleDown-Policy"
  scaling_adjustment     = "${var.numOfInstanceScaleDown}"
  depends_on = ["aws_autoscaling_group.meetup-ecs-asg"]
}

resource "aws_cloudwatch_metric_alarm" "instance_scaling_cpu_high_alert" {
  actions_enabled     = true
  alarm_actions       = ["${aws_autoscaling_policy.instance_scale_up_policy.arn}","${aws_sns_topic.instance_scaleupdown_sns.arn}"]
  alarm_description   = "${aws_ecs_cluster.meetup-cluster.name}-InstanceScaling-CPU-HighAlert"
  alarm_name          = "${aws_ecs_cluster.meetup-cluster.name}-InstanceScaling-CPU-HighAlert"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.meetup-ecs-asg.name}"
  }

  evaluation_periods = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "60"
  statistic          = "Average"
  threshold          = "80"
}

resource "aws_cloudwatch_metric_alarm" "instance_scaling_cpu_low_alert" {
  actions_enabled     = true
  alarm_actions       = ["${aws_autoscaling_policy.instance_scale_down_policy.arn}","${aws_sns_topic.instance_scaleupdown_sns.arn}"]
  alarm_description   = "${aws_ecs_cluster.meetup-cluster.name}-InstanceScaling-CPU-LowAlert"
  alarm_name          = "${aws_ecs_cluster.meetup-cluster.name}-InstanceScaling-CPU-LowAlert"
  comparison_operator = "LessThanOrEqualToThreshold"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.meetup-ecs-asg.name}"
  }

  evaluation_periods = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"

  period             = "120"
  statistic          = "Average"
  threshold          = "20"
}

resource "aws_sns_topic" "instance_scaleupdown_sns" {
  display_name = "${aws_ecs_cluster.meetup-cluster.name}-SNS-Alert"
  name         = "${aws_ecs_cluster.meetup-cluster.name}-SNS-Alert"
}

resource "aws_autoscaling_notification" "instance_autoscaling_notification" {
  group_names   = ["${aws_autoscaling_group.meetup-ecs-asg.name}"]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]
  topic_arn     = "${aws_sns_topic.instance_scaleupdown_sns.arn}"
}
