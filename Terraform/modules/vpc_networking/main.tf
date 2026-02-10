
resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = var.dns_support
  enable_dns_hostnames = var.dns_hostname


  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}"
    },
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets_config

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, each.value.newbits, each.value.netnum)
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]

  map_public_ip_on_launch = each.value.is_public

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
    },
  )
}

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets_config

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, each.value.newbits, each.value.netnum)
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
    },
  )
}

resource "aws_subnet" "isolated_subnets" {
  for_each = var.isolated_subnets_config

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, each.value.newbits, each.value.netnum)
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index]

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-${each.key}"
    },
  )
}

resource "aws_eip" "nat" {

  # count is basically an on/of switch to create this resource
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-eip"
    },
  )
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id

  # this requires the map_public_ip_on_launch in the subnet to be true in at least one subnet
  subnet_id = [
    for subnet in aws_subnet.public_subnets : subnet.id
    if subnet.map_public_ip_on_launch == true
  ][0]

  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-gw"
    },
  )
}

resource "aws_internet_gateway" "igw" {
  count = var.enable_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    },
  )
}

resource "aws_route_table" "public" {
  count = var.enable_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[count.index].id
  }

  tags = merge(
    var.tags,
    local.common_tags,
    { Name = "${var.vpc_name}-public-rt" }
  )
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets_config) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    local.common_tags,
    { Name = "${var.vpc_name}-private-rt" }
  )
}

resource "aws_route_table" "private_nat_access" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = merge(
    var.tags,
    local.common_tags,
    { Name = "${var.vpc_name}-private-nat-rt" }
  )
}

resource "aws_route_table" "isolated" {
  count = length(var.isolated_subnets_config) > 0 ? 1 : 0

  vpc_id = aws_vpc.main.id

  # This table now only allows internal VPC traffic.

  tags = merge(
    var.tags,
    local.common_tags,
    { Name = "${var.vpc_name}-isolated-rt" }
  )
}

resource "aws_route_table_association" "public_rt_association" {
  for_each = var.public_subnets_config

  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private_rt_nat_association" {
  for_each = {
    for key, value in var.private_subnets_config : key => value
    if value.needs_nat_gw == true
  }

  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_nat_access[0].id
}

resource "aws_route_table_association" "private_rt_association" {
  for_each = {
    for key, value in var.private_subnets_config : key => value
    if value.needs_nat_gw == false
  }

  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "isolated_rt_association" {
  for_each = {
    for key, value in var.isolated_subnets_config : key => value
    if value.isolated_on == true
  }

  subnet_id      = aws_subnet.isolated_subnets[each.key].id
  route_table_id = aws_route_table.isolated[0].id
}

# AWS automatically creates a route table and routetable association for subnets without both, \
# this route is only for local traffic




