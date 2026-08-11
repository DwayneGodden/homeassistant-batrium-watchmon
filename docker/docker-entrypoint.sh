#!/bin/sh

set +e
set -u

APP_DIR="/app"
DATA_DIR="/data"
APP_CONFIG_DIR="${APP_DIR}/config"

DATA_CONFIG_FILE="${DATA_DIR}/config.json"
APP_CONFIG_FILE="${APP_CONFIG_DIR}/config.json"
DIST_CONFIG_FILE="${APP_DIR}/config.json_dist"

CONFIG_UI_FILE="${APP_DIR}/config-ui.js"

echo "Starting Batrium WatchMon UDP Listener standalone Docker container..."

mkdir -p "${DATA_DIR}"
mkdir -p "${APP_CONFIG_DIR}"

start_config_ui() {
    while true; do
        echo "Starting WatchMon config web interface on port 8099..."
        node "${CONFIG_UI_FILE}"
        EXIT_CODE="$?"
        echo "Config Web UI exited with code ${EXIT_CODE}. Restarting in 5 seconds..."
        sleep 5
    done
}

create_default_config_if_missing() {
    if [ ! -f "${DATA_CONFIG_FILE}" ]; then
        echo "No config found at ${DATA_CONFIG_FILE}"

        if [ -f "${DIST_CONFIG_FILE}" ]; then
            echo "Creating default config from ${DIST_CONFIG_FILE}"
            cp -f "${DIST_CONFIG_FILE}" "${DATA_CONFIG_FILE}"
        else
            echo "Default config not found. Creating empty JSON config."
            echo "{}" > "${DATA_CONFIG_FILE}"
        fi

        echo "Open the Web UI, update the config, save it, then the listener will retry automatically."
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

start_config_ui &

echo "Entering WatchMon listener supervisor loop..."

while true; do
    create_default_config_if_missing

    echo "Validating config file..."

    if ! config_is_valid; then
        echo "Config file is not valid JSON."
        cat /tmp/watchmon_config_error.log || true
        echo "Web UI remains available. Retrying validation in 30 seconds..."
        sleep 30
        continue
    fi

    echo "Config JSON is valid."

    echo "Copying persistent config into Batrium runtime config..."
    copy_runtime_config

    echo "Starting Batrium WatchMon UDP Listener..."

    cd "${APP_DIR}" || {
        echo "Could not change directory to ${APP_DIR}"
        sleep 30
        continue
    }

    node index.js
    WATCHMON_EXIT_CODE="$?"

    echo "Batrium WatchMon UDP Listener exited with code ${WATCHMON_EXIT_CODE}"
    echo "Container will stay alive so the Web UI remains available."
    echo "Fix config if needed. Listener will retry in 30 seconds."

    sleep 30
done
