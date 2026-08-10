#!/usr/bin/with-contenv bashio


#
# Back command if you need a base config loaded
# docker cp /addon_configs/watchmon_udp/config.json app_local_watchmon-udp:/data/config.json
#
#

set -e

APP_DIR="/app"
DATA_DIR="/data"
APP_CONFIG_DIR="${APP_DIR}/config"

DATA_CONFIG_FILE="${DATA_DIR}/config.json"
APP_CONFIG_FILE="${APP_CONFIG_DIR}/config.json"
DIST_CONFIG_FILE="${APP_DIR}/config.json_dist"

bashio::log.info "Starting Batrium WatchMon UDP Listener add-on..."

mkdir -p "${DATA_DIR}"
mkdir -p "${APP_CONFIG_DIR}"

if [ ! -f "${DATA_CONFIG_FILE}" ]; then
    bashio::log.warning "No config found at ${DATA_CONFIG_FILE}"

    if [ -f "${DIST_CONFIG_FILE}" ]; then
        bashio::log.info "Creating default config from ${DIST_CONFIG_FILE}"
        cp -f "${DIST_CONFIG_FILE}" "${DATA_CONFIG_FILE}"
    else
        bashio::log.warning "Default config not found. Creating empty JSON config."
        echo "{}" > "${DATA_CONFIG_FILE}"
    fi
fi

bashio::log.info "Copying persistent config into Batrium runtime config..."
cp -f "${DATA_CONFIG_FILE}" "${APP_CONFIG_FILE}"

bashio::log.info "Starting WatchMon config web interface on port 8099..."
node "${APP_DIR}/config-ui.js" &

bashio::log.info "Starting Batrium WatchMon UDP Listener..."

cd "${APP_DIR}"

node /app/config-ui.js &
exec node index.js