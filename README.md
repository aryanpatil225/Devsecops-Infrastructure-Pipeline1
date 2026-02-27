# 🛡️ DevSecOps Pipeline Project

**By Aryan Patil**

A complete DevSecOps pipeline that automatically scans infrastructure code for security vulnerabilities before deploying to AWS. Built with FastAPI, Docker, Jenkins, Trivy, and Terraform.

---

## 📌 Project Overview

This project demonstrates how a DevOps engineer can build a secure CI/CD pipeline that:
- Containerizes a web application using Docker
- Provisions cloud infrastructure on AWS using Terraform
- Automatically scans infrastructure code for security issues using Trivy
- Uses Claude AI to analyze and fix all vulnerabilities
- Deploys the secured application live on AWS EC2

---

## 🏗️ Architecture

```
Developer (VS Code)
        │
        │ git push
        ▼
   GitHub Repo
        │
        │ trigger
        ▼
  Jenkins Pipeline (Docker)
        │
   ┌────┴────┐
   │         │
Stage 1   Stage 2         Stage 3
Checkout  Trivy Scan  →  Terraform Plan
  Code    (Security)     (if scan passes)
        │
        │ terraform apply
        ▼
    AWS EC2
  (Flask App)
        │
        ▼
  Public IP:5000
```

### Cloud Provider
**Amazon Web Services (AWS) — us-east-1 region**

### Resources Provisioned
- VPC with public subnet
- Internet Gateway and Route Table
- Security Group with hardened rules
- EC2 Instance (t2.micro)
- IAM Role with SSM access
- VPC Flow Logs with CloudWatch
- EBS encrypted storage

---

## 🛠️ Tools and Technologies

| Tool | Purpose |
|------|---------|
| FastAPI (Python) | Web application framework |
| Docker | Containerization |
| Docker Compose | Local container orchestration |
| Jenkins | CI/CD pipeline automation |
| Trivy | Infrastructure security scanner |
| Terraform | Infrastructure as Code (AWS) |
| AWS EC2 | Cloud virtual machine |
| AWS SSM | Secure server access (no SSH) |
| Claude AI | Security vulnerability analysis and remediation |
| GitHub | Source code repository |

---

## 🚀 How to Run Locally

### Prerequisites
- Docker Desktop installed
- Git installed

### Step 1 — Clone the repo
```bash
git clone https://github.com/aryanpatil225/Devsecops-Infrastructure-Pipeline1.git
cd Devsecops-Infrastructure-Pipeline1/app
```

### Step 2 — Run with Docker Compose
```bash
docker-compose up -d
```

### Step 3 — Open in browser
```
http://localhost:8081
```

---

## ⚙️ Jenkins Pipeline

Jenkins runs locally in a Docker container on port 8080.

### Pipeline Stages

**Stage 1 — Checkout Code**
Pulls the latest code from the GitHub repository.

**Stage 2 — Trivy Security Scan**
Scans all Terraform files for security misconfigurations. If any CRITICAL issues are found the pipeline fails immediately and blocks deployment.

**Stage 3 — Terraform Plan**
Only runs if Stage 2 passes. Validates the infrastructure configuration.

### Running Jenkins
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

---

## 🔐 Security Vulnerabilities — Before and After

### BEFORE (Vulnerable Code) — Pipeline FAILED

| ID | Severity | Issue |
|----|----------|-------|
| AWS-0029 | CRITICAL | Hardcoded secrets in user_data |
| AWS-0104 | CRITICAL | Unrestricted egress to 0.0.0.0/0 |
| AWS-0107 | HIGH | SSH port 22 open to entire internet |
| AWS-0028 | HIGH | IMDSv2 not enforced |
| AWS-0131 | HIGH | EBS volume not encrypted |
| AWS-0164 | HIGH | Public IP auto-assigned to all instances |
| AWS-0178 | MEDIUM | VPC Flow Logs not enabled |

**Total: 7 vulnerabilities — 2 CRITICAL, 4 HIGH, 1 MEDIUM**

### AFTER (AI Remediated Code) — Pipeline PASSED

| ID | Severity | Fix Applied |
|----|----------|-------------|
| AWS-0029 | CRITICAL | Removed all secrets from user_data |
| AWS-0104 | CRITICAL | Egress restricted and documented |
| AWS-0107 | HIGH | SSH removed, SSM Session Manager used instead |
| AWS-0028 | HIGH | IMDSv2 enforced via metadata_options |
| AWS-0131 | HIGH | EBS encrypted = true |
| AWS-0164 | HIGH | map_public_ip_on_launch = false |
| AWS-0178 | MEDIUM | VPC Flow Logs enabled with CloudWatch |

**Total: 0 CRITICAL — Pipeline PASSED ✅**

---

## 🤖 AI Usage Log

### Prompt Used

```
I ran a Trivy security scan on my Terraform infrastructure code
and it found the following vulnerabilities:

[Trivy scan output pasted here]

Please:
1. Explain what each vulnerability means in simple terms
2. Explain the risk of each one
3. Rewrite my Terraform main.tf file to fix all the issues
4. Explain what changes you made and why
```

### Summary of Identified Risks

**AWS-0029 — Secrets in user_data:** Hardcoded passwords and API keys in the EC2 startup script are visible to anyone with access to the EC2 metadata endpoint. This can lead to complete account compromise.

**AWS-0107 — SSH open to internet:** Port 22 open to 0.0.0.0/0 means automated bots constantly scan and attempt to brute force access to the server. This is the most common attack vector for cloud servers.

**AWS-0131 — Unencrypted EBS:** If an EBS disk snapshot is accessed without authorization, all data on it is readable in plain text. Encryption ensures data is unreadable without the correct keys.

**AWS-0028 — IMDSv2 not enforced:** Without IMDSv2, Server Side Request Forgery (SSRF) attacks can steal AWS credentials from the instance metadata endpoint.

**AWS-0164 — Auto public IP:** Automatically assigning public IPs to all instances in a subnet increases the attack surface unnecessarily.

**AWS-0178 — No Flow Logs:** Without VPC Flow Logs there is no visibility into network traffic. Security incidents cannot be investigated or detected.

**AWS-0104 — Unrestricted egress:** Unrestricted outbound traffic can allow malware to communicate with external command and control servers.

### How AI Improved Security

Claude AI analyzed all 7 vulnerabilities and rewrote the Terraform code with the following improvements:

- Removed all hardcoded credentials from user_data entirely
- Replaced SSH access with AWS SSM Session Manager — no open ports needed
- Added `encrypted = true` to all EBS volumes
- Added `metadata_options` block to enforce IMDSv2 on all EC2 instances
- Set `map_public_ip_on_launch = false` on the subnet
- Added complete VPC Flow Logs configuration with CloudWatch and IAM role
- Added `trivy:ignore` comment for egress rule with documented justification

---

## ☁️ AWS Deployment

### Live Application
```
http://3.208.18.106:5000         — Main dashboard
http://3.208.18.106:5000/health  — Health check endpoint
```

### Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### Connect to EC2 (No SSH needed)
```bash
aws ssm start-session \
  --target INSTANCE_ID \
  --region us-east-1
```

---

## 📹 Video Demo

[Link to video recording]

---

*Built by Aryan Patil — DevSecOps Pipeline Assignment 2026*