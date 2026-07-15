# The VPC itself — an isolated virtual network in your AWS account
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# Internet Gateway — lets resources in public subnets reach the internet
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-igw"
  }
}

# =====================================================================
# 双 AZ:每个 AZ 各一个 public + private 子网,实现高可用
# =====================================================================

# Public subnets — one per AZ
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr_a
  availability_zone       = var.az_a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr_b
  availability_zone       = var.az_b
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-subnet-b"
  }
}

# Private subnets — one per AZ
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.az_a

  tags = {
    Name = "${var.name}-private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.az_b

  tags = {
    Name = "${var.name}-private-subnet-b"
  }
}

# Route table that sends internet-bound traffic to the IGW
# One public route table is enough — both public subnets share it.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-public-rt"
  }
}

# Attach the public route table to both public subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# =====================================================================
# NAT Gateway —— 让 private 子网"能出门上网,但外面进不来"
# ⚠️ 收费!(约 $0.059/小时 ≈ $43/月 + 流量费,建了就一直扣)
# 想用时去掉下面的注释,apply;测完记得 destroy。
# 注:双 AZ 若要真正高可用,NAT 也应每个 AZ 各建一个;这里先给单个示例。
# =====================================================================

# ① 弹性公网 IP —— NAT Gateway 要有一个固定公网 IP 才能对外通信
# resource "aws_eip" "nat" {
#   domain = "vpc"
#
#   tags = {
#     Name = "${var.name}-nat-eip"
#   }
# }

# ② NAT Gateway 本体 —— 必须放在【public 子网】里!
# 因为它自己得先能上网(靠 public 子网通往 IGW 的路由),才能帮别人转发。
# resource "aws_nat_gateway" "this" {
#   allocation_id = aws_eip.nat.id         # 绑上面那个弹性 IP
#   subnet_id     = aws_subnet.public_a.id # ← 注意是 public,不是 private
#
#   # 显式声明依赖:确保 IGW 先建好,NAT 才有意义
#   depends_on = [aws_internet_gateway.this]
#
#   tags = {
#     Name = "${var.name}-nat"
#   }
# }

# ③ private 子网专用路由表 —— 去任何地方(0.0.0.0/0)都走 NAT
# 对比 public 路由表走的是 IGW;private 走 NAT 才能"只出不进"。
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.this.id
#
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.this.id # ← 出口是 NAT,不是 gateway_id
#   }
#
#   tags = {
#     Name = "${var.name}-private-rt"
#   }
# }

# ④ 把上面这张路由表关联到 private 子网 —— 不关联的话前面都白写
# resource "aws_route_table_association" "private_a" {
#   subnet_id      = aws_subnet.private_a.id
#   route_table_id = aws_route_table.private.id
# }
# resource "aws_route_table_association" "private_b" {
#   subnet_id      = aws_subnet.private_b.id
#   route_table_id = aws_route_table.private.id
# }