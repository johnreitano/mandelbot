resource "aws_instance" "explorer" {
  count                       = var.create_explorer ? 1 : 0
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.explorer_be_0.id
  key_name                    = "mandelbot-key"
  vpc_security_group_ids      = [aws_security_group.explorer_be.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-${0}"
  }
}

resource "aws_eip" "explorer" {
  count    = var.create_explorer ? 1 : 0
  instance = aws_instance.explorer[0].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-explorer-eip-${0}"
  }
}

resource "null_resource" "build_and_configure_client" {
  depends_on = [aws_security_group.explorer_be, aws_eip.explorer, aws_instance.explorer]
  count      = var.create_explorer ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      # copy source to remote node as soon as sshd is available
      until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ${var.compressed_source_path} ubuntu@${aws_eip.explorer[0].public_ip}:/tmp/mandelbot.tar.gz
      do
        sleep 1
        echo -n "."
      done
      echo
    EOF
  }

  provisioner "remote-exec" {
    inline = [
      "echo building client on explorer node...",
      "pkill mandelbotd",
      "rm -rf ~/mandelbot",
      "mkdir ~/mandelbot",
      "cd ~/mandelbot",
      "tar -xzf /tmp/mandelbot.tar.gz",
      "deploy/modules/validator/build-client.sh", # TODO: move this to script dir
      "echo configuring explorer node...",
      "cd ~/mandelbot",
      "echo about to run configure-explorer.sh...",
      "deploy/modules/explorer/configure-explorer.sh '${aws_eip.explorer[0].public_ip}' '${join(",", var.seed_ips)}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[0].public_ip
    }
  }

  provisioner "file" {
    content     = var.validator_genesis_file_contents
    destination = "/home/ubuntu/.mandelbot/config/genesis.json"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[0].public_ip
    }
  }
  triggers = {
    recent_instance_creation = join(",", [for r in aws_instance.explorer : r.id])
    change_to_genesis_file   = var.validator_genesis_file_contents
  }
}

resource "null_resource" "start_explorer" {
  depends_on = [null_resource.build_and_configure_client]
  count      = var.create_explorer ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "echo starting explorer node...",
      "sudo systemctl enable mandelbot.service",
      "sudo systemctl start mandelbot.service",
      "echo done starting explorer node"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.explorer[0].public_ip
    }
  }

  triggers = {
    recent_client_configuration = join(",", [for r in null_resource.build_and_configure_client : r.id])
  }
}
