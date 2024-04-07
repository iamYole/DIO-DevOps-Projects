
# Create Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.dio-vpc.id
  tags = merge(
    var.tags,
    {
      Name = "${var.tag_prefix}_IGW"
    }
  )
}

# Create Elastic IP
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = "${var.tag_prefix}_NAT_EIP"
    },
  )
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = "${var.tag_prefix}_NAT"
    },
  )
}

