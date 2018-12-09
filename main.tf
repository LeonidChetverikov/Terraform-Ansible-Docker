provider "aws" {
  region = "us-east-1"
}

variable azs_var {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable subnet_id_var {
  type    = "list"
  default = ["subnet-123", "subnet-456", "subnet-789"]
}

variable dns_name_var {
  type    = "list"
  default = ["name1", "name2", "name3"]
}

resource "aws_security_group" "nat" {
    name = "vpc_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "TemplateNat"
    }
}
resource "aws_instance" "DR_ec2" {
  count = "${length(var.azs_var)}"
  ami = "ami-0057d8e6fb0692b80"
  key_name = "keys"
  instance_type = "t2.nano"
  availability_zone = "${element(var.azs_var,count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat.id}"]
  subnet_id = "${element(aws_subnet.outsubnet.*.id,count.index)}"
  associate_public_ip_address = true
  source_dest_check = false
}

resource "aws_route53_zone" "primary" {
  name = "datarobotexample.com"
}

resource "aws_route53_record" "www" {
  count = "${length(var.dns_name_var)}"
  zone_id = "${aws_route53_zone.primary.zone_id}"

  name    = "${element(var.dns_name_var,count.index)}.datarobotexample.com"
  type    = "A"
  ttl     = "300"
  records = ["${element(aws_instance.DR_ec2.*.public_ip,count.index)}"]
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags {
    Name = "vpc-123456789"
  }
}

resource "aws_subnet" "outsubnet" {
  count = "${length(var.azs_var)}"
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "${element(var.azs_var,count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${element(var.subnet_id_var,count.index)}"
  }
}

resource "aws_internet_gateway" "gw" {
  count = 3
  vpc_id = "${element(aws_subnet.outsubnet.*.id,count.index)}"
}
resource "aws_volume_attachment" "this_ec2" {
  count = "${length(var.azs_var)}"
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.my-test-ebs.*.id[count.index]}"
  instance_id = "${aws_instance.DR_ec2.*.id[count.index]}"
}

resource "aws_ebs_volume" "my-test-ebs" {
  count = "${length(var.azs_var)}"
  availability_zone = "${element(var.azs_var,count.index)}"
  size              = 1024

  tags {
    Name = "DataRobot"
  }
}
