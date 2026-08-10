#!/usr/bin/with-contenv bashio

set -u

APP_DIR="/app"
DATA_DIR="/data"
APP_CONFIG_DIR="${APP_DIR}/config"

DATA_CONFIG_FILE="${DATA_DIR}/config.json"
APP_CONFIG_FILE="${APP_CONFIG_DIR}/config.json"
DIST_CONFIG_FILE="${APP_DIR}/config.json_dist"

CONFIG_UI_FILE="${APP_DIR}/config-ui.js"
CONFIG_UI_PORT="8099"

CONFIG_UI_PID=""
WATCHMON_PID=""

cleanup() {
    bashio::log.info "Shutting down WatchMon UDP app..."

    if [ -n "${WATCHMON_PID}" ] && kill -0 "${WATCHMON_PID}" 2>/dev/null; then
        bashio::log.info "Stopping Batrium WatchMon UDP Listener..."
        kill "${WATCHMON_PID}" 2>/dev/null || true
    fi

    if [ -n "${CONFIG_UI_PID}" ] && kill -0 "${CONFIG_UI_PID}" 2>/dev/null; then
        bashio::log.info "Stopping config web interface..."
        kill "${CONFIG_UI_PID}" 2>/dev/null || true
    fi

    exit 0
}

trap cleanup SIGTERM SIGINT

bashio::log.info "Starting Batrium WatchMon UDP Listener app..."

mkdir -p "${DATA_DIR}"
mkdir -p "${APP_CONFIG_DIR}"

if [ -f "${CONFIG_UI_FILE}" ]; then
    bashio::log.info "Starting WatchMon config web interface on port ${CONFIG_UI_PORT}..."
    node "${CONFIG_UI_FILE}" &
    CONFIG_UI_PID="$!"
    bashio::log.info "Config Web UI started with PID ${CONFIG_UI_PID}"
else
    bashio::log.warning "Config UI file not found at ${CONFIG_UI_FILE}"
fi

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

bashio::log.info "Validating config file..."

if ! node -e "JSON.parse(require('fs').readFileSync('${DATA_CONFIG_FILE}', 'utf8'))" 2>/tmp/watchmon_config_error.log; then
    bashio::log.error "Config file is not valid JSON."
    bashio::log.error "The Batrium listener will not start until the config is fixed."
    bashio::log.error "Open the Web UI, fix the config, save it, then restart the app."
    bashio::log.error "Validation error:"
    cat /tmp/watchmon_config_error.log || true

    bashio::log.info "Keeping app alive so the config Web UI remains available..."

    while true; do
        if [ -n "${CONFIG_UI_PID}" ] && ! kill -0 "${CONFIG_UI_PID}" 2>/dev/null; then
            bashio::log.error "Config Web UI has stopped. Exiting app."
            exit 1
        fi

        sleep 30
    done
fi

bashio::log.info "Config JSON is valid."

bashio::log.info "Copying persistent config into Batrium runtime config..."
cp -f "${DATA_CONFIG_FILE}" "${APP_CONFIG_FILE}"

if [ ! -f "${APP_CONFIG_FILE}" ]; then
    bashio::log.error "Runtime config was not created at ${APP_CONFIG_FILE}"
    bashio::log.error "The Batrium listener cannot start."
    bashio::log.info "Keeping app alive so the config Web UI remains available..."

    while true; do
        if [ -n "${CONFIG_UI_PID}" ] && ! kill -0 "${CONFIG_UI_PID}" 2>/dev/null; then
            bashio::log.error "Config Web UI has stopped. Exiting app."
            exit 1
        fi

        sleep 30
    done
fi

bashio::log.info "Starting Batrium WatchMon UDP Listener..."

cd "${APP_DIR}" || exit 1

node index.js &
WATCHMON_PID="$!"

bashio::log.info "Batrium WatchMon UDP Listener started with PID ${WATCHMON_PID}"
bashio::log.info "Config Web UI remains available on port ${CONFIG_UI_PORT}"

while true; do
    if [ -n "${CONFIG_UI_PID}" ] && ! kill -0 "${CONFIG_UI_PID}" 2>/dev/null; then
        bashio::log.error "Config Web UI has stopped. Exiting app."
        exit 1
    fi

    if [ -n "${WATCHMON_PID}" ] && ! kill -0 "${WATCHMON_PID}" 2>/dev/null; then
        wait "${WATCHMON_PID}"
        WATCHMON_EXIT_CODE="$?"

        bashio::log.error "Batrium WatchMon UDP Listener exited with code ${WATCHMON_EXIT_CODE}"
        bashio::log.error "The app will stay running so the Web UI remains available."
        bashio::log.error "Fix the config in the Web UI, then restart the app."

        WATCHMON_PID=""
    fi

    sleep 30
done