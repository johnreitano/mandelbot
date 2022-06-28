resource "aws_instance" "explorer" {
  count                       = var.create_explorer ? 1 : 0
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.explorer.id
  key_name                    = "mandelbot-key"
  vpc_security_group_ids      = [aws_security_group.explorer.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-${count.index}"
  }
}

resource "aws_eip" "explorer" {
  count    = var.create_explorer ? 1 : 0
  instance = aws_instance.explorer[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-eip-${count.index}"
  }
}

resource "null_resource" "configure_client" {
  depends_on = [aws_security_group.explorer, aws_eip.explorer]
  count      = var.create_explorer ? 1 : 0

  // copy genesis file from primary validator to explorer node
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${var.genesis_file_available}" != "true" ]]; then echo "error: no genesis file avalable"; exit 1; fi
      until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${var.validator_ips[0]}:.mandelbot/config/genesis.json upload/genesis.json; do echo "waiting for connection"; sleep 1; done
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf upload",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "upload"
    destination = "."
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "modules/explorer/upload/"
    destination = "upload"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[count.index].public_ip
    }
  }


  provisioner "remote-exec" {
    inline = [
      "echo configuring explorer node...",
      "chmod +x upload/*.sh ~/upload/mandelbotd",
      "~/upload/configure-generic-client.sh",
      "~/upload/configure-explorer.sh '${aws_eip.explorer[0].public_ip}' '${join(",", var.seed_ips)}'"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[count.index].public_ip
    }
  }

  triggers = {
    instance_created       = join(",", [for r in aws_instance.explorer : r.id])
    uploaded_files_changed = join(",", [for f in setunion(fileset(".", "upload/node_key_*.json"), fileset(".", "upload/*.sh"), fileset(".", "modules/explorer/upload/*.sh")) : filesha256(f)])
  }
}

resource "null_resource" "start_explorer" {
  depends_on = [null_resource.configure_client]
  count      = var.create_explorer ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "echo starting explorer node...",
      "sudo systemctl enable mandelbot",
      "sudo systemctl start mandelbot",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[0].public_ip
    }
  }

  triggers = {
    recent_client_configuration = join(",", [for r in null_resource.configure_client : r.id])
  }
}
