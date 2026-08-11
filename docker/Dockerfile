FROM node:20-alpine

LABEL org.opencontainers.image.title="Batrium WatchMon UDP Listener"
LABEL org.opencontainers.image.description="Standalone Docker image for Batrium WatchMon UDP Listener with web config UI"
LABEL org.opencontainers.image.source="https://github.com/DwayneGodden/homeassistant-batrium-watchmon"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app

COPY upstream/WatchMonUdpListener/ /app/

RUN npm install --omit=dev
RUN npm install express

RUN mkdir -p /app/config
RUN mkdir -p /data

COPY watchmon_udp/config-ui.js /app/config-ui.js
COPY docker/docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod +x /app/docker-entrypoint.sh

EXPOSE 8099/tcp
EXPOSE 18542/udp

CMD ["/app/docker-entrypoint.sh"]
