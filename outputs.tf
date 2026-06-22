output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

#output "latest-amazon-linux-image-id" {
#  value = data.aws_ami.latest-amazon-linux-image.id
#}