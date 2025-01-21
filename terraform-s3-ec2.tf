provider "aws" {
  region = "us-east-1"
}

# Variables
variable "instance_type" {
  default = "t2.medium"
}

variable "key_name" {
  default = "prom-grafana-testing-devel-mattj"
}

variable "subnet_id" {
  default = "subnet-08d5b89ee2ee2fd05"
}

# EC2 Instances
resource "aws_instance" "ec2_instance" {
  count         = 3
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id

  tags = {
    Name      = "EC2-instance-${count.index + 1}"
    yor_name  = "ec2_instance"
    yor_trace = "e8b0c0cf-da84-48dc-b457-82cae4429f58"
  }
}

# S3 Buckets
resource "aws_s3_bucket" "s3_bucket" {
  count = 3

  bucket = "my-unique-bucket-${count.index + 1}-${random_id.bucket_id[count.index].hex}"
  acl    = "private"

  tags = {
    Name                 = "S3 Bucket ${count.index + 1}"
    Environment          = "Development"
    yor_name             = "s3_bucket"
    yor_trace            = "c37f6ec7-3f3d-4bf2-9788-5c1651d61154"
    git_commit           = "28885922b4bccf09690e76f6f25f19d170a2996e"
    git_file             = "terraform-s3-ec2.tf"
    git_last_modified_at = "2025-01-21 15:45:41"
    git_last_modified_by = "matt+github@metahertz.co.uk"
    git_modifiers        = "matt+github"
    git_org              = "metahertz"
    git_repo             = "demo-infra-code"
  }
}

resource "random_id" "bucket_id" {
  count       = 3
  byte_length = 8
}
