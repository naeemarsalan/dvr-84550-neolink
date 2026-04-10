FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libgstreamer1.0-0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-rtsp \
    libgstrtspserver-1.0-0 \
    gettext-base \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ARG NEOLINK_VERSION=v0.6.2

RUN set -eux; \
    DPKG_ARCH="$(dpkg --print-architecture)"; \
    case "${DPKG_ARCH}" in \
      amd64)  NEOLINK_ARCH="x86_64_bullseye" ;; \
      arm64)  NEOLINK_ARCH="arm64" ;; \
      armhf)  NEOLINK_ARCH="armhf" ;; \
      i386)   NEOLINK_ARCH="i386" ;; \
      *)      echo "Unsupported arch: ${DPKG_ARCH}"; exit 1 ;; \
    esac; \
    curl -sL "https://github.com/QuantumEntangledAndy/neolink/releases/download/${NEOLINK_VERSION}/neolink_linux_${NEOLINK_ARCH}.zip" \
      -o /tmp/neolink.zip; \
    unzip /tmp/neolink.zip -d /tmp/neolink; \
    find /tmp/neolink -name neolink -type f -exec cp {} /usr/local/bin/neolink \;; \
    chmod +x /usr/local/bin/neolink; \
    rm -rf /tmp/neolink /tmp/neolink.zip; \
    neolink --version

COPY neolink.toml /etc/neolink/neolink.toml.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8554

ENTRYPOINT ["/entrypoint.sh"]
