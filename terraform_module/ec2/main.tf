# =====================================================================
# EC2 模块 —— 放在 private 子网里的后端服务器
# 结构:找 AMI → 安全组 → EC2 实例(自带小 web 服务) → 挂进 Target Group
# 免费:用 t2.micro(免费套餐) + 系统自带 python3 起 web,不需要 NAT 上网
# =====================================================================

# ① 找一个最新的 Amazon Linux 2023 AMI —— 自带 python3,不用联网装东西
# 用 data 而不是写死 AMI ID,因为 AMI ID 每个 region 都不一样、还会更新
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"] # 官方镜像

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ② 安全组 —— 只允许 ALB 访问 EC2 的 80 端口(别人进不来)
resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Allow HTTP from the ALB only"
  vpc_id      = var.vpc_id

  # 入站:只放行来自 ALB 安全组的 80 端口(比开 0.0.0.0/0 安全得多)
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id] # ← 只认 ALB 这个来源
  }

  # 出站:全放行(private 子网没 NAT 时其实也出不去,但留着无害)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ec2-sg"
  }
}

# ③ EC2 实例本体 —— 放进 private 子网
resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type # 默认 t2.micro(免费套餐)
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # 开机自动跑的脚本:用系统自带 python3 起一个最简单的网页服务
  # 不需要联网、不需要 NAT,健康检查访问 "/" 就能拿到 200
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /srv/web
    echo "<h1>Hello from private EC2: $(hostname)</h1>" > /srv/web/index.html

    # 写成 systemd 服务,重启也能自动拉起
    cat > /etc/systemd/system/webapp.service <<'UNIT'
    [Unit]
    Description=Tiny Python web server
    After=network.target

    [Service]
    WorkingDirectory=/srv/web
    ExecStart=/usr/bin/python3 -m http.server 80
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now webapp.service
  EOF

  tags = {
    Name = "${var.name}-ec2"
  }
}

# ④ 把 EC2 挂进 Target Group —— 这一步之后 ALB 才真的会往这台机器转流量
resource "aws_lb_target_group_attachment" "this" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.this.id
  port             = 80
}
