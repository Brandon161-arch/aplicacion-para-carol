# syntax=docker/dockerfile:1.7

# Imagen oficial de Flutter para construir la app web.
# "stable" es la etiqueta publicada y mantenida por Cirrus Labs.
# Si necesitas fijar una versión, usa una etiqueta que exista en:
#   https://github.com/cirruslabs/docker-images-flutter/pkgs/container/flutter
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable

FROM ${FLUTTER_IMAGE} AS build

# El stage de compilación corre como root para poder escribir /app
# independientemente del usuario por defecto de la imagen de Flutter.
USER root

WORKDIR /app

ENV CI=true
ENV FLUTTER_SUPPRESS_ANALYTICS=true

# Cachea dependencias antes de copiar el código.
COPY pubspec.yaml pubspec.lock ./
RUN flutter config --enable-web \
    && flutter pub get

COPY . .

RUN flutter build web --release --pwa-strategy=none --no-wasm-dry-run

FROM nginx:1.27-alpine AS runtime

RUN rm -f /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=4s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
