FROM node:alpine3.22

WORKDIR /app

COPY index.js index.html package.json ./

EXPOSE 3000/tcp

# 构建时把官方 xray + cloudflared 二进制打进镜像，
# 容器启动时直接使用，不再每次从外部下载（避免启动时下载失败导致节点起不来）。
ARG TARGETARCH
RUN apk update && apk upgrade &&\
    apk add --no-cache openssl curl gcompat iproute2 coreutils unzip bash &&\
    chmod +x index.js &&\
    npm install &&\
    mkdir -p /app/bin &&\
    case "${TARGETARCH}" in \
      arm64) XRAY_ZIP="Xray-linux-arm64-v8a.zip"; CLOUDFLARED_BIN="cloudflared-linux-arm64";; \
      *)     XRAY_ZIP="Xray-linux-64.zip";       CLOUDFLARED_BIN="cloudflared-linux-amd64";; \
    esac &&\
    curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/${XRAY_ZIP}" &&\
    unzip -o /tmp/xray.zip xray -d /app/bin &&\
    curl -fsSL -o /app/bin/bot "https://github.com/cloudflare/cloudflared/releases/latest/download/${CLOUDFLARED_BIN}" &&\
    mv /app/bin/xray /app/bin/web &&\
    chmod +x /app/bin/web /app/bin/bot &&\
    /app/bin/web version && /app/bin/bot --version &&\
    rm -f /tmp/xray.zip

ENV BAKED_BIN_DIR=/app/bin

CMD ["node", "index.js"]
