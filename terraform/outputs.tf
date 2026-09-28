output "ip_publica" {
  description = "Apunta aqui el registro A de tu dominio"
  value       = aws_eip.app.public_ip
}

output "siguiente_paso_dns" {
  description = "Que hacer despues del apply"
  value       = "Crea un registro A de ${var.domain} hacia ${aws_eip.app.public_ip}. Caddy pide el certificado solo cuando el dominio ya resuelve; antes de eso el reto de Let's Encrypt falla."
}

output "ecr_repositorio" {
  description = "A donde se sube la imagen"
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "Endpoint de Postgres. No es publico: solo se llega desde el servidor."
  value       = aws_db_instance.main.endpoint
}

output "entrar_al_servidor" {
  description = "Sin abrir el puerto 22"
  value       = "aws ssm start-session --target ${aws_instance.app.id} --region ${var.region}"
}
