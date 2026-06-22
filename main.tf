provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

module "myapp-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  env_prefix = var.env_prefix
  vpc_id = aws_vpc.myapp-vpc.id
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

resource "aws_default_security_group" "default-sg" {
#  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}

#data "aws_ami" "latest-amazon-linux-image" {
#  most_recent = true
#  owners = ["amazon"]
#  filter {
#    name = "name"
##    values = ["al2023-ami-*-kernel-*-x86_64"] // it returns a neuron image, so it needs more filtering
#    values = ["al2023-ami-2023*-kernel-*-x86_64"] // it returns the image we want
#  }
#  filter {
#    name = "virtualization-type"
#    values = ["hvm"]
#  }
#}

// use SSM parameter store to get the latest Amazon Linux 2023 image ID
data "aws_ssm_parameter" "latest-amazon-linux-image" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

// let EC2 instance know the public key to use for when user logs in via SSH using the private key
resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ssm_parameter.latest-amazon-linux-image.value
  instance_type = var.instance_type

  subnet_id = module.myapp-subnet.subnet.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh") // commented out to use provisioner instead

  user_data_replace_on_change = true

  tags = {
    Name = "${var.env_prefix}-server"
  }
}