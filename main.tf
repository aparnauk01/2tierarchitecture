
resource "aws_vpc" "twotier" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "2tier"
  }
}

resource "aws_subnet" "twotierpublic" {
  vpc_id     = aws_vpc.twotier.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "2tierpublic"
  }
}

resource "aws_subnet" "twotierprivate" {
  vpc_id     = aws_vpc.twotier.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "2tierprivate"
  }
}


resource "aws_subnet" "twotierprivatefordb" {
  vpc_id            = aws_vpc.twotier.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "2tierprivate2"
  }
}


resource "aws_internet_gateway" "twotiergw" {
  vpc_id = aws_vpc.twotier.id

  tags = {
    Name = "twotier"
  }
}

resource "aws_route_table" "twotierprivate_rtb" {
  vpc_id = aws_vpc.twotier.id
  tags = {
    Name = "twotier-private-rt"
  }
}

resource "aws_route_table_association" "twotierpri" {
  subnet_id      = aws_subnet.twotierprivate.id
  route_table_id = aws_route_table.twotierprivate_rtb.id
}

resource "aws_route_table_association" "twotierpridb" {
  subnet_id      = aws_subnet.twotierprivatefordb.id
  route_table_id = aws_route_table.twotierprivate_rtb.id
}

data "aws_route_table" "default_public_rtb" {
  subnet_id = aws_subnet.twotierpublic.id
}

resource "aws_route" "route" {
  route_table_id         = data.aws_route_table.default_public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.twotiergw.id
}



################################################################# DB Tier ###################################################################################

resource "aws_db_subnet_group" "aws_db_subnet_group" {
  name        = "twotier-rds-subnet-grp"
  description = "Private Subnet Group to ensure HA in 2Tier application"
  subnet_ids  = [aws_subnet.twotierprivatefordb.id, aws_subnet.twotierprivate.id]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Security group for RDS instances"
  vpc_id      = aws_vpc.twotier.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_security_group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage      = 10
  db_name                = "wordpress"
  engine                 = "mysql"
  engine_version         = "8.4.5"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = var.db_password
  skip_final_snapshot    = true
  port                   = 3306
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.aws_db_subnet_group.name
  availability_zone      = "us-east-1a"

}


####################################################################### APP TIER ################################################################################

resource "aws_security_group" "twotier_pub_sg" {
  name        = "twotier-pub-sg"
  description = "Allow TLS inbound traffic to two tier public ec2 instance where Wordpress is hosted"
  vpc_id      = aws_vpc.twotier.id

  tags = {
    Name = "twotier"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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
}

resource "aws_instance" "twotier_wordpress_instance" {
  ami                         = "ami-0953476d60561c955"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.twotierpublic.id
  associate_public_ip_address = true


  security_groups = [aws_security_group.twotier_pub_sg.id]
  user_data = templatefile("${path.module}/user_data.sh", {
    db_host = aws_db_instance.rds.address
  })

  tags = {
    Name = "2tierpublicsubnet"
  }
}


