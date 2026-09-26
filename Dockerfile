# syntax=docker/dockerfile:1
#
# Imagen de PRODUCCION. El flujo local sigue siendo bin/dev; esto no lo reemplaza.
#
#   docker build -t money-minder .
#   docker run -p 3000:3000 \
#     -e SECRET_KEY_BASE=... \
#     -e DATABASE_URL=postgres://user:pass@host:5432/money_minder_production \
#     -e REDIS_URL=redis://host:6379/0 \
#     -e ANTHROPIC_API_KEY=... \
#     money-minder
#
# El mismo contenedor corre Sidekiq cambiando el comando:
#   docker run ... money-minder bundle exec sidekiq

ARG RUBY_VERSION=3.2.2
ARG NODE_VERSION=24.15.0
ARG YARN_VERSION=1.22.22

# ── Base: lo minimo que necesita para CORRER ────────────────────────────────
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Este proyecto no tiene config/master.key, asi que los secretos entran por
# variables de entorno y no por credentials encriptadas.
# assets.compile = false en produccion: los assets se precompilan en el build y
# Puma los sirve gracias a RAILS_SERVE_STATIC_FILES.
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libpq5 \
      libvips42 \
      postgresql-client \
      tzdata && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ── Build: compiladores, Node y assets. Nada de esto llega a la imagen final ──
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Node hace falta en esta etapa, no solo para yarn: assets:precompile dispara los
# hooks de jsbundling y cssbundling, que corren esbuild y tailwind.
ARG NODE_VERSION
ARG YARN_VERSION
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      | tar -xJ -C /usr/local --strip-components=1 --no-same-owner && \
    npm install -g "yarn@${YARN_VERSION}" && \
    npm cache clean --force

# Las dependencias van antes del codigo para que un cambio en la app no invalide
# la cache de bundle ni la de yarn.
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile && yarn cache clean

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# SECRET_KEY_BASE de relleno: precompilar no necesita el real, y exigirlo aqui
# obligaria a meter el secreto de produccion en el build.
RUN SECRET_KEY_BASE=solo_para_precompilar_assets ./bin/rails assets:precompile

# Los .map de esbuild son utiles en desarrollo y solo peso en produccion.
RUN rm -f public/assets/*.map app/assets/builds/*.map

# ── Final ───────────────────────────────────────────────────────────────────
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Usuario sin privilegios. Solo estos directorios necesitan escritura.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["./bin/rails", "server"]
