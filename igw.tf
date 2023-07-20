resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app-vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.app-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta" {
  count          = 2
  subnet_id      = element(aws_subnet.app-subnets.*.id, count.index)
  route_table_id = aws_route_table.rt.id
}
