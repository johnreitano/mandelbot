resource "aws_instance" "explorer" {
  count                       = var.create_explorer ? 1 : 0
  ami                         = "ami-0d70546e43a941d70"
  instance_type               = "t2.medium"
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
    Name        = "${var.project}-${var.env}-explorer"
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

resource "aws_route53_record" "explorer_a_record" {
  depends_on = [aws_eip.explorer]
  count      = var.create_explorer ? 1 : 0

  zone_id = var.dns_zone_id
  name    = "${var.domain_prefix}explorer"
  type    = "A"
  ttl     = 600
  records = [aws_eip.explorer[count.index].public_ip]
}

resource "null_resource" "configure_client" {
  depends_on = [aws_security_group.explorer, aws_route53_record.explorer_a_record]
  count      = var.create_explorer ? 1 : 0

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
      "chmod +x ~/upload/*.sh",
      "~/upload/configure-generic-client.sh",
      "~/upload/install-generic-cert.sh ${var.tls_certificate_email} ${var.domain_prefix}explorer.${var.dns_zone_name}",
      "~/upload/configure-explorer.sh ${count.index} ${var.domain_prefix}explorer.${var.dns_zone_name}"
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
    uploaded_files_changed = join(",", [for f in setunion(fileset(".", "upload/*.sh"), fileset(".", "modules/explorer/upload/*.sh")) : filesha256(f)])
  }
}

resource "null_resource" "start_explorer" {
  depends_on = [null_resource.configure_client]
  count      = var.create_explorer ? 1 : 0

  provisioner "remote-exec" {
    inline = [
      "echo starting block explorer...",
      "sudo systemctl enable explorer.service",
      "sudo systemctl start explorer.service",
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

