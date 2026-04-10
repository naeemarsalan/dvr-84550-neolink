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
ARG TARGETARCH=amd64

RUN ARCH=$(case "${TARGETARCH}" in \
      amd64) echo "x86_64_bullseye" ;; \
      arm64) echo "arm64" ;; \
      arm)   echo "armhf" ;; \
    esac) && \
    curl -sL "https://github.com/QuantumEntangledAndy/neolink/releases/download/${NEOLINK_VERSION}/neolink_linux_${ARCH}.zip" \
      -o /tmp/neolink.zip && \
    unzip /tmp/neolink.zip -d /tmp/neolink && \
    find /tmp/neolink -name neolink -type f -exec cp {} /usr/local/bin/neolink \; && \
    chmod +x /usr/local/bin/neolink && \
    rm -rf /tmp/neolink /tmp/neolink.zip

COPY neolink.toml /etc/neolink/neolink.toml.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8554

ENTRYPOINT ["/entrypoint.sh"]
