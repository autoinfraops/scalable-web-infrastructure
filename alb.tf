
# Load balancer for our web app
resource "aws_lb" "load_balancer" {
  name               = "${var.app-name}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.app-subnets.*.id
  #   subnets            = data.aws_subnet_ids.default_subnet.ids
  security_groups = [aws_security_group.alb.id]

}

# set up load balancer for inboud traffic on port 80
resource "aws_lb_listener" "http" {
  # map the listener to the ALB
  load_balancer_arn = aws_lb.load_balancer.arn

  port = 80

  protocol = "HTTP"

  # By default, return a simple 404 page if URL is not recognized
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Time for coffee!"
      status_code  = 404
    }
  }
}

# This listener rule will forward requests to the target group
resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}


# The web apps are internally running on port 8080
# This target group will be used to route traffic
# to the web app instances
resource "aws_lb_target_group" "lb_target_group" {
  name     = "${aws_lb.load_balancer.name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.app-vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "lb_target_attachment" {
  count            = var.num-replicas
  target_group_arn = aws_lb_target_group.lb_target_group.arn
  target_id        = element(aws_instance.webapp_instances.*.id, count.index)
  port = 8080
}

# This SG is for the ALB
resource "aws_security_group" "alb" {
  name   = "alb-security-group"
  vpc_id = aws_vpc.app-vpc.id
}

# This rule allows inbound traffic to the ALB at port 80
resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

# This rule allows outbound traffic from the ALB
resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

}