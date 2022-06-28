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
  depends_on = [aws_security_group.validator, aws_eip.validator]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "rm -rf upload",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "upload"
    destination = "."
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
      "echo configuring validator node...",
      "chmod +x ~/upload/*.sh ~/upload/mandelbotd",
      "sudo systemctl stop mandelbot.service || :",
      "~/upload/configure-generic-client.sh",
      "~/upload/configure-validator.sh ${count.index} '${join(",", [for node in aws_eip.validator : node.public_ip])}'",
      "echo generating genesis transaction...",
      "~/upload/generate-gentx.sh ${count.index}",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    instance_created_or_deleted = join(",", [for r in aws_instance.validator : r.id])
    uploaded_files_changed      = join(",", [for f in setunion(fileset(".", "upload/node_key_*.json"), fileset(".", "upload/*.sh"), fileset(".", "modules/validator/upload/*.sh")) : filesha256(f)])

  }
}


resource "null_resource" "generate_genesis_file" {
  # depends_on = [null_resource.copy_gentx_to_primary_validator]
  count = var.num_instances > 0 ? 1 : 0
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${var.num_instances}" < "2" ]]; then exit 0; fi
      rm -rf /tmp/mandelbot/validator/gentx
      mkdir -p /tmp/mandelbot/validator/gentx
      secondary_ips='${join(" ", slice([for node in aws_eip.validator : node.public_ip], 1, var.num_instances))}'
      for secondary_ip in $secondary_ips; do
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@$secondary_ip:.mandelbot/config/gentx/\* /tmp/mandelbot/validator/gentx/
      done
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/mandelbot/validator/gentx/* ubuntu@${aws_eip.validator[0].public_ip}:.mandelbot/config/gentx/
    EOF
  }

  // generate genesis file on primary validator
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

  // download genesis file and copy to secondary validators
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${var.num_instances}" < "2" ]]; then exit 0; fi
      rm -rf /tmp/mandelbot/validator/genesis
      mkdir -p /tmp/mandelbot/validator/genesis
      until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${aws_eip.validator[0].public_ip}:.mandelbot/config/genesis.json /tmp/mandelbot/validator/genesis/genesis.json; do echo "waiting for connection"; sleep 1; done
      secondary_ips='${join(" ", slice([for node in aws_eip.validator : node.public_ip], 1, var.num_instances))}'
      for secondary_ip in $secondary_ips; do
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa /tmp/mandelbot/validator/genesis/genesis.json ubuntu@$secondary_ip:.mandelbot/config/genesis.json      
      done
    EOF
  }

  triggers = {
    client_configured = join(",", [for r in null_resource.configure_client : r.id])
  }
}

resource "null_resource" "start_validator" {
  # depends_on = [null_resource.generate_genesis_file]
  count = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting validator node ${count.index} via systemctl...",
      "sudo systemctl restart mandelbot.service",
      "sleep 1",
      "sudo systemctl status -l mandelbot.service --no-pager",
      "sudo systemctl enable mandelbot.service",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.validator[count.index].public_ip
    }
  }
  triggers = {
    genesis_file_generated = join(",", [for r in null_resource.generate_genesis_file : r.id])
  }
}

