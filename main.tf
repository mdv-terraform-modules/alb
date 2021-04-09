#======================== Application Load Balancer ============================

resource "aws_lb" "lb" {
  name               = "${var.environment}-LoadBalancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets_ids
  security_groups    = [aws_security_group.alb_sg.id]
  tags               = merge(var.tags, { Name = "${var.environment}-LoadBalancer" })
}

#-------------------- Listeners for load balancer -----------------------

resource "aws_lb_listener" "ssl_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ports.ssl_port
  protocol          = var.protocol.https
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = lookup(var.target_groups_details, "${var.environment}-default")
  }
}

resource "aws_lb_listener_certificate" "main" {
  listener_arn    = aws_lb_listener.ssl_listener.arn
  certificate_arn = data.aws_acm_certificate.cert_main.arn
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ports.http_port
  protocol          = var.protocol.http

  default_action {
    type = "redirect"

    redirect {
      port        = var.ports.ssl_port
      protocol    = var.protocol.https
      status_code = "HTTP_301"
    }
  }
}

#-------------------- Secret listener for load balancer -----------------------

resource "aws_lb_listener" "secret_ssl_port" {
  load_balancer_arn = aws_lb.lb.arn
  port              = var.ports.secret_ssl_port
  protocol          = var.protocol.https
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert.arn


  default_action {
    type             = "forward"
    target_group_arn = lookup(var.target_groups_details, "${var.environment}-secret")
  }
}

resource "aws_lb_listener_certificate" "secret" {
  listener_arn    = aws_lb_listener.secret_ssl_port.arn
  certificate_arn = data.aws_acm_certificate.cert_main.arn
}

#-------------------- listeners rules for load balancer -----------------------

resource "aws_lb_listener_rule" "ssl_rules" {
  count        = length(var.ports)
  listener_arn = aws_lb_listener.ssl_listener.arn
  priority     = 100 - count.index + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tgs[count.index].arn
  }

  condition {
    host_header {
      values = ["${var.host_headers[count.index]}${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "forum_ssl_rule" {
  listener_arn = aws_lb_listener.ssl_listener.arn
  priority     = 96

  action {
    type             = "forward"
    target_group_arn = lookup(var.target_groups_details, "${var.environment}-forum")
  }

  condition {
    path_pattern {
      values = ["/forum/*"]
    }
  }
}

resource "aws_lb_listener_rule" "secret_ssl_rule" {
  listener_arn = aws_lb_listener.secret_ssl_port.arn
  priority     = 95

  action {
    type             = "forward"
    target_group_arn = lookup(var.target_groups_details, "${var.environment}-secret")
  }

  condition {
    host_header {
      values = ["www.${var.domain_name}"]
    }
  }
}

#------------------- Target groups for load balancer ---------------------

resource "aws_lb_target_group" "tgs" {
  count    = length(var.user_data)
  name     = "${var.environment}-${var.user_data[count.index]}"
  port     = var.ports.http_port
  protocol = var.protocol.http
  vpc_id   = var.vpc_id

  health_check {
    path                = "/index.html"
    protocol            = var.protocol.http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }

  tags = merge(var.tags, { Name = "${var.user_data[count.index]} ${var.environment} Target Group" })
}

#============================= Security Group ==================================

resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = local.http_protocol
      cidr_blocks = local.any_cidr_block
    }
  }
  egress {
    from_port   = local.any_port
    to_port     = local.any_port
    protocol    = local.any_protocol
    cidr_blocks = local.any_cidr_block
  }

  tags = merge(var.tags, { Name = "${var.environment} Security Group" })
}
