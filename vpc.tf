# Network layout (per environment):
#   VPC
#   ├── Public subnets  (1 per AZ) -> route 0.0.0.0/0 via Internet Gateway   [ALB, NAT Gateways]
#   └── Private subnets (1 per AZ) -> route 0.0.0.0/0 via NAT Gateway in same AZ [EC2 instances]

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# ---------------------------------------------------------------------------
# Public subnets - reachable from the internet through the Internet Gateway
# ---------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# All non-local traffic from public subnets goes out through the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# NAT Gateways - let private instances reach the internet (outbound only)
# prod: one per AZ so losing one AZ doesn't cut off the other AZ's instances
# dev:  a single shared NAT to save cost (NAT Gateways are billed per hour)
# ---------------------------------------------------------------------------

locals {
  nat_gateway_count = var.environment == "prod" ? length(var.private_subnet_cidrs) : 1
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip-${count.index + 1}"
  }

  # An EIP for a NAT Gateway only works once the VPC has an Internet Gateway
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # NAT lives in the PUBLIC subnet of the same AZ

  tags = {
    Name = "${var.environment}-nat-${count.index + 1}"
  }
}

# ---------------------------------------------------------------------------
# Private subnets - no direct inbound access from the internet
# ---------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
  }
}

# One route table per private subnet
# prod: each points at the NAT Gateway in its own AZ
# dev:  all point at the single NAT Gateway (index capped at 0)
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-private-rt-${count.index + 1}"
  }
}

resource "aws_route" "private_nat" {
  count                  = length(aws_subnet.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[min(count.index, local.nat_gateway_count - 1)].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
