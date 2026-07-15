# =====================================================================
# ALB 模块 —— 应用负载均衡器
# 结构:安全组 → ALB → Target Group → Listener
# 放在 public 子网,把流量转发给 private 子网里的服务器
# =====================================================================

# ① 安全组 —— ALB 的"防火墙",允许外部 HTTP(80) 进来
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP inbound to the ALB"
  vpc_id      = var.vpc_id

  # 入站:允许任何人访问 80 端口(网站)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 出站:允许 ALB 把流量转发给后端(全放行)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 = 所有协议
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# ② ALB 本体 —— 必须跨【至少 2 个 AZ 的子网】,所以 subnets 是个列表
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application" # application = ALB(第7层)
  internal           = false         # false = 面向公网;true = 仅内部
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids # ← 至少两个不同 AZ 的 public 子网

  tags = {
    Name = "${var.name}-alb"
  }
}

# ③ Target Group —— 一组后端服务器的集合,ALB 往这里转发
resource "aws_lb_target_group" "this" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # 健康检查:ALB 定期访问这个路径,不健康的后端就不再发流量
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200" # 返回 HTTP 200 才算健康
  }

  tags = {
    Name = "${var.name}-tg"
  }
}

# ④ Listener —— 监听 80 端口,收到请求就转给上面的 Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}