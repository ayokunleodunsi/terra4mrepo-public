terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

provider "aws" {
  # Configuration options
   region = "us-east-1"
}

resource "aws_vpc" "prixit" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "trainingvpc"
  }
}

resource "aws_subnet" "dallas" {
  vpc_id     = aws_vpc.prixit.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "training_subnet"
  }
}

variable "sbnet1"{
  description = "Name of subnet"
  type        = string
  default     = "aws_subnet.dallas.id"
}

resource "aws_internet_gateway" "training_gw" {
  vpc_id = aws_vpc.prixit.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "dallas_rt" {
  vpc_id = aws_vpc.prixit.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.training_gw.id
  }

   tags = {
    Name = "txroute"
  }
}

resource "aws_route_table_association" "dallas_rta" {
  subnet_id      = aws_subnet.dallas.id
  route_table_id = aws_route_table.dallas_rt.id
}

resource "aws_security_group" "dallas_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prixit.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_key_pair" "mainkey" {
        key_name = "newkey_rsa"
        public_key = file("/home/ayoadmin/assignment/newkey.pub")
}

resource "aws_instance" "dallas_server1" {
  ami                         = "ami-026b57f3c383c2eec"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.mainkey.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.dallas_sg.id}"]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.dallas.id

  provisioner "file" {
  source      = "/home/ayoadmin/assignment/file.txt"
  destination = "/home/ec2-user/file_1.txt"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("/home/ayoadmin/assignment/newkey")
    host        = self.public_ip
    }

  tags = {
    Name = "webserver"
   }
}
