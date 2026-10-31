output "web_server_public_ip" {
  description = "Dia chi IP tinh cua Web Server"
  value       = aws_eip.web_eip.public_ip
}

output "web_server_url" {
  description = "Link truy cap truc tiep vao Website"
  value       = "http://${aws_eip.web_eip.public_ip}"
}
