resource "aws_instance" "validator" {
  count                       = var.num_instances
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.validator.id
  key_name                    = "mandelbot-key"
  vpc_security_group_ids      = [aws_security_group.validator.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-${count.index}"
  }
}

resource "aws_eip" "validator" {
  count    = var.num_instances
  instance = aws_instance.validator[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-validator-eip-${count.index}"
  }
}



resource "null_resource" "configure_client" {
  depends_on = [aws_security_group.validator, aws_eip.validator, var.build_linux_executable_id]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "mkdir -p upload",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "upload/"
    destination = "upload"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "modules/validator/upload/"
    destination = "upload"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x upload/*.sh upload/mandelbotd",
      "echo configuring validator node...",
      "upload/configure-generic-client.sh",
      "upload/configure-validator.sh ${count.index} '${join(",", [for node in aws_eip.validator : node.public_ip])}'",
      "echo generating genesis transaction...",
      "upload/generate-gentx.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    recent_instance_creation = join(",", concat([for r in aws_instance.validator : r.id], [var.build_linux_executable_id]))
  }
}

resource "null_resource" "copy_gentx_to_primary_validator" {
  depends_on = [null_resource.configure_client]
  count      = var.num_instances <= 1 ? 0 : var.num_instances - 1

  provisioner "local-exec" {
    command = <<-EOF
      rm -rf /tmp/mandelbot/validator/gentx
      mkdir -p /tmp/mandelbot/validator/gentx
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[count.index + 1].public_ip}:.mandelbot/config/gentx/\* /tmp/mandelbot/validator/gentx/
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/mandelbot/validator/gentx/* ubuntu@${aws_eip.validator[0].public_ip}:.mandelbot/config/gentx/
    EOF
  }
  triggers = {
    recent_client_configuration = join(",", concat([for r in null_resource.configure_client : r.id]))
  }
}

resource "null_resource" "generate_genesis_file" {
  depends_on = [null_resource.copy_gentx_to_primary_validator]
  count      = var.num_instances > 0 ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "echo generating genesis file on primary validator node",
      "upload/generate-genesis-file.sh",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[0].public_ip
    }
  }

  triggers = {
    recent_client     = join(",", [for r in null_resource.configure_client : r.id])
    recent_gentx_copy = join(",", [for r in null_resource.copy_gentx_to_primary_validator : r.id])
  }
}

resource "null_resource" "download_genesis_file" {
  depends_on = [null_resource.configure_client, null_resource.generate_genesis_file]
  count      = var.num_instances <= 1 ? 0 : 1

  provisioner "local-exec" {
    command = <<-EOF
      # download genesis file from first validator to temporary file
      rm -rf /tmp/mandelbot/validator/genesis
      mkdir -p /tmp/mandelbot/validator/genesis
      until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.mandelbot/config/genesis.json /tmp/mandelbot/validator/genesis/genesis.json; do echo "waiting for connection"; sleep 1; done
      echo
    EOF
  }
  triggers = {
    recent_genesis_file_generation = var.num_instances > 0 ? null_resource.generate_genesis_file[0].id : ""
    genesis_file_deleted           = !fileexists("/tmp/mandelbot/validator/genesis/genesis.json") ? "true" : "false"
  }
}

data "local_file" "genesis_file" {
  depends_on = [null_resource.configure_client, null_resource.copy_gentx_to_primary_validator, null_resource.generate_genesis_file, null_resource.download_genesis_file]
  filename   = "/tmp/mandelbot/validator/genesis/genesis.json"
}

locals {
  genesis_file_content = data.local_file.genesis_file.content
}

resource "null_resource" "copy_genesis_file_to_secondary_validator" {
  depends_on = [null_resource.download_genesis_file, data.local_file.genesis_file, local.genesis_file_content]
  count      = var.num_instances <= 1 ? 0 : var.num_instances - 1
  provisioner "file" {
    content     = local.genesis_file_content
    destination = "/home/ubuntu/.mandelbot/config/genesis.json"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index + 1].public_ip
    }
  }

  triggers = {
    recent_genesis_file_content = local.genesis_file_content
  }
}

resource "null_resource" "start_validator" {
  depends_on = [null_resource.copy_genesis_file_to_secondary_validator]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting validator node ${count.index} via systemctl...",
      "sudo systemctl enable mandelbot.service",
      "sudo systemctl start mandelbot.service",
      "sleep 3",
      "sudo systemctl status mandelbot.service --no-pager",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    recent_genesis_file_copy = join(",", [for r in null_resource.copy_genesis_file_to_secondary_validator : r.id])
  }
}
