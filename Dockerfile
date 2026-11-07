# syntax=docker/dockerfile:1.7

# Imagen oficial de Flutter para construir la app web.
# Puedes fijar una versión exacta con:
#   docker build --build-arg FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:3.47.6 .
ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:3.47.6

FROM ${FLUTTER_IMAGE} AS build

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
