output "region" {
  description = "value"
  value       = var.default_region
}

output "instance_type" {
  description = "Instance type that was deployed"
  value       = aws_instance.app_server.instance_type
}

output "instance_public_ip" {
  description = "Dit is het publieke ip address van de ec2 instance."
  value       = aws_instance.app_server.public_ip
}

output "instance_ssh_user" {
  description = "Default SSH user"
  value       = var.default_ssh_user
}

output "z_easy_connect" {
  description = "OUtput that provides the full command to connect to the ec2 instance"
  value = "ssh -i ${local_sensitive_file.private_sshkey.filename} ${var.default_ssh_user}@${aws_instance.app_server.public_ip}"
}
