FROM homeassistant/aarch64-base:latest

RUN apk add --no-cache nodejs npm git

WORKDIR /app

COPY upstream/WatchMonUdpListener/ /app/

RUN npm install
RUN npm install express

COPY config-ui.js /app/config-ui.js
COPY run.sh /app/run.sh
RUN chmod a+x /app/run.sh

CMD [ "/app/run.sh" ]
