# launch template for wordpress

resource "aws_launch_template" "wordpress-launch-template" {
  //image_id               = lookup(var.Images, "US_Office", "Ubuntu_Server_22")
  image_id               = var.image["US_Office"]["Ubuntu_Server_22"]
  instance_type          = var.instance_type["small"]
  vpc_security_group_ids = [var.webserver_sg-id] //[aws_security_group.webserver-sg.id]

  /*   iam_instance_profile {
    name = aws_iam_instance_profile.ip.id
  } */

  key_name = var.keypair


  placement {
    availability_zone = "random_shuffle.az_list.result"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.tag_prefix}_wordpress-launch-template"
      },
    )

  }

  # create a file called wordpress.sh and copy the wordpress userdata from project 15 into it.
  user_data = filebase64("${path.module}/userdata/wordpress.sh")
}


# ---- Autoscaling for wordpress application

resource "aws_autoscaling_group" "wordpress-asg" {
  name                      = "wordpress-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [

    var.private_subnets[0].id,
    var.private_subnets[1].id
  ]


  launch_template {
    id      = aws_launch_template.wordpress-launch-template.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "wordpress-asg"
    propagate_at_launch = true
  }
}


# attaching autoscaling group of wordpress application to internal loadbalancer
resource "aws_autoscaling_attachment" "asg_attachment_wordpress" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-asg.id
  lb_target_group_arn    = var.wordpress_tg-arn //aws_lb_target_group.wordpress-tgt.arn
}


# launch template for tooling
resource "aws_launch_template" "tooling-launch-template" {
  image_id               = var.image["US_Office"]["Ubuntu_Server_22"]
  instance_type          = var.instance_type["small"]
  vpc_security_group_ids = [var.webserver_sg-id] //[aws_security_group.webserver-sg.id]

  /*   iam_instance_profile {
    name = aws_iam_instance_profile.ip.id
  } */

  key_name = var.keypair


  placement {
    availability_zone = "random_shuffle.az_list.result"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.tag_prefix}_tooling-launch-template"
      },
    )

  }

  # create a file called tooling.sh and copy the tooling userdata from project 15 into it
  user_data = filebase64("${path.module}/userdata/tooling.sh")
}



# ---- Autoscaling for tooling -----

resource "aws_autoscaling_group" "tooling-asg" {
  name                      = "tooling-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1

  vpc_zone_identifier = [

    var.private_subnets[0].id,
    var.private_subnets[1].id
  ]

  launch_template {
    id      = aws_launch_template.tooling-launch-template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tooling-launch-template"
    propagate_at_launch = true
  }
}

# attaching autoscaling group of  tooling application to internal loadbalancer
resource "aws_autoscaling_attachment" "asg_attachment_tooling" {
  autoscaling_group_name = aws_autoscaling_group.tooling-asg.id
  lb_target_group_arn    = var.tooling_tg-arn //aws_lb_target_group.tooling-tgt.arn
}
