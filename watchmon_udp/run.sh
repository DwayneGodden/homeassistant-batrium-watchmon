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

CONFIG_UI_FILE="${APP_DIR}/config-ui.js"
CONFIG_UI_PORT="8099"

bashio::log.info "Starting Batrium WatchMon UDP Listener app..."

mkdir -p "${DATA_DIR}"
mkdir -p "${APP_CONFIG_DIR}"

# Always start the config web UI first.
# This allows the user to fix config problems from the Home Assistant interface.
if [ -f "${CONFIG_UI_FILE}" ]; then
    bashio::log.info "Starting WatchMon config web interface on port ${CONFIG_UI_PORT}..."
    node "${CONFIG_UI_FILE}" &
else
    bashio::log.warning "Config UI file not found at ${CONFIG_UI_FILE}"
fi

# Create persistent config if missing.
if [ ! -f "${DATA_CONFIG_FILE}" ]; then
    bashio::log.warning "No config found at ${DATA_CONFIG_FILE}"

    if [ -f "${DIST_CONFIG_FILE}" ]; then
        bashio::log.info "Creating default config from ${DIST_CONFIG_FILE}"
        cp -f "${DIST_CONFIG_FILE}" "${DATA_CONFIG_FILE}"
    else
        bashio::log.warning "Default config not found. Creating empty JSON config."
        echo "{}" > "${DATA_CONFIG_FILE}"
    fi

    bashio::log.warning "A config file has been created at ${DATA_CONFIG_FILE}"
    bashio::log.warning "Open the Web UI, update the config, save it, then restart the app."
fi

# Validate config before starting the main Batrium process.
bashio::log.info "Validating config file..."

if ! node -e "JSON.parse(require('fs').readFileSync('${DATA_CONFIG_FILE}', 'utf8'))" 2>/tmp/watchmon_config_error.log; then
    bashio::log.error "Config file is not valid JSON."
    bashio::log.error "The Batrium listener will not start until the config is fixed."
    bashio::log.error "Open the Web UI, fix the config, save it, then restart the app."
    bashio::log.error "Validation error:"
    cat /tmp/watchmon_config_error.log || true

    # Keep container alive so Home Assistant Ingress Web UI remains available.
    bashio::log.info "Keeping app alive so the config Web UI remains available..."
    exec tail -f /dev/null
fi

bashio::log.info "Config JSON is valid."

# Copy persistent config to the location expected by the Batrium app.
bashio::log.info "Copying persistent config into Batrium runtime config..."
cp -f "${DATA_CONFIG_FILE}" "${APP_CONFIG_FILE}"

# Final sanity check.
if [ ! -f "${APP_CONFIG_FILE}" ]; then
    bashio::log.error "Runtime config was not created at ${APP_CONFIG_FILE}"
    bashio::log.error "The Batrium listener cannot start."
    exec tail -f /dev/null
fi

bashio::log.info "Starting Batrium WatchMon UDP Listener..."

cd "${APP_DIR}"

exec node index.js