# ── Secretos ────────────────────────────────────────────────────────────────
#
# Van en SSM Parameter Store como SecureString, que es gratis hasta 10 mil
# parametros estandar. Secrets Manager cobra 0.40 USD por secreto al mes, y aqui
# no hace falta su rotacion automatica.
#
# El servidor los lee al arrancar con su rol de instancia. No viajan en la imagen
# ni quedan en el user_data.

resource "random_id" "secret_key_base" {
  byte_length = 64
}

resource "aws_ssm_parameter" "secret_key_base" {
  name        = "/${var.project}/SECRET_KEY_BASE"
  description = "Firma de sesiones y de los JWT de la API movil"
  type        = "SecureString"
  value       = random_id.secret_key_base.hex
}

resource "aws_ssm_parameter" "database_url" {
  name        = "/${var.project}/DATABASE_URL"
  description = "Cadena de conexion a Postgres"
  type        = "SecureString"
  value       = "postgres://${aws_db_instance.main.username}:${random_password.db.result}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
}

resource "aws_ssm_parameter" "anthropic_api_key" {
  name        = "/${var.project}/ANTHROPIC_API_KEY"
  description = "Chatbot y reportes de IA"
  type        = "SecureString"
  value       = var.anthropic_api_key
}
