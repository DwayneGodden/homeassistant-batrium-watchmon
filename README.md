# Batrium WatchMon UDP Listener for Home Assistant

[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-Compatible-41BDF5?style=flat-square&logo=homeassistant)](https://www.home-assistant.io/)
[![ARM64 Only](https://img.shields.io/badge/ARM64-Only-orange?style=flat-square&logo=arm)](https://developer.arm.com/)
[![Open Source](https://img.shields.io/badge/Open%20Source-Yes-brightgreen?style=flat-square)](https://opensource.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Home Assistant app for receiving Batrium WatchMon UDP broadcasts and publishing data to MQTT and/or InfluxDB, featuring a built-in Home Assistant configuration editor.

Repository: https://github.com/DwayneGodden/homeassistant-batrium-watchmon

```markdown
⚠️ This add-on currently supports ARM64 / AArch64 Home Assistant installations only.
```


## Features

- Receives Batrium WatchMon UDP broadcast packets
- Uses host networking for LAN UDP broadcast visibility
- Publishes Batrium data to MQTT
- Supports InfluxDB output
- Built-in Home Assistant Ingress web interface
- Web-based full JSON config editor
- JSON validation before saving
- Format JSON and reload-from-disk buttons
- Designed for ARM64 / AArch64 systems

## Installation

1. Open Home Assistant.
2. Go to **Settings**.
3. Go to **Apps** or **Add-ons**, depending on your Home Assistant version.
4. Add this repository URL:
```text
https://github.com/DwayneGodden/homeassistant-batrium-watchmon
```
5. Install **Batrium WatchMon UDP Listener**.
6. Start the app.
7. Open the web UI and edit the configuration.

## Requirements

- MQTT service
- InfluxDB service, if you want InfluxDB output

Both can be installed as Home Assistant add-ons and configured using your Home Assistant server LAN IP.

## Configuration

On first launch, open the web UI and update:

- MQTT server IP
- MQTT username and password
- InfluxDB IP
- InfluxDB username and password
- InfluxDB database name

## Network Requirement

Batrium WatchMon UDP traffic is typically broadcast traffic. For this reason, the add-on should run with host networking enabled:

host_network: true


## Credits

This project packages and extends the original Batrium WatchMon UDP Listener:

```text
https://github.com/Batrium/WatchMonUdpListener
```

Additional Home Assistant app/add-on packaging, persistent config handling, host-network deployment and Ingress web UI by Dwayne Godden.

## License

MIT License. See `LICENSE`.
