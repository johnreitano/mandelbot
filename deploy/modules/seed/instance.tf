resource "aws_instance" "seed" {
  count                       = var.num_instances
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.seed.id
  key_name                    = "mandelbot-key"
  vpc_security_group_ids      = [aws_security_group.seed.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [associate_public_ip_address]
  }

  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-${count.index}"
  }
}

resource "aws_eip" "seed" {
  count    = var.num_instances
  instance = aws_instance.seed[count.index].id
  vpc      = true
  tags = {
    Environment = var.env
    Project     = var.project
    Name        = "${var.project}-${var.env}-seed-eip-${count.index}"
  }
}

resource "null_resource" "build_and_configure_client" {
  depends_on = [aws_security_group.seed, aws_eip.seed, aws_instance.seed]
  count      = var.num_instances

  # provisioner "local-exec" {
  #   command = <<-EOF
  #     # copy source to remote node as soon as sshd is available
  #     until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ${var.compressed_source_path} ubuntu@${aws_eip.seed[count.index].public_ip}:/tmp/mandelbot.tar.gz
  #     do
  #       sleep 1
  #       echo -n "."
  #     done
  #     echo
  #   EOF
  # }

  provisioner "remote-exec" {
    inline = [
      "echo building client on seed node...",
      "pkill mandelbotd",
      "rm -rf ~/mandelbot",
      "mkdir ~/mandelbot",
      "cd ~/mandelbot",
      "tar -xzf /tmp/mandelbot.tar.gz",
      "deploy/modules/validator/build-client.sh", # TODO: move this to script dir
      "echo configuring seed node...",
      "pkill mandelbotd",
      "cd ~/mandelbot",
      "deploy/modules/seed/configure-seed.sh ${count.index} '${join(",", [for node in aws_eip.seed : node.public_ip])}' '${join(",", var.validator_ips)}'",
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  provisioner "file" {
    content     = var.validator_genesis_file_contents
    destination = "/home/ubuntu/.mandelbot/config/genesis.json"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }
  triggers = {
    recent_instance_creation = join(",", [for r in aws_instance.seed : r.id])
    change_to_genesis_file   = var.validator_genesis_file_contents
    x                        = "2"
  }
}

resource "null_resource" "start_seed" {
  depends_on = [null_resource.build_and_configure_client]
  count      = var.num_instances

  provisioner "remote-exec" {
    inline = [
      "echo starting seed node...",
      "sudo systemctl enable mandelbot.service",
      "sudo systemctl start mandelbot.service",
      "echo done starting seed node"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  triggers = {
    recent_client_configuration = join(",", [for r in null_resource.build_and_configure_client : r.id])
  }
}
