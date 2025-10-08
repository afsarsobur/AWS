resource "aws_instance" "sobur" {
  ami           = "ami-0e872aee57663ae2d"
  instance_type = "t2.micro"

  tags = {
    Name = "sobur"
  }
}
