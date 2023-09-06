provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Component   = "o11y-for-${lower(var.slug)}"
    Environment = "production"
  }
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "o11y-ws-vpc" {
  cidr_block           = "10.13.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    local.common_tags,
    {
      "Name" = "o11y-ws-vpc"
    }
  )
}

# Create public subnets, each in a different AZ
resource "aws_subnet" "o11y_ws_subnets" {
  count                   = var.subnet_count
  cidr_block              = cidrsubnet(aws_vpc.o11y-ws-vpc.cidr_block, 8, var.subnet_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.o11y-ws-vpc.id
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    {
      "Name" = "o11y-ws-subnet-${count.index}"
    }
  )
}

# resource "aws_subnet" "o11y-ws-subnet" {
#   vpc_id                  = aws_vpc.o11y-ws-vpc.id
#   cidr_block              = "10.13.0.0/22"
#   map_public_ip_on_launch = true
#   # availability_zone       = "${var.aws_region}a"
#   tags = merge(
#     local.common_tags,
#     {
#       "Name" = "o11y-ws-subnet"
#     }
#   )
# }

resource "aws_security_group" "o11y-ws-sg" {
  name   = "Observability-Workshop-SG"
  vpc_id = aws_vpc.o11y-ws-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 82
    to_port     = 82
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8010
    to_port     = 8010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 13133
    to_port     = 13133
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 55679
    to_port     = 55679
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6501
    to_port     = 6501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "o11y-ws-sg"
    }
  )
}

resource "aws_internet_gateway" "o11y-ws-ig" {
  vpc_id = aws_vpc.o11y-ws-vpc.id
  tags = merge(
    local.common_tags,
    {
      "Name" = "o11y-ws-igw"
    }
  )
}

# resource "aws_route_table" "o11y-ws-rt" {
#   vpc_id = aws_vpc.o11y-ws-vpc.id
#   tags = merge(
#     local.common_tags,
#     {
#       "Name" = "o11y-ws-rt"
#     }
#   )
# }

resource "aws_route" "o11y-ws-route" {
  route_table_id         = aws_vpc.o11y-ws-vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.o11y-ws-ig.id
}

# resource "aws_route" "o11y-ws-route" {
#   route_table_id         = aws_route_table.o11y-ws-rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.o11y-ws-ig.id
# }

# resource "aws_route_table_association" "o11y-ws-rta" {
#   subnet_id      = aws_subnet.o11y-ws-subnet.id
#   route_table_id = aws_route_table.o11y-ws-rt.id
# }

resource "random_string" "password" {
  length           = 16
  override_special = "_%@$#"
}

# ED25519 key
resource "tls_private_key" "pk" {
  # algorithm = "ED25519"
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "o11y-workshop-${var.slug}-kp"
  public_key = tls_private_key.pk.public_key_openssh
}

locals {
  template_vars = {
    access_token      = var.splunk_access_token
    rum_token         = var.splunk_rum_token
    realm             = var.splunk_realm
    hec_token         = var.splunk_hec_token
    hec_url           = var.splunk_hec_url
    presetup          = var.splunk_presetup
    jdk               = var.splunk_jdk
    otel_demo         = var.otel_demo
    wsversion         = var.wsversion
    instance_password = random_string.password.result
    pub_key           = tls_private_key.pk.public_key_openssh
  }
}

