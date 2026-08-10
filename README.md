# Batrium WatchMon UDP Listener for Home Assistant

A Home Assistant App/Add-on wrapper for the Batrium WatchMon UDP Listener.

Repository: https://github.com/DwayneGodden/homeassistant-batrium-watchmon

## Features

- Receives Batrium WatchMon UDP broadcast packets
- Uses host networking for LAN UDP broadcast visibility
- Publishes Batrium data to MQTT
- Supports InfluxDB output
- Persistent `/data/config.json` configuration storage
- Built-in Home Assistant Ingress web interface
- Web-based full JSON config editor
- JSON validation before saving
- Format JSON and reload-from-disk buttons
- ARM64/aarch64 support

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

## Configuration

Persistent config:

```text
/data/config.json
```

Runtime config used by the Batrium listener:

```text
/app/config/config.json
```

## Network Requirement

Batrium WatchMon UDP traffic is typically broadcast traffic. This app should run with host networking enabled:

```yaml
host_network: true
```

Check network mode:

```bash
docker inspect app_local_watchmon_udp | grep -A5 -B5 NetworkMode
```

Expected result:

```json
"NetworkMode": "host"
```

## Credits

This project packages and extends the original Batrium WatchMon UDP Listener:

```text
https://github.com/Batrium/WatchMonUdpListener
```

Additional Home Assistant app/add-on packaging, persistent config handling, host-network deployment and Ingress web UI by Dwayne Godden.

## License

MIT License. See `LICENSE`.
