resource "aws_key_pair" "deployer" {
  key_name   = "mandelbot-key"
  public_key = file(var.ssh_public_key_path)
}

