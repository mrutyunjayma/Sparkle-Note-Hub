resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#------------------
#Internet Gateway
#-------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#----------------------------
# Public subnets (2AZ)
#----------------------------
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index}"

    # Required for EKS
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

#----------------------------
# Private subnets (2AZ)
#---------------------------

resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr_block, 8, count.index+2)
  availability_zone = var.azs[count.index]
  


  tags = {
    Name = "${var.project_name}-private-${count.index}"

    #Required for EKS
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# -------------------------
# Elastic IP for NAT
# -------------------------
resource "aws_eip" "nat" {
  count = length(var.azs)
  domain = "vpc"
}

# -------------------------
# NAT Gateway
# -------------------------
resource "aws_nat_gateway" "nat" {
  count = length(var.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }
}

# -------------------------
# Public Route Table
# -------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Private Route Table
# -------------------------
resource "aws_route_table" "private" {
  count = length(var.azs)
  vpc_id = aws_vpc.this.id

  tags =  {
    Name = "${var.project_name}-private-rt-${count.index}"
  }
}

resource "aws_route" "private_nat" {
  count = length(var.azs)


  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}