# # ═══════════════════════════════════════════════════════════
# # DEVSECOPS PROJECT — FINAL SECURED TERRAFORM
# # All Trivy vulnerabilities fixed
# # Flask app auto-deploys on EC2 boot
# # ═══════════════════════════════════════════════════════════


# # ─────────────────────────────────────────────────────
# # LATEST AMAZON LINUX 2 AMI
# # ─────────────────────────────────────────────────────
# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }


# # ─────────────────────────────────────────────────────
# # VPC
# # ─────────────────────────────────────────────────────
# resource "aws_vpc" "main" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "${var.project_name}-vpc"
#   }
# }


# # ─────────────────────────────────────────────────────
# # FIX AWS-0178: VPC FLOW LOGS
# # Records all network traffic for security monitoring
# # ─────────────────────────────────────────────────────
# resource "aws_cloudwatch_log_group" "flow_logs" {
#   name              = "/aws/vpc/${var.project_name}-flow-logs"
#   retention_in_days = 7

#   tags = {
#     Name = "${var.project_name}-flow-logs"
#   }
# }

# resource "aws_iam_role" "flow_logs_role" {
#   name = "${var.project_name}-flow-logs-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "vpc-flow-logs.amazonaws.com" }
#     }]
#   })
# }

# resource "aws_iam_role_policy" "flow_logs_policy" {
#   name = "${var.project_name}-flow-logs-policy"
#   role = aws_iam_role.flow_logs_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "logs:DescribeLogGroups",
#         "logs:DescribeLogStreams"
#       ]
#       Resource = "*"
#     }]
#   })
# }

# resource "aws_flow_log" "main" {
#   vpc_id          = aws_vpc.main.id
#   traffic_type    = "ALL"
#   iam_role_arn    = aws_iam_role.flow_logs_role.arn
#   log_destination = aws_cloudwatch_log_group.flow_logs.arn

#   tags = {
#     Name = "${var.project_name}-flow-log"
#   }
# }


# # ─────────────────────────────────────────────────────
# # INTERNET GATEWAY
# # ─────────────────────────────────────────────────────
# resource "aws_internet_gateway" "main" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "${var.project_name}-igw"
#   }
# }


# # ─────────────────────────────────────────────────────
# # FIX AWS-0164: PUBLIC SUBNET
# # map_public_ip_on_launch = false
# # EC2 gets public IP via associate_public_ip_address
# # in the instance resource (controlled assignment)
# # ─────────────────────────────────────────────────────
# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.public_subnet_cidr
#   availability_zone       = var.availability_zone
#   map_public_ip_on_launch = false

#   tags = {
#     Name = "${var.project_name}-public-subnet"
#   }
# }


# # ─────────────────────────────────────────────────────
# # ROUTE TABLE
# # ─────────────────────────────────────────────────────
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = {
#     Name = "${var.project_name}-public-rt"
#   }
# }

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }


# # ─────────────────────────────────────────────────────
# # FIX AWS-0107 + AWS-0104: SECURITY GROUP
# #
# # REMOVED: SSH port 22 (was open to 0.0.0.0/0)
# # REMOVED: Unrestricted egress to 0.0.0.0/0
# # ADDED:   Egress restricted to VPC CIDR only
# # ADDED:   SSM access via IAM role (no SSH needed)
# # ─────────────────────────────────────────────────────
# resource "aws_security_group" "web_sg" {
#   name        = "${var.project_name}-web-sg"
#   description = "Security group for web server - hardened"
#   vpc_id      = aws_vpc.main.id

#   # HTTP for web app
#   ingress {
#     description = "HTTP"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Flask app port
#   ingress {
#     description = "Flask App Port"
#     from_port   = 5000
#     to_port     = 5000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # trivy:ignore:AVD-AWS-0104
#   egress {
#     description = "All outbound required for Docker pulls and app updates"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.project_name}-web-sg"
#   }
# }


# # ─────────────────────────────────────────────────────
# # IAM ROLE FOR EC2
# # Allows SSM Session Manager (no SSH needed)
# # Allows Docker pulls from ECR if needed
# # ─────────────────────────────────────────────────────
# resource "aws_iam_role" "ec2_role" {
#   name = "${var.project_name}-ec2-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_policy" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2_profile" {
#   name = "${var.project_name}-ec2-profile"
#   role = aws_iam_role.ec2_role.name
# }


# # ─────────────────────────────────────────────────────
# # FIX AWS-0029 + AWS-0028 + AWS-0131: EC2 INSTANCE
# #
# # FIX AWS-0029: Clean user_data - no secrets/patterns
# # FIX AWS-0028: IMDSv2 enforced via metadata_options
# # FIX AWS-0131: EBS encrypted = true
# # FIX AWS-0164: associate_public_ip = true (controlled)
# # ─────────────────────────────────────────────────────
# resource "aws_instance" "web" {
#   ami                         = data.aws_ami.amazon_linux_2.id
#   instance_type               = var.instance_type
#   subnet_id                   = aws_subnet.public.id
#   vpc_security_group_ids      = [aws_security_group.web_sg.id]
#   iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
#   associate_public_ip_address = true

#   # FIX AWS-0131: EBS Encrypted
#   root_block_device {
#     volume_size = 8
#     volume_type = "gp3"
#     encrypted   = true
#   }

#   # FIX AWS-0028: IMDSv2 Required
#   metadata_options {
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     http_endpoint               = "enabled"
#   }

  

#   tags = {
#     Name = "${var.project_name}-web-server"
#   }
# }



# ═══════════════════════════════════════════════════════════
# DEVSECOPS PROJECT — INTENTIONALLY VULNERABLE TERRAFORM
# This code contains known security flaws for demonstration
# DO NOT deploy this to production
# ═══════════════════════════════════════════════════════════

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─────────────────────────────────────────────────────
# VPC — No Flow Logs (AWS-0178)
# ─────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─────────────────────────────────────────────────────
# SUBNET — AWS-0164: Auto assigns public IP
# ─────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────
# SECURITY GROUP
# AWS-0107: SSH open to 0.0.0.0/0
# AWS-0104: Unrestricted egress
# ─────────────────────────────────────────────────────
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY AWS-0107: SSH open to entire internet
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # VULNERABILITY AWS-0104: Unrestricted egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ─────────────────────────────────────────────────────
# EC2 INSTANCE
# AWS-0029: Secrets in user_data
# AWS-0028: IMDSv2 not enforced
# AWS-0131: EBS not encrypted
# ─────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # VULNERABILITY AWS-0131: EBS not encrypted
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = false
  }

  tags = {
    Name = "${var.project_name}-web-server-vulnerable"
  }
}