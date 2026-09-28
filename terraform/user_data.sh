#!/bin/bash
set -euxo pipefail

# Arranque del servidor. Corre una sola vez, al crear la instancia.
# El log queda en /var/log/cloud-init-output.log

dnf update -y
dnf install -y docker
systemctl enable --now docker

# Compose v2 como plugin de Docker, que es como se distribuye ahora.
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /opt/${project}
cd /opt/${project}

# Los secretos se leen del Parameter Store con el rol de la instancia. No quedan
# en el user_data, que es visible para cualquiera que pueda describir la instancia.
aws ssm get-parameters-by-path \
  --region ${region} \
  --path "/${project}/" \
  --with-decryption \
  --query "Parameters[].{Name:Name,Value:Value}" \
  --output text | while read -r name value; do
    echo "$${name##*/}=$${value}" >> /opt/${project}/.env
  done
chmod 600 /opt/${project}/.env

cat >> /opt/${project}/.env <<ENVEOF
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
REDIS_URL=redis://redis:6379/0
ENVEOF

# Segunda capa de filtrado, dentro de Caddy. El grupo de seguridad ya bloquea el
# 443, pero si alguien lo abre por error la app sigue sin servirse a cualquiera.
# Caddy es el borde (no hay balanceador delante), asi que remote_ip ve la IP real
# del cliente y no la de un proxy.
if [ -n "${allowed_cidrs}" ]; then
  cat > /opt/${project}/Caddyfile <<CADDYEOF
${domain} {
	encode gzip
	tls ${acme_email}

	@permitidas remote_ip ${allowed_cidrs}
	handle @permitidas {
		reverse_proxy app:3000
	}

	# A todo lo demas se le responde 403 sin revelar que hay detras.
	handle {
		respond "No autorizado" 403
	}
}
CADDYEOF
else
  cat > /opt/${project}/Caddyfile <<CADDYEOF
${domain} {
	encode gzip
	reverse_proxy app:3000
	tls ${acme_email}
}
CADDYEOF
fi

cat > /opt/${project}/docker-compose.yml <<COMPOSEEOF
services:
  # Caddy resuelve el certificado de Let's Encrypt solo, con el dominio del
  # Caddyfile. Por eso el registro DNS tiene que apuntar aca ANTES de levantarlo:
  # el reto HTTP-01 falla si el dominio no resuelve a esta IP.
  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - app
    logging:
      driver: awslogs
      options:
        awslogs-region: ${region}
        awslogs-group: ${log_group}
        awslogs-stream: caddy

  app:
    image: ${ecr_repo}:${image_tag}
    restart: unless-stopped
    env_file: .env
    depends_on:
      - redis
    logging:
      driver: awslogs
      options:
        awslogs-region: ${region}
        awslogs-group: ${log_group}
        awslogs-stream: app

  # Mismo contenedor, otro comando. Toma las 5 colas de su initializer.
  sidekiq:
    image: ${ecr_repo}:${image_tag}
    restart: unless-stopped
    env_file: .env
    command: bundle exec sidekiq
    depends_on:
      - redis
    logging:
      driver: awslogs
      options:
        awslogs-region: ${region}
        awslogs-group: ${log_group}
        awslogs-stream: sidekiq

  # Redis local: solo guarda la cola de Sidekiq. Si se pierde, se pierden trabajos
  # pendientes, no datos del usuario. Por eso no se paga ElastiCache.
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --save 60 1 --appendonly no
    volumes:
      - redis_data:/data

volumes:
  caddy_data:
  caddy_config:
  redis_data:
COMPOSEEOF

aws ecr get-login-password --region ${region} \
  | docker login --username AWS --password-stdin ${ecr_repo}

docker compose -f /opt/${project}/docker-compose.yml up -d

# Servicio systemd para que todo vuelva solo tras un reinicio del servidor.
cat > /etc/systemd/system/${project}.service <<SERVICEEOF
[Unit]
Description=${project}
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/${project}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl enable ${project}.service
