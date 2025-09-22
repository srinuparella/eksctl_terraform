## Create a Virtual Private Cloud (VPC) where all AWS resources will live
resource "aws_vpc" "dev_vpc" {
  cidr_block = var.kub_sub.vpccidr
  tags = {
    Name = var.kub_sub.vpcname
  }
}

## Create a Subnet inside the VPC (for EC2, EKS, etc.)
resource "aws_subnet" "dev_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = var.kub_sub.subnetvalues.subcidr
  availability_zone = var.kub_sub.subnetvalues.subaz
  tags = {
    Name = var.kub_sub.subnetvalues.subname
  }
}

## Create an Internet Gateway (IGW) to allow VPC resources to access the internet
resource "aws_internet_gateway" "dev_ig" {
  vpc_id = aws_vpc.dev_vpc.id
  tags = {
    Name = var.kub_sub.ig_values.ig_name
  }
}

## Create a Route Table to define how traffic flows out of the subnet
## Adds a default route (0.0.0.0/0) through the Internet Gateway
resource "aws_route_table" "dev_rt" {
  vpc_id = aws_vpc.dev_vpc.id
  route {
    cidr_block = var.kub_sub.rt_values.rtcidr
    gateway_id = aws_internet_gateway.dev_ig.id
  }
  tags = {
    Name = var.kub_sub.rt_values.rtname
  }
}

## Associate the Route Table with the Subnet
## Ensures traffic from subnet follows the IGW route
resource "aws_route_table_association" "dev_rt_ass" {
  subnet_id      = aws_subnet.dev_subnet.id
  route_table_id = aws_route_table.dev_rt.id
}

## Create a Security Group (firewall rules) for the EC2 instance
resource "aws_security_group" "dev_sg" {
  name        = var.kub_sub.sg_values.sgname
  vpc_id      = aws_vpc.dev_vpc.id
  description = var.kub_sub.sg_values.sgdecs

  ## Ingress = inbound rules (who can access this EC2)
  ingress {
    from_port   = var.kub_sub.ingress_values.ing_from_port
    to_port     = var.kub_sub.ingress_values.ing_to_port
    protocol    = var.kub_sub.ingress_values.ingproto
    cidr_blocks = [var.kub_sub.ingress_values.ingcidr]
    description = var.kub_sub.ingress_values.ingdesc
  }

  ## Egress = outbound rules (what EC2 can access outside)
  egress {
    from_port   = var.kub_sub.egress_values.egr_from_port
    to_port     = var.kub_sub.egress_values.egr_to_port
    protocol    = var.kub_sub.egress_values.egrproto
    cidr_blocks = [var.kub_sub.egress_values.egrcidr]
    description = var.kub_sub.egress_values.egrdesc
  }
}

## Create an S3 Bucket (can be used for logs, state, backups, etc.) 
## first create s3 thren next use init for backend 
resource "aws_s3_bucket" "dev_bucket" {
  bucket = "dev-richard-bucket"
}

## Create a Key Pair for SSH access into EC2
## The public key comes from your local ~/.ssh/id_ed25519.pub
resource "aws_key_pair" "dev_key" {
  key_name   = var.kub_sub.keypair.keyname
  public_key = file(var.kub_sub.keypair.pubkey)
}

## Launch an EC2 instance inside the subnet, secured by the SG
resource "aws_instance" "dev_ec2" {
  ami                         = "ami-02d26659fd82cf299"   # Ubuntu AMI
  instance_type               = "m7i-flex.large"
  subnet_id                   = aws_subnet.dev_subnet.id
  vpc_security_group_ids      = [aws_security_group.dev_sg.id]
  key_name                    = "dev-key-pair"
  associate_public_ip_address = true
  tags = {
    Name = "dev-ec2"
  }
}

## Provisioner: Run commands on the EC2 after it is created
resource "null_resource" "dev_provision" {
  triggers = {
    Build_Version = "2.0"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.dev_ec2.public_ip
    private_key = file("~/.ssh/<your pvt key>")
  }

  provisioner "remote-exec" {
    inline = [
      # Update packages
      "sudo apt update -y",
      "sudo apt install -y unzip curl",
      
        # Apply docker group immediately (no logout required) thats why using <<EONG
       # 2. Install Docker
      # --------------------------
      "curl -fsSL https://get.docker.com -o install-docker.sh",
      "sudo sh install-docker.sh",
      "rm -f install-docker.sh",
      "sudo usermod -aG docker ubuntu",
      "newgrp docker -c 'docker --version && docker run hello-world || true'",
    

      # Install AWS CLI v2
      "curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
      "unzip -o awscliv2.zip",
      "sudo ./aws/install",
      "rm -rf aws awscliv2.zip",

       # Configure AWS credentials
      "aws configure set aws_access_key_id <Yours Access Key>",
      "aws configure set aws_secret_access_key <Your Secret Key>",
      "aws configure set default.region ap-south-1",

      # Install eksctl (Linux amd64)
      "ARCH=amd64 && PLATFORM=$(uname -s)_$${ARCH} && curl -sLO https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$${PLATFORM}.tar.gz && curl -sL https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_checksums.txt | grep $${PLATFORM} | sha256sum --check && tar -xzf eksctl_$${PLATFORM}.tar.gz -C /tmp && sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm -rf eksctl_$${PLATFORM}.tar.gz /tmp/eksctl",

      # Install kubectl (latest stable)
      "KUB_VER=$(curl -sL https://dl.k8s.io/release/stable.txt)",
      "curl -LO https://dl.k8s.io/release/$${KUB_VER}/bin/linux/amd64/kubectl",
      "curl -LO https://dl.k8s.io/release/$${KUB_VER}/bin/linux/amd64/kubectl.sha256",
      "echo \"$(cat kubectl.sha256)  kubectl\" | sha256sum --check",
      "sudo mv kubectl /usr/local/bin/",
      "sudo chmod +x /usr/local/bin/kubectl",
      "rm -f kubectl.sha256",

      # Verify kubectl installed
      "which kubectl",
      "kubectl version --client --output=yaml",

    #   # Create EKS cluster only if it doesn't exist
    #   "if ! eksctl get cluster --name mycluster --region ap-south-1 >/dev/null 2>&1; then eksctl create cluster --name mycluster --region ap-south-1 --node-type m7i-flex.large; else echo 'Cluster mycluster already exists, skipping creation.'; fi"
    "eksctl create cluster --name mycluster --region ap-south-1 --node-type m7i-flex.large "
    
    ]
  }
#    provisioner "remote-exec" {
#     when    = destroy
#     inline = [
#       "echo 'Deleting EKS cluster...'",
#       "eksctl delete cluster --name mycluster --region ap-south-1 --wait"
#     ]
# }
}

