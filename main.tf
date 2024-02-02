data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

## -------------
## Add Elastic IP
## -------------
resource "aws_eip" "default" {
  instance = "${aws_instance.aws_instance.id}"
  vpc      = true
}

resource "aws_instance" "aws_instance" {
  ami             = "${data.aws_ami.operating_system.id}"
  instance_type   = "t2.medium"
  key_name        = "promet-ohio-terraform"

  tags = {
    Name = "aws-instance"
  }

  ## Add here the security groups needed
  ##
  vpc_security_group_ids = [
    "${aws_security_group.security-group.id}",
  ]
}

## -----------------------------
## Provision with users
## -----------------------------
resource null_resource "ansible_web" {
  depends_on = [
    "aws_instance.aws_instance"
  ]

  ## NOTE: 'sleep 6m' is an arbitrary delay added to wait until
  ##       the ec2 instance is ready to accept ssh connection
  ##
 provisioner "local-exec" {
    command = "sleep 6m && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u centos --private-key '${var.aws_pem_location}' -i '${aws_eip.default.public_ip},' ansible/web-apache-centos.yml"
  }
}

## ===========================================
## security groups declarations
## ===========================================
resource "aws_security_group" "security-group" {
  name = "security-group"
  description = "Inbound only SSH, Outbound HTTP, HTTPS"

  tags = {
    Name = "Access Security Group"
  }

  ## inbound ssh
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ## inbound http
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ## outbund http
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ## inbound https
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ## outbound https
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ## inbound icmp echo
  #ingress {
  #  from_port = 8
  #  to_port = 0
  #  protocol = "icmp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}
}
