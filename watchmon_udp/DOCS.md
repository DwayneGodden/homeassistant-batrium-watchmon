# Batrium WatchMon UDP Listener

Repository:

```text
https://github.com/DwayneGodden/homeassistant-batrium-watchmon
```

## About

This app listens for UDP broadcast packets from a Batrium WatchMon BMS and forwards decoded data to MQTT and/or InfluxDB.

## Configuration

Use the built-in **Open Web UI** button to edit the full JSON configuration.

Persistent config:

```text
/data/config.json
```

Runtime config:

```text
/app/config/config.json
```

## Network Requirement

This app requires host networking to receive Batrium UDP broadcast traffic:

```yaml
host_network: true
```

## Troubleshooting

Check host networking:

```bash
docker inspect app_local_watchmon_udp | grep -A5 -B5 NetworkMode
```

Check UDP traffic:

```bash
tcpdump -ni any udp port 18542
```

## Credits

This app packages and extends the original Batrium WatchMon UDP Listener:

```text
https://github.com/Batrium/WatchMonUdpListener
```
