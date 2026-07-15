output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the EC2 (no public IP — it lives in a private subnet)"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID attached to the EC2"
  value       = aws_security_group.ec2.id
}
