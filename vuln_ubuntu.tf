# Vulnerable VM


resource "aws_instance" "vuln_vm" {
  availability_zone = var.primary_az
  ami           = var.ubuntu_ami
  instance_type = "t2.micro"
  key_name = var.key_name
 
  network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.tfgoof-nic.id
  }
  
  user_data =  "${file("vuln_bootstrap.sh")}"
  tags = {
   Environment = "DEV"
   Owner = var.owner

  }
}

# Unecrypted EBS
resource "aws_ebs_volume" "volume1" {
    availability_zone = var.primary_az
    size              = 40
    encrypted         = false
    tags = {
        Name = "${var.owner}-volume1"
        Owner = var.owner
    }
}

resource "aws_ebs_snapshot" "snapshot1" {
    volume_id = "${aws_ebs_volume.volume1.id}"
  
    tags = {
        Name = "${var.owner}-snapshot"
        Owner = var.owner
    }
}


output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value       = aws_instance.vuln_vm.public_ip
}