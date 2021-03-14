resource "aws_vpc" "default" {
  count = var.vpc_id == "" ? 1 : 0

  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    { Name = "DistCalc" }
  )
}
data "aws_vpc" "default" { id = var.vpc_id == "" ? aws_vpc.default[0].id : var.vpc_id }
output "vpc" { value = data.aws_vpc.default }

resource "aws_internet_gateway" "default" {
  count = var.vpc_id == "" ? 1 : 0

  vpc_id = data.aws_vpc.default.id

  tags = merge(
    local.tags,
    { Name = "DistCalc" }
  )
}

data "aws_availability_zones" "available" { state = "available" }
resource "aws_subnet" "lb" {
  count = var.lb_subnet_ids == [] ? length(data.aws_availability_zones.available.names) : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index)
  vpc_id            = data.aws_vpc.default.id

  tags = merge(
    local.tags,
    { Name = join(" ", ["DistCalc", "LB", upper(substr(data.aws_availability_zones.available.names[count.index], length(data.aws_availability_zones.available.names[count.index]) - 1, length(data.aws_availability_zones.available.names[count.index])))]) }
  )
}
data "aws_subnet" "lb" {
  count = var.lb_subnet_ids == [] ? length(aws_subnet.lb) : length(var.lb_subnet_ids)

  id = var.lb_subnet_ids == [] ? aws_subnet.lb[count.index].id : var.lb_subnet_ids[count.index]
}
output "lb_subnets" { value = data.aws_subnet.lb }

data "aws_internet_gateway" "default" {
  depends_on = [data.aws_subnet.lb]

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
resource "aws_route_table" "lb" {
  count = aws_subnet.lb == [] ? 0 : 1

  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  tags = merge(
    local.tags,
    { Name = "DistCalc LB" }
  )
}
resource "aws_route_table_association" "lb" {
  count = length(aws_subnet.lb)

  subnet_id      = aws_subnet.lb[count.index].id
  route_table_id = aws_route_table.lb[0].id
}

resource "aws_security_group" "lb" {
  count = var.lb_security_groups == [] ? 1 : 0

  vpc_id = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "DistCalc LB" }
  )
}
data "aws_security_group" "lb" {
  count = var.lb_security_groups == [] ? length(aws_security_group.lb) : length(var.lb_security_groups)

  id = var.lb_security_groups == [] ? aws_security_group.lb[count.index].id : var.lb_security_groups[count.index]
}
output "lb_security_groups" { value = data.aws_security_group.lb }

resource "aws_lb" "frontend" {
  security_groups = data.aws_security_group.lb[*].id
  subnets         = var.lb_subnet_ids == [] ? aws_subnet.lb[*].id : var.lb_subnet_ids

  tags = merge(
    local.tags,
    { Name = coalesce(var.lb_name, "DistCalc app") },
    var.lb_tags
  )
}

resource "aws_lb_target_group" "frontend" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  tags = merge(
    local.tags,
    { Name = "DistCalc app" }
  )
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_subnet" "ec2" {
  count = var.ec2_subnet_id == "" ? 1 : 0

  vpc_id     = data.aws_vpc.default.id
  cidr_block = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index + 10)

  tags = merge(
    local.tags,
    { Name = "DistCalc app" }
  )
}
data "aws_subnet" "ec2" {
  id = var.ec2_subnet_id == "" ? aws_subnet.ec2[0].id : var.ec2_subnet_id
}
output "ec2_subnet" { value = data.aws_subnet.ec2 }

resource "aws_eip" "nat" {
  count = length(aws_subnet.ec2)

  vpc = true

  tags = merge(
    local.tags,
    { Name = "DistCalc EIP" }
  )
}

resource "aws_nat_gateway" "ec2" {
  count = length(aws_eip.nat)

  allocation_id = aws_eip.nat[0].id
  subnet_id     = data.aws_subnet.ec2.id

  tags = merge(
    local.tags,
    { Name = "DistCalc NAT" }
  )
}
data "aws_nat_gateway" "default" {
  depends_on = [aws_nat_gateway.ec2]

  subnet_id = data.aws_subnet.ec2.id
}

resource "aws_route_table" "ec2" {
  count = aws_subnet.ec2 == [] ? 0 : 1

  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.default.id
  }

  tags = merge(
    local.tags,
    { Name = "DistCalc EC2" }
  )
}

resource "aws_route_table_association" "ec2" {
  count = length(aws_subnet.ec2)

  subnet_id      = aws_subnet.ec2[count.index].id
  route_table_id = aws_route_table.ec2[0].id
}

resource "aws_security_group" "ec2" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    description     = "Traffic from LB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = data.aws_security_group.lb[*].id
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = coalesce(var.ec2_sg_name, "DistCalc EC2") },
    var.ec2_sg_tags
  )
}

resource "aws_iam_role" "role" {
  count = var.ec2_instance_profile == "" ? 1 : 0

  name = "EC2ReadOnly"
  path = "/"

  assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                   "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            },
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                   "Service": "ssm.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
  EOF
}
resource "aws_iam_role_policy_attachment" "ro" {
  count = length(aws_iam_role.role)

  role       = aws_iam_role.role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "ssm" {
  count = length(aws_iam_role.role)

  role       = aws_iam_role.role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ec2ro" {
  count = length(aws_iam_role.role)

  name = "EC2ReadOnlyProfile"
  role = aws_iam_role.role[0].name
}
data "aws_iam_instance_profile" "ec2ro" {
  name = var.ec2_instance_profile == "" ? aws_iam_instance_profile.ec2ro[0].name : var.ec2_instance_profile
}
output "iam_instance_profile" { value = data.aws_iam_instance_profile.ec2ro }

data "aws_ami" "image" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}
resource "aws_instance" "app" {
  ami                    = data.aws_ami.image.id
  iam_instance_profile   = data.aws_iam_instance_profile.ec2ro.name
  instance_type          = var.ec2_instance_type
  subnet_id              = data.aws_subnet.ec2.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = <<-EOF
    #cloud-config

    packages:
    - docker

    write_files:
    - path: /etc/systemd/system/app.service
      permissions: 0755
      owner: root
      content: |
        [Unit]
        Description=distcalc app
        Requires=docker.service
        After=docker.service

        [Service]
        Restart=always
        ExecStart=/usr/bin/docker run --name app --publish 8080:8080 --restart always michelecereda/distcalc
        ExecStop=/usr/bin/docker stop app

        [Install]
        WantedBy=multi-user.target

    runcmd:
    - sudo systemctl enable --now app.service
  EOF

  tags = merge(
    local.tags,
    { Name = coalesce(var.ec2_name, "DistCalc app") },
    var.ec2_tags
  )
}
resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = aws_instance.app.id
  port             = 8080
}
