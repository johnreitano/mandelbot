resource "aws_instance" "seed" {
  depends_on = [aws_subnet.seed, aws_security_group.seed]

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

resource "aws_route53_record" "seed_api_a_record" {
  depends_on = [aws_eip.seed]
  count      = var.num_instances

  zone_id = var.dns_zone_id
  name    = "${var.domain_prefix}seed-${count.index}-api"
  type    = "A"
  ttl     = 600
  records = [aws_eip.seed[count.index].public_ip]
}

resource "aws_route53_record" "seed_rpc_a_record" {
  depends_on = [aws_eip.seed]
  count      = var.num_instances

  zone_id = var.dns_zone_id
  name    = "${var.domain_prefix}seed-${count.index}-rpc"
  type    = "A"
  ttl     = 600
  records = [aws_eip.seed[count.index].public_ip]
}

resource "null_resource" "configure_client" {
  depends_on = [aws_security_group.seed, aws_route53_record.seed_api_a_record, aws_route53_record.seed_rpc_a_record]
  count      = var.num_instances

  // copy genesis file from primary validator to explorer node
  provisioner "local-exec" {
    command = <<-EOF
      if [[ "${var.genesis_file_available}" != "true" ]]; then echo "error: no genesis file avalable"; exit 1; fi
      until scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ubuntu@${var.validator_ips[0]}:.mandelbot/config/genesis.json ./upload/genesis.json; do echo "waiting for connection"; sleep 1; done
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
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "upload"
    destination = "."
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  provisioner "file" {
    source      = "modules/seed/upload/"
    destination = "upload"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo configuring seed node...",
      "chmod +x upload/*.sh ./upload/mandelbotd",
      "~/upload/configure-generic-client.sh",
      "~/upload/install-generic-cert.sh ${var.tls_certificate_email} ${var.domain_prefix}seed-${count.index}-rpc.${var.dns_zone_name}",
      "~/upload/install-nginx-cert.sh ${var.tls_certificate_email} ${var.domain_prefix}seed-${count.index}-api.${var.dns_zone_name} 1317",
      "~/upload/configure-seed.sh ${count.index} '${join(",", [for node in aws_eip.seed : node.public_ip])}' '${join(",", var.validator_ips)}'"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key_path)
      host        = aws_eip.seed[count.index].public_ip
    }
  }

  triggers = {
    genesis_file_available = var.genesis_file_available
    instance_created       = join(",", [for r in aws_instance.seed : r.id])
    uploaded_files_changed = join(",", [for f in setunion(fileset(".", "upload/node_key_*.json"), fileset(".", "upload/*.sh"), fileset(".", "modules/seed/upload/*.sh")) : filesha256(f)])
  }
}

resource "null_resource" "start_seed" {
  depends_on = [null_resource.configure_client]
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
    client_configuration_changed = join(",", [for r in null_resource.configure_client : r.id])
  }
}
