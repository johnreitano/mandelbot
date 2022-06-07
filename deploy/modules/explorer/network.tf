resource "aws_subnet" "explorer_fe" {
  vpc_id            = var.vpc_id
  cidr_block        = var.fe_subnet_cidr
  availability_zone = "us-west-2a"

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-fe-subnet"
  }
}
resource "aws_subnet" "explorer_be_0" {
  vpc_id            = var.vpc_id
  cidr_block        = var.be_0_subnet_cidr
  availability_zone = "us-west-2a"

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-0-subnet"
  }
}

resource "aws_subnet" "explorer_be_1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.be_1_subnet_cidr
  availability_zone = "us-west-2b"

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-1-subnet"
  }
}

resource "aws_db_subnet_group" "explorer_be_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.explorer_be_0.id, aws_subnet.explorer_be_1.id]

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-subnet-group"
  }
}


resource "aws_route_table" "explorer_fe" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-fe-route-table"
  }
}

resource "aws_route_table_association" "explorer_fe" {
  subnet_id      = aws_subnet.explorer_fe.id
  route_table_id = aws_route_table.explorer_fe.id
}

resource "aws_route_table" "explorer_be_0" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id # TODO: change or remove this
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-0-route-table"
  }
}

resource "aws_route_table_association" "explorer_be_0" {
  subnet_id      = aws_subnet.explorer_be_0.id
  route_table_id = aws_route_table.explorer_be_0.id
}

resource "aws_route_table" "explorer_be_1" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id # TODO: change or remove this
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-1-route-table"
  }
}

resource "aws_route_table_association" "explorer_be_1" {
  subnet_id      = aws_subnet.explorer_be_1.id
  route_table_id = aws_route_table.explorer_be_1.id
}

resource "aws_security_group" "explorer_fe" {
  name        = "${var.env}-explorer-fe-sg"
  description = "SG to alllow traffic from the explorer clients"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["68.101.219.8/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["68.101.219.8/32"]
  }

  ingress {
    from_port   = 1317
    to_port     = 1317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 26656
    to_port     = 26656
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 26657
    to_port     = 26657
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-sg"
  }
}


resource "aws_security_group" "explorer_be" {
  name        = "${var.env}-explorer-be-sg"
  description = "SG to alllow traffic from the explorer clients"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["68.101.219.8/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["68.101.219.8/32"]
  }

  ingress {
    from_port   = 1317
    to_port     = 1317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 26656
    to_port     = 26656
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 26657
    to_port     = 26657
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-be-sg"
  }
}
