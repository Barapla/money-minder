# ── Postgres administrado ───────────────────────────────────────────────────

resource "random_password" "db" {
  length  = 32
  special = false # Evita caracteres que romperian la DATABASE_URL al interpolarse
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "db" {
  name        = "${var.project}-db"
  description = "Postgres, solo desde el servidor de la app"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = { Name = "${var.project}-db" }
}

resource "aws_db_instance" "main" {
  identifier     = var.project
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 3 # Crece solo antes de llenarse
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "money_minder_production"
  username = "money_minder"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = var.db_backup_retention_days
  backup_window           = "07:00-08:00" # UTC, de madrugada en Mexico
  maintenance_window      = "Mon:08:30-Mon:09:30"

  auto_minor_version_upgrade = true
  deletion_protection        = true

  # Con deletion_protection activo esto no aplica, pero si algun dia se desactiva
  # para destruir el entorno, al menos queda una copia final.
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  lifecycle {
    # El nombre del snapshot lleva timestamp: sin esto cada plan saldria con cambios.
    ignore_changes = [final_snapshot_identifier]
  }
}
