
#EC2 Imstamce 1
#Build VPC
resource "aws_vpc" "goofdemovpc" {
  cidr_block = var.aws_vpc_cidr

}

# Build Internet Gateway
resource "aws_internet_gateway" "goof_demo_gateway" {
  vpc_id = aws_vpc.goofdemovpc.id
}


# Create a subnet
resource "aws_subnet" "external" {
  vpc_id                  = aws_vpc.goofdemovpc.id
  cidr_block              = var.aws_subnet_cidr
  availability_zone       = var.primary_az
 
}

#Create a Route Table
resource "aws_route_table" "goof_route_table" {
  vpc_id = aws_vpc.goofdemovpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.goof_demo_gateway.id
  }
  
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.goof_demo_gateway.id
  }
  
  }

#Associate Route Table to Subnet
resource "aws_route_table_association" "goof_route_association" {
    subnet_id = aws_subnet.external.id
    route_table_id = aws_route_table.goof_route_table.id
}


#Create security groups 

resource "aws_security_group" "goof_sg" {
  name = "${var.victim_company}-ssh-sg"
  vpc_id = aws_vpc.goofdemovpc.id
ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.source_ip]
  }
ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [var.source_ip]
  }
ingress {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = [var.source_ip]
  }
 ingress {
      from_port   = 1337
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = [var.source_ip]
  }   
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.source_ip]
  }

}


#Create Network Interface
resource "aws_network_interface" "goof-nic" {
    subnet_id = aws_subnet.external.id
    private_ips = [var.goof_private]
    security_groups = [aws_security_group.goof_sg.id]
}


#Create Elastic IP
resource "aws_eip" "goof_eip" {
  vpc                       = true
  network_interface         = aws_network_interface.goof-nic.id
  associate_with_private_ip = var.goof_private
  depends_on = [aws_internet_gateway.goof_demo_gateway]
}