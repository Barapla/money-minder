# ── Servidor de la app ──────────────────────────────────────────────────────

data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project}-app"
  description = "Servidor de la app: HTTP y HTTPS abiertos, SSH cerrado salvo que se indique"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP. Caddy redirige a HTTPS y lo usa para el reto de Let's Encrypt"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    # Vacio por defecto: se entra por SSM Session Manager, sin puerto abierto.
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-app" }
}

resource "aws_key_pair" "app" {
  count = var.ssh_public_key == "" ? 0 : 1

  key_name   = var.project
  public_key = var.ssh_public_key
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023_arm.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name
  key_name               = var.ssh_public_key == "" ? null : aws_key_pair.app[0].key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    # IMDSv2 obligatorio: cierra la puerta al robo de credenciales del rol via SSRF.
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    project    = var.project
    region     = var.region
    ecr_repo   = aws_ecr_repository.app.repository_url
    image_tag  = var.image_tag
    domain     = var.domain
    acme_email = var.acme_email
    log_group  = aws_cloudwatch_log_group.app.name
  })

  # Cambiar el user_data recrea la instancia. Se declara para que el plan lo diga
  # en vez de aplicar el cambio en silencio sin efecto.
  user_data_replace_on_change = true

  tags = { Name = var.project }

  depends_on = [aws_db_instance.main]
}

# IP fija: sin esto la IP publica cambia en cada reinicio y el DNS que apuntes
# deja de servir.
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = { Name = var.project }
}
