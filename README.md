# Batrium WatchMon UDP Listener for Home Assistant

A Home Assistant App/Add-on wrapper for the Batrium WatchMon UDP Listener.

This project packages the original Batrium WatchMon UDP Listener as a Home Assistant app with persistent configuration, host-network support for UDP broadcast traffic, MQTT/InfluxDB output, and a built-in web UI for editing the full JSON configuration directly from Home Assistant.

## Features

- Receives Batrium WatchMon UDP broadcast packets
- Runs inside Home Assistant as a custom app/add-on
- Uses host networking for LAN UDP broadcast visibility
- Publishes Batrium data to MQTT
- Supports InfluxDB output
- Persistent `/data/config.json` configuration storage
- Built-in Home Assistant Ingress web interface
- Web-based full JSON config editor
- JSON validation before saving
- Format JSON and reload-from-disk buttons
- ARM64/aarch64 support

## Project Structure

Recommended repository layout:

```text
ha-batrium-watchmon/
├── README.md
├── LICENSE
├── repository.json
└── watchmon_udp/
    ├── config.yaml
    ├── Dockerfile
    ├── run.sh
    ├── config-ui.js
    ├── DOCS.md
    ├── icon.png
    └── logo.png
```

## Installation

### Add as a Home Assistant app/add-on repository

1. Open Home Assistant.
2. Go to **Settings**.
3. Go to **Apps** or **Add-ons**, depending on your Home Assistant version.
4. Open the app/add-on store.
5. Add this repository URL:

```text
https://github.com/YOUR-GITHUB-USERNAME/ha-batrium-watchmon
```

6. Install **Batrium WatchMon UDP Listener**.
7. Start the app.
8. Open the web UI and edit the configuration.

### Local development install

Copy the `watchmon_udp` folder into your Home Assistant local apps/add-ons directory, then reload apps/add-ons:

```bash
ha apps reload
```

Older Home Assistant versions may use:

```bash
ha addons reload
```

Then build and start:

```bash
ha apps rebuild local_watchmon_udp
ha apps start local_watchmon_udp
```

## Configuration

The app stores its persistent configuration at:

```text
/data/config.json
```

At runtime, the app copies this file to the location expected by the original Batrium listener:

```text
/app/config/config.json
```

You can edit the configuration through the built-in web interface using the **Open Web UI** button in Home Assistant.

## Example Config

```json
{
    "config": {
        "mqtthost": "core-mosquitto",
        "mqttusername": "mqttuser",
        "mqttpassword": "your-password-here",
        "influxhost": "172.30.33.2",
        "influxdatabase": "batrium",
        "influxusername": "",
        "influxpassword": "",
        "influxenabled": false,
        "mqttenabled": true,
        "debug": false,
        "debugmqtt": false
    },
    "3e": {
        "mqtt": true,
        "influx": true,
        "tag": "general",
        "serie": "generic"
    },
    "32": {
        "mqtt": true,
        "influx": true,
        "tag": "general",
        "serie": "generic"
    },
    "all": {
        "mqtt": false,
        "influx": false,
        "info": "Do not run every message to influx. you will kill the machine if running raspberry pi!"
    }
}
```

## MQTT Notes

The MQTT host depends on your Home Assistant networking setup.

Common options:

```json
"mqtthost": "core-mosquitto"
```

or the Mosquitto app/add-on container IP:

```json
"mqtthost": "172.30.33.0"
```

Use the value that works in your environment.

## InfluxDB Notes

Do not use `localhost` for InfluxDB unless InfluxDB is running inside the same container.

For the Home Assistant InfluxDB app/add-on, use the InfluxDB container IP or resolvable container name.

Example:

```json
"influxhost": "172.30.33.2"
```

## UDP Broadcast and Host Networking

Batrium WatchMon UDP traffic is typically broadcast traffic. For the listener to receive LAN broadcast packets, the app is configured to use host networking:

```yaml
host_network: true
```

This allows the listener to receive UDP packets sent to the Home Assistant host network interface.

## Web UI

The included web interface runs on internal port `8099` and is exposed through Home Assistant Ingress.

The web UI allows you to:

- Edit the full JSON config
- Validate JSON before saving
- Format JSON
- Reload the config from disk
- Save config to both persistent and runtime paths

## Development

### Rebuild

```bash
ha apps reload
ha apps rebuild local_watchmon_udp
ha apps restart local_watchmon_udp
```

Older Home Assistant versions may use:

```bash
ha addons reload
ha addons rebuild local_watchmon_udp
ha addons restart local_watchmon_udp
```

### Check network mode

```bash
docker inspect app_local_watchmon_udp | grep -A5 -B5 NetworkMode
```

Expected result:

```json
"NetworkMode": "host"
```

### Check logs

```bash
ha apps logs local_watchmon_udp
```

Older Home Assistant versions may use:

```bash
ha addons logs local_watchmon_udp
```

## Credits

This project packages and extends the original Batrium WatchMon UDP Listener.

Original project:

```text
https://github.com/Batrium/WatchMonUdpListener
```

Additional Home Assistant app/add-on packaging, persistent config handling, host-network deployment and Ingress web UI by Dwayne Godden.

## License

This project is released under the MIT License.

The original Batrium WatchMon UDP Listener is also listed as MIT licensed in its package metadata. Preserve the original license notice when redistributing or modifying this project.

