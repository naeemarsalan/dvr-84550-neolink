# Swann DVR RTSP Bridge

Exposes a Swann DVR-84550 (DVR8-4X50) as standard RTSP streams using [neolink](https://github.com/QuantumEntangledAndy/neolink).

## Streams

| Channel | URL |
|---------|-----|
| 0 | `rtsp://<host>:8554/ch0` |
| 1 | `rtsp://<host>:8554/ch1` |
| 2 | `rtsp://<host>:8554/ch2` |
| 3 | `rtsp://<host>:8554/ch3` |
| 4 | `rtsp://<host>:8554/ch4` |
| 5 | `rtsp://<host>:8554/ch5` |
| 6 | `rtsp://<host>:8554/ch6` |
| 7 | `rtsp://<host>:8554/ch7` |

## Quick Start

```bash
docker compose up -d
```

View in VLC or ffplay:

```bash
ffplay -rtsp_transport tcp rtsp://localhost:8554/ch0
```

## Configuration

Edit `neolink.toml` with your DVR details:

- `address` - DVR IP and port (default 9000)
- `username` / `password` - DVR credentials
- `uid` - DVR P2P UID (found on device label or app)
- `channel_id` - Camera channel (0-7)
- `stream` - `subStream` (SD) or `mainStream` (HD)

## Run Without Docker

```bash
# Download neolink
curl -sL https://github.com/QuantumEntangledAndy/neolink/releases/download/v0.6.2/neolink_linux_x86_64_bullseye.zip -o neolink.zip
unzip neolink.zip

# Run
./neolink rtsp --config neolink.toml
```

## Protocol

The DVR uses the Baichuan/Reolink modern XML protocol over TCP port 9000 with MD5 challenge-response authentication. See [docs/CAPTURE_ANALYSIS.md](docs/CAPTURE_ANALYSIS.md) for full protocol details.