resource "aws_instance" "observability-instance" {
  count                  = var.aws_instance_count
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.o11y_ws_subnets.*.id[count.index % length(aws_subnet.o11y_ws_subnets)]
  vpc_security_group_ids = [aws_security_group.o11y-ws-sg.id]

  key_name = aws_key_pair.kp.key_name

  user_data = templatefile("${path.module}/templates/${var.user_data_tpl}", merge(local.template_vars,
    {
      instance_name = "${lower(var.slug)}-${count.index + 1}"
      hec_info      = try(var.splunk_hec_info) ? var.splunk_hec_info[count.index] : { token = var.splunk_hec_token, url = var.splunk_hec_url }

  }))

  root_block_device {
    volume_size = var.instance_disk_aws
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(
    local.common_tags,
    {
      #Name = "observability-${count.index + 1}"
      Instance = "${lower(var.slug)}-${format("%02d", count.index + 1)}"
      Name     = "${lower(var.slug)}-${format("%02d", count.index + 1)}"
      Subnet   = "${aws_subnet.o11y_ws_subnets.*.id[count.index % length(aws_subnet.o11y_ws_subnets)]}"
    }
  )

  lifecycle {
    precondition {
      # if splunk_presetup=true, tokens and realm cannot be empty
      condition     = var.splunk_presetup ? try(var.splunk_access_token, "") != "" && try(var.splunk_realm, "") != "" && try(var.splunk_rum_token, "") != "" : true
      error_message = "When requesting a pre-setup instance, splunk_realm, splunk_access_token and splunk_rum_token are required and cannot be null/empty"
    }
    precondition {
      # if otel_demo=true, tokens and realm cannot be empty. also presetup cannot also be true.
      condition     = var.otel_demo ? try(var.splunk_access_token, "") != "" && try(var.splunk_realm, "") != "" && try(var.splunk_rum_token, "") != "" && try(var.splunk_presetup, "") == false : true
      error_message = "When requesting an otel_demo, splunk_realm, splunk_access_token and splunk_rum_token are required and cannot be null/empty. splunk_presetup variable must also be set to false. "
    }
    precondition {
      # access_token and realm cannot be empty.
      condition     = var.splunk_access_token != "" && var.splunk_realm != ""
      error_message = "splunk_realm and splunk_access_token are required and cannot be null/empty."
    }
    precondition {
      condition     = var.splunk_hec_token != "" ? try(var.splunk_hec_url, "") != "" : true
      error_message = "if splunk_hec_token is defined, splunk_hec_url needs to be defined, too"
    }
    precondition {
      condition     = var.splunk_hec_url != "" ? try(var.splunk_hec_token, "") != "" : true
      error_message = "if splunk_hec_url is defined, splunk_hec_token needs to be defined, too"
    }
    precondition {
      # either splunk_hec_token and splunk_hec_url are defined, or splunk_hec_info is defined, but not both}
      condition     = try(var.splunk_hec_token, "") != "" && try(var.splunk_hec_url, "") != "" ? try(var.splunk_hec_info) == false : true
      error_message = "if splunk_hec_token and splunk_hec_url are defined, splunk_hec_info may not be defined"
    }
    precondition {
      # either splunk_hec_token and splunk_hec_url are defined, or splunk_hec_info is defined, but not both
      condition     = try(var.splunk_hec_info, "") != "" ? try(var.splunk_hec_url) == false && try(var.splunk_hec_token) == false : true
      error_message = "if splunk_hec_info is defined, splunk_hec_token and splunk_hec_url may not be defined"
    }
    precondition {
      condition     = try(var.splunk_hec_info, "") != "" ? length(var.splunk_hec_info) == var.aws_instance_count : true
      error_message = "when using splunk_hec_info, provide an amount of (token, url) value pairs equal to aws_instance_count"
    }
  }
}

locals {
  ssh_priv_key = pathexpand("~/.ssh/id_o11y-workshop-${var.slug}")
}

resource "local_sensitive_file" "ssh_priv_key" {
  filename        = local.ssh_priv_key
  file_permission = "400"
  # directory_permission = "700"
  # content  = tls_private_key.pk.private_key_pem
  content = tls_private_key.pk.private_key_openssh
}

resource "local_file" "ssh_client_config" {
  filename        = pathexpand("~/.ssh/config.d/o11y-workshop-${var.slug}")
  file_permission = "600"
  content = templatefile("${path.module}/templates/ssh_client_config.tpl",
    {
      ips : aws_instance.observability-instance[*].public_ip
      names : aws_instance.observability-instance[*].tags["Instance"]
      key : local.ssh_priv_key
  })
}
