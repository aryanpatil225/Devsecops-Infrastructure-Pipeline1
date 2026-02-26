# ═══════════════════════════════════════════════════
# DEVSECOPS PROJECT — TERRAFORM MAIN CONFIGURATION
# ⚠️  VERSION 1: INTENTIONALLY VULNERABLE
# Vulnerabilities will be fixed in Part 4 (AI Remediation)
# ═══════════════════════════════════════════════════


# ─────────────────────────────────────────────────────
# DATA SOURCE: Latest Amazon Linux 2 AMI
#
# WHY data source instead of hardcoded AMI ID?
# AMI IDs are DIFFERENT per region and get UPDATED
# with security patches regularly.
# Using data source = always get latest patched image.
# Hardcoding = stuck on old, possibly vulnerable AMI.
# ─────────────────────────────────────────────────────
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
# VPC — Virtual Private Cloud
#
# WHY VPC?
# Isolates your infrastructure in its own private network.
# Nothing can reach your resources unless
# you explicitly allow it via security rules.
# Think of it as your private data center in AWS.
# ─────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# ─────────────────────────────────────────────────────
# INTERNET GATEWAY
#
# WHY Internet Gateway?
# Without this, your VPC is completely isolated.
# IGW allows resources in public subnet to:
# - Receive traffic FROM internet (inbound)
# - Send traffic TO internet (outbound)
# ─────────────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# ─────────────────────────────────────────────────────
# PUBLIC SUBNET
#
# WHY public subnet?
# Web servers need to be reachable from internet.
# Public subnet = has route to Internet Gateway.
#
# In production architecture:
# Public subnet  = Load Balancers, Bastion Hosts
# Private subnet = App servers, Databases (no internet)
# We use public for simplicity in this demo.
# ─────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone

  # ⚠️ VULNERABILITY 1: map_public_ip_on_launch = true
  # WHY THIS IS RISKY:
  # Every EC2 in this subnet gets a public IP automatically.
  # Direct exposure to internet without load balancer.
  # Best practice: use private subnet + ALB instead.
  # We keep this for demo so we can access app via public IP.
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}


# ─────────────────────────────────────────────────────
# ROUTE TABLE
#
# WHY route table?
# Tells AWS where to send network traffic.
# 0.0.0.0/0 → IGW means:
# "Send ALL internet-bound traffic through IGW"
# Without this, even with IGW, traffic won't flow.
# ─────────────────────────────────────────────────────
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


# ─────────────────────────────────────────────────────
# ROUTE TABLE ASSOCIATION
#
# WHY associate route table to subnet?
# A route table alone does nothing.
# Must be LINKED to a subnet to take effect.
# ─────────────────────────────────────────────────────
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# ─────────────────────────────────────────────────────
# SECURITY GROUP — ⚠️ INTENTIONALLY VULNERABLE
#
# VULNERABILITY 2: SSH open to 0.0.0.0/0
# ════════════════════════════════════════
# WHY THIS IS CRITICAL RISK:
#
# 0.0.0.0/0 = ENTIRE INTERNET can attempt SSH
#
# Real world impact:
# • Automated bots scan ALL public IPs for port 22
# • Brute force attacks run 24/7 against open SSH
# • If key is leaked/weak = full server compromise
# • This is the #1 cause of EC2 breaches on AWS
# • AWS itself warns against this in Security Hub
#
# Trivy will flag this as CRITICAL
# Jenkins pipeline will FAIL because of this
# We fix it in Part 4 with AI remediation
# ─────────────────────────────────────────────────────
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # ⚠️ CRITICAL VULNERABILITY — SSH open to world
  ingress {
    description = "SSH - INTENTIONALLY VULNERABLE"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # ← THIS IS THE VULNERABILITY
  }

  # HTTP access for web app
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask app port
  ingress {
    description = "Flask Application Port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound — all traffic allowed
  egress {
    description = "Allow all outbound"
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
#
# WHY t2.micro?
# Free tier = 750 hours/month = $0 for demo
#
# WHY user_data?
# Bootstrap script runs automatically on first boot.
# Installs Docker so Flask app container can run.
# This means app is running when Terraform finishes.
# ─────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # ⚠️ VULNERABILITY 3: Unencrypted EBS volume
  # WHY THIS IS RISKY:
  # If EBS snapshot is accidentally made public
  # or shared, data is readable by anyone.
  # AWS encrypts for FREE — no excuse not to use it.
  # Compliance frameworks (PCI-DSS, HIPAA) REQUIRE it.
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = false   # ← INTENTIONALLY INSECURE
  }

  # Bootstrap script: installs Docker on EC2
  user_data = <<-EOF
    #!/bin/bash
    # Update system packages
    yum update -y

    # Install Docker
    yum install -y docker

    # Start Docker service
    systemctl start docker
    systemctl enable docker

    # Add ec2-user to docker group
    usermod -aG docker ec2-user

    # Pull and run Flask app
    docker run -d \
      -p 5000:5000 \
      -e APP_ENV=production \
      -e APP_VERSION=1.0.0 \
      --name flask-app \
      --restart unless-stopped \
      python:3.12-slim \
      sh -c "pip install flask gunicorn && \
             echo 'from flask import Flask,jsonify
import os
app=Flask(__name__)
@app.route(\"/\")
def home(): return jsonify({\"message\":\"DevSecOps App Running on AWS\",\"status\":\"running\"})
@app.route(\"/health\")
def health(): return jsonify({\"status\":\"healthy\"}),200
' > app.py && gunicorn --bind 0.0.0.0:5000 app:app"
  EOF

  tags = {
    Name = "${var.project_name}-web-server"
  }
}