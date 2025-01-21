provider "aws" {
  region = "us-east-1"
}

# Variables
variable "instance_type" {
  default = "t2.small"
}

variable "key_name" {
  default = "prom-grafana-testing-devel-mattj"
}

variable "subnet_id" {
  default = "subnet-08d5b89ee2ee2fd05"
}

# EC2 Instances
resource "aws_instance" "ec2_instance" {
  count         = 2
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  tags = {
    Name = "EC2-instance-${count.index + 1}"
  }
}

# S3 Buckets
resource "aws_s3_bucket" "s3_bucket" {
  count = 2

  bucket = "my-unique-bucket-${count.index + 1}-${random_id.bucket_id[count.index].hex}"
  acl    = "private"

  tags = {
    Name        = "S3 Bucket ${count.index + 1}"
    Environment = "Development"
  }
}

resource "random_id" "bucket_id" {
  count        = 2
  byte_length  = 8
}
