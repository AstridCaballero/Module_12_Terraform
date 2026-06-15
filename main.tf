provider "aws" {
  region = "eu-west-2"
  access_key = "AKIA2JGYSYB2DWZEUS47"
  secret_key = "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"
}

#resource "aws_vpc" "development-vpc" {
#  cidr_block = "10.0.0.0/16"
#}
#
#resource "aws_subnet" "dev-subnet-1" {
#  vpc_id = aws_vpc.development-vpc.id
#  cidr_block = "10.0.10.0/24"
#  availability_zone = "eu-west-2a"
#}
#
#data "aws_vpc" "existing_vpc" {
#  default = true
#}
#
#resource "aws_subnet" "dev-subnet-2" {
#  vpc_id = data.aws_vpc.existing_vpc.id
#  cidr_block = "172.31.48.0/20"
#  availability_zone = "eu-west-2a"
#}