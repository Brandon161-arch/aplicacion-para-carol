# Build de Flutter web usando el SDK oficial desde Google Storage.
# Evita la imagen de GHCR (~2 GB) que fallaba por cortes de red.
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.47.6
ARG FLUTTER_SHA256=f1631b9c2c8b3529323db412b0d1beacf4a748f8783b0d7cf599a8fd5f461675

ENV DEBIAN_FRONTEND=noninteractive
ENV CI=true
ENV FLUTTER_SUPPRESS_ANALYTICS=true
ENV PATH="/opt/flutter/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        unzip \
        wget \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# wget -c reanuda la descarga si la conexión se corta.
RUN set -eux; \
    wget -c \
        --tries=20 \
        --waitretry=5 \
        --timeout=30 \
        -O /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"; \
    echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c -; \
    tar -xJf /tmp/flutter.tar.xz -C /opt; \
    rm /tmp/flutter.tar.xz; \
    git config --global --add safe.directory /opt/flutter; \
    flutter config --no-analytics; \
    flutter config --enable-web; \
    flutter --version

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

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
