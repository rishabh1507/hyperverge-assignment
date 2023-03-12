# provider 
provider "aws" {
    region = "ap-northeast-1"
}

# resource
# security group for allowing traffic on port 80, 22
resource "aws_security_group" "allow_traffic" {
    name         = "allow_traffic"
    description  = "Allow inbound traffic"

    ingress {
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "sg_hyperverge2"
    }
}

# keypair for aws instance
resource "aws_key_pair" "hyperverge2_key" {
    key_name = "hyperverge2_key"
    public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "hyperverge2_key" {
    content = tls_private_key.rsa.private_key_pem
    filename = "hyperverge2_key"
  
}

# aws instance for static website
resource "aws_instance" "hyperverge2" {
       ami = "ami-06ee4e2261a4dc5c3"
       instance_type = "t2.micro"
       subnet_id = "subnet-03672a1ea9a5ed54e"
       vpc_security_group_ids = [aws_security_group.allow_traffic.id]
       key_name = "hyperverge2_key"
       user_data = file("script.sh")
        tags = {
            Name = "hyperverge2"
        }
}

# 2nd aws instance for static website
resource "aws_instance" "hyperverge3" {
    ami = "ami-06ee4e2261a4dc5c3"
    instance_type = "t2.micro"
    subnet_id = "subnet-01e70617085f85ec4"
    vpc_security_group_ids = [aws_security_group.allow_traffic.id]
    key_name = "hyperverge2_key"
    user_data = file("script.sh")
        tags = {
            Name = "hyperverge3"
        }
}

#create security group for ALB
resource "aws_security_group" "sg_application_lb" {
  name   = "sg_application_lb"
  vpc_id = "vpc-07e40feb9ed4c4919"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "sg_application_lb"
  }
}

#create ALB
resource "aws_lb" "lb_hyperverge" {
  name               = "hyperverge-elb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-03672a1ea9a5ed54e", "subnet-01e70617085f85ec4"]
  security_groups    = [aws_security_group.sg_application_lb.id]
  enable_deletion_protection = false
  tags = {
    Name = "hyperverge-elb"
  }
}

#create target group
resource "aws_lb_target_group" "hyperverge_vms" {
  name     = "tf-hyperverge-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id = "vpc-07e40feb9ed4c4919"
}

#create listner for ALB
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb_hyperverge.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hyperverge_vms.arn
  }
}
#add host to target group
resource "aws_lb_target_group_attachment" "hyperverge2_tg_attachment" {
  target_group_arn =  aws_lb_target_group.hyperverge_vms.arn
  target_id        =  aws_instance.hyperverge2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "hyperverge3_tg_attachment" {
  target_group_arn =  aws_lb_target_group.hyperverge_vms.arn
  target_id        =  aws_instance.hyperverge3.id
  port             = 80
}
