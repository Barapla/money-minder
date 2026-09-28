variable "project" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "money-minder"
}

variable "region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de EC2. t4g es Graviton (ARM), por eso la imagen se construye para arm64."
  type        = string
  default     = "t4g.small"
}

variable "db_instance_class" {
  description = "Tipo de RDS"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "GB de disco para RDS"
  type        = number
  default     = 20
}

variable "db_backup_retention_days" {
  description = "Dias de retencion de respaldos automaticos. En 0 se desactivan y se pierde el point-in-time recovery."
  type        = number
  default     = 7
}

variable "domain" {
  description = "Dominio de la app. Caddy pide el certificado de Let's Encrypt para este nombre. El registro DNS lo apuntas tu."
  type        = string
}

variable "acme_email" {
  description = "Correo para los avisos de vencimiento de Let's Encrypt"
  type        = string
}

variable "allowed_cidrs" {
  description = <<-DESC
    Quien puede entrar a la app, en notacion CIDR. Una IP suelta se escribe /32,
    por ejemplo ["189.203.44.10/32", "201.140.0.0/16"].

    Aplica al puerto 443. El 80 NO se puede cerrar: el reto HTTP-01 de Let's
    Encrypt lo validan servidores suyos desde IPs que no publican, asi que
    cerrarlo deja a Caddy sin poder renovar el certificado. En el 80 solo queda
    la redireccion a HTTPS y el reto; la app no se sirve por ahi.

    Vacio significa abierto a todos, que es el comportamiento anterior.
  DESC
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Cada entrada debe ser un CIDR valido. Una IP suelta lleva /32, por ejemplo 189.203.44.10/32."
  }
}

variable "ssh_allowed_cidrs" {
  description = "Desde donde se permite SSH. Por defecto nadie: se entra por SSM Session Manager, que no necesita puerto abierto."
  type        = list(string)
  default     = []
}

variable "ssh_public_key" {
  description = "Llave publica para SSH. Vacio si solo usas SSM."
  type        = string
  default     = ""
}

variable "anthropic_api_key" {
  description = "Llave de la API de Anthropic para el chatbot y los reportes de IA"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "Tag de la imagen en ECR que corre el servidor"
  type        = string
  default     = "latest"
}
