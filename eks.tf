provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

# Create an IAM role for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
  tags = {
    yor_name  = "eks_cluster_role"
    yor_trace = "9df0f6a7-0485-4166-9d3b-27df376f6d53"
  }
}

# Attach the AmazonEKSClusterPolicy to the IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Create the EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "small-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = ["subnet-08d5b89ee2ee2fd05", "subnet-04aed5950840cd975"] # Replace with your subnet IDs
  }

  tags = {
    Environment = "dev"
    Project     = "eks-demo"
    yor_name    = "eks_cluster"
    yor_trace   = "d4b0f560-0692-41df-b947-24e929bf24ba"
  }
}

# Create a Node Group for the EKS cluster
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "small-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_eks_cluster.eks_cluster.vpc_config[0].subnet_ids

  scaling_config {
    desired_size = 2 # Set your desired node count
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]

  remote_access {
    ec2_ssh_key = "prom-grafana-testing-devel-mattj" # Replace with your SSH key name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy
  ]
  tags = {
    yor_name  = "eks_node_group"
    yor_trace = "3d703e8b-089f-46ed-accb-c0dd02d5a94d"
  }
}

# IAM Role for the Node Group
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
  tags = {
    yor_name  = "eks_node_role"
    yor_trace = "b9910a22-a95c-43ee-a7a5-3a19da0f63ab"
  }
}

# Attach the AmazonEKSWorkerNodePolicy and other policies to the Node IAM Role
resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_node_role.name
}

# Output kubeconfig for accessing the cluster
resource "local_file" "kubeconfig" {
  content  = <<-EOT
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks_cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority[0].data}
  name: ${aws_eks_cluster.eks_cluster.name}
contexts:
- context:
    cluster: ${aws_eks_cluster.eks_cluster.name}
    user: ${aws_eks_cluster.eks_cluster.name}
  name: ${aws_eks_cluster.eks_cluster.name}
current-context: ${aws_eks_cluster.eks_cluster.name}
users:
- name: ${aws_eks_cluster.eks_cluster.name}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
      - "eks"
      - "get-token"
      - "--cluster-name"
      - "${aws_eks_cluster.eks_cluster.name}"
EOT
  filename = "./kubeconfig-${aws_eks_cluster.eks_cluster.name}"
}

output "kubeconfig_path" {
  value = local_file.kubeconfig.filename
}
