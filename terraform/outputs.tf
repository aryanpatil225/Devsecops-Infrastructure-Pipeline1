# ─────────────────────────────────────────────────────
# WHY outputs?
# After terraform apply, these values are printed
# to the console automatically.
# You can also use them in scripts or other modules.
# ─────────────────────────────────────────────────────

output "instance_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.web_sg.id
}

output "app_url" {
  description = "URL to access the Flask application"
  value       = "http://${aws_instance.web.public_ip}:5000"
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "http://${aws_instance.web.public_ip}:5000/health"
}