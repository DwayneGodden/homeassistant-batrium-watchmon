#!/usr/bin/with-contenv bashio

set +e
set -u

APP_DIR="/app"
DATA_DIR="/data"
APP_CONFIG_DIR="${APP_DIR}/config"

DATA_CONFIG_FILE="${DATA_DIR}/config.json"
APP_CONFIG_FILE="${APP_CONFIG_DIR}/config.json"
DIST_CONFIG_FILE="${APP_DIR}/config.json_dist"

CONFIG_UI_FILE="${APP_DIR}/config-ui.js"
CONFIG_UI_PORT="8099"

CONFIG_UI_SUPERVISOR_PID=""

cleanup() {
    bashio::log.info "Shutting down WatchMon UDP app..."

    if [ -n "${CONFIG_UI_SUPERVISOR_PID}" ] && kill -0 "${CONFIG_UI_SUPERVISOR_PID}" 2>/dev/null; then
        kill "${CONFIG_UI_SUPERVISOR_PID}" 2>/dev/null || true
    fi

    pkill -f "node ${CONFIG_UI_FILE}" 2>/dev/null || true
    pkill -f "node index.js" 2>/dev/null || true

    exit 0
}

trap cleanup SIGTERM SIGINT

bashio::log.info "Starting Batrium WatchMon UDP Listener app..."

mkdir -p "${DATA_DIR}"
mkdir -p "${APP_CONFIG_DIR}"

start_config_ui_supervisor() {
    (
        while true; do
            if [ -f "${CONFIG_UI_FILE}" ]; then
                bashio::log.info "Starting WatchMon config web interface on port ${CONFIG_UI_PORT}..."
                node "${CONFIG_UI_FILE}"
                EXIT_CODE="$?"
                bashio::log.error "Config Web UI exited with code ${EXIT_CODE}. Restarting in 5 seconds..."
            else
                bashio::log.error "Config UI file not found at ${CONFIG_UI_FILE}. Retrying in 30 seconds..."
                sleep 30
            fi

            sleep 5
        done
    ) &

    CONFIG_UI_SUPERVISOR_PID="$!"
    bashio::log.info "Config Web UI supervisor started with PID ${CONFIG_UI_SUPERVISOR_PID}"
}

create_default_config_if_missing() {
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
        bashio::log.warning "Open the Web UI, update the config, save it, then the listener will retry automatically."
    fi
}

config_is_valid() {
    node -e "JSON.parse(require('fs').readFileSync('${DATA_CONFIG_FILE}', 'utf8'))" 2>/tmp/watchmon_config_error.log
    return "$?"
}

copy_runtime_config() {
    mkdir -p "${APP_CONFIG_DIR}"
    cp -f "${DATA_CONFIG_FILE}" "${APP_CONFIG_FILE}"
}

start_config_ui_supervisor
create_default_config_if_missing

bashio::log.info "Entering WatchMon listener supervisor loop..."

while true; do
    create_default_config_if_missing

    bashio::log.info "Validating config file..."

    if ! config_is_valid; then
        bashio::log.error "Config file is not valid JSON."
        bashio::log.error "The Batrium listener will not start until the config is fixed."
        bashio::log.error "Open the Web UI, fix the config, and save it."
        bashio::log.error "Validation error:"
        cat /tmp/watchmon_config_error.log || true

        bashio::log.info "Config Web UI remains available. Retrying validation in 30 seconds..."
        sleep 30
        continue
    fi

    bashio::log.info "Config JSON is valid."

    bashio::log.info "Copying persistent config into Batrium runtime config..."
    copy_runtime_config

    if [ ! -f "${APP_CONFIG_FILE}" ]; then
        bashio::log.error "Runtime config was not created at ${APP_CONFIG_FILE}"
        bashio::log.error "Retrying in 30 seconds..."
        sleep 30
        continue
    fi

    bashio::log.info "Starting Batrium WatchMon UDP Listener..."

    cd "${APP_DIR}" || {
        bashio::log.error "Could not change directory to ${APP_DIR}"
        sleep 30
        continue
    }

    node index.js
    WATCHMON_EXIT_CODE="$?"

    bashio::log.error "Batrium WatchMon UDP Listener exited with code ${WATCHMON_EXIT_CODE}"
    bashio::log.error "The app container will stay alive so the Web UI remains available."
    bashio::log.error "Fix the config if needed. Listener will retry in 30 seconds."

    sleep 30
done
