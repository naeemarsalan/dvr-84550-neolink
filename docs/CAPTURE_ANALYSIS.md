# DVR Capture Analysis Results

## Protocol Discovery

This is **NOT** the simple Baichuan binary protocol that `/tmp/sdvr/` implements.
This is the **Reolink/Baichuan Modern XML Protocol** (class 0x6514/0x6414).

## Header Format (20 bytes, revised)

```
Offset  Size  Field
0       4     Magic: 0x0ABCDEF0
4       4     Packet ID (message type)
8       4     Payload size
12      4     Message ID / sequence (upper 16 bits = session, lower 16 bits = sequence)
16      2     Status code (in responses) / 0x0000 (in requests)
18      2     Class: 0x6514 (legacy login), 0x6414 (XML messages), 0x6614 (legacy responses)
```

## Authentication Flow (Two-Phase MD5 Challenge-Response)

### Phase 1: Legacy Login (Packet 0x01, class 0x6514)
Client sends 1856-byte packet with MD5-hashed credentials:
- Offset 0-19: Header (id=0x01, payload=1836, class=0x6514)
- Offset 20: MD5(username) — 31 chars + null (e.g., `21232F297A57A5A743894A0E4A801FC` = md5("admin"))
- Offset 52: MD5(password) — 31 chars + null (e.g., `2A8EB911867347426494EBDD6C9D6F5`)
- Rest: zeros + timestamp at tail

### Phase 1 Response: Nonce (Packet 0x01, class 0x6614)
Server responds with XML containing MD5 nonce:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<body>
<Encryption version="1.1">
<type>md5</type>
<nonce>8CFD0638A544638A</nonce>
</Encryption>
</body>
```

### Phase 2: XML Login (Packet 0x01, class 0x6414)
Client sends 343-byte packet with nonce-hashed credentials:
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<body>
<LoginUser version="1.1">
<userName>01E7572F87C7E3738C95F7DB0E6013F</userName>
<password>07276992905E4CD2CC80ED5705B2F08</password>
</LoginUser>
<LoginNet version="1.1">
<type>LAN</type>
<udpPort>0</udpPort>
</LoginNet>
</body>
```
Note: userName/password here are MD5(original_md5 + nonce)

### Phase 2 Response: Device Info (Packet 0x01, status=200)
Server responds with large XML containing firmware info, IO ports, etc.
Status 401 = authentication failed.

## MD5 Auth Algorithm
```
1. md5_user = MD5(username)   # e.g., MD5("admin") = "21232f297a57a5a743894a0e4a801fc3"
2. md5_pass = MD5(password)   # truncated to 31 chars in legacy packet
3. Server sends nonce (16 hex chars)
4. final_user = MD5(md5_user + nonce)   # truncated to 31 chars
5. final_pass = MD5(md5_pass + nonce)   # truncated to 31 chars
6. Send in XML LoginUser
```

## Post-Login Command Packets

All use class 0x6414 with XML payloads:

### Packet 0x97 - Permission/Token Request
```xml
<Extension version="1.1">
<userName>admin</userName>
<token>system, network, PTZ, IO, audio, security, disk</token>
</Extension>
```
Multiple 0x97 packets sent for different token groups:
- `system, network, PTZ, IO, audio, security, disk`
- `streaming, record, image`
- `video, alarm, replay`

### Packet 0x2C - Channel Info Request
```xml
<Extension version="1.1">
<channelId>0</channelId>
</Extension>
```

### Packet 0x1A - Channel Config Request
```xml
<Extension version="1.1">
<channelId>0</channelId>
</Extension>
```

### Packet 0xBE - Channel Settings Request
```xml
<Extension version="1.1">
<channelId>0</channelId>
</Extension>
```

### Packet 0x03 - Start Video Preview
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<body>
<Preview version="1.1">
<channelId>0</channelId>
<handle>66255</handle>
<streamType>subStream</streamType>
<preRec>0</preRec>
</Preview>
</body>
```
- `channelId`: Camera channel (0-7)
- `handle`: Session handle (random/incremented)
- `streamType`: `subStream` (low res) or `mainStream` (high res)
- `preRec`: Pre-recording (0=disabled)

### Packet 0xC0 - Unknown (0 payload, possibly keepalive)

### Packet 0x5D - Heartbeat/Keepalive
- Sent frequently, 0 payload, timestamp field = 0x00010200

## Video Stream Response
Server responds to 0x03 with binary video data (H.264/H.265 frames).
The S→C buffer in the successful session was 289,529 bytes — raw video data.

## Connection Summary (Stream 8 - Successful)
```
C→S: 0x01 (legacy login with MD5 creds)
S→C: 0x01 (nonce challenge)
C→S: 0x01 (XML login with nonce-hashed creds)
S→C: 0x01 (status=200, device info XML)
C→S: 0x97 (permission request: system,network,PTZ...)
C→S: 0x97 (permission request: streaming,record,image)
C→S: 0x97 (permission request: video,alarm,replay)
C→S: 0x5D (heartbeat)
C→S: 0x2C (channel 0 info)
C→S: 0xC0 (unknown)
C→S: 0x5D (heartbeat x6)
C→S: 0x1A (channel 0 config)
C→S: 0xBE (channel 0 settings)
C→S: 0x03 (START PREVIEW: channel 0, subStream)
C→S: 0x1A (channel 0 config)
C→S: 0xBE (channel 0 settings)
C→S: 0xBE (channel 0 settings)
... more commands
S→C: [289KB video data]
```

## Failed Connection (Stream 7)
Same flow but got status 401 on phase 2 — likely wrong nonce computation.
The plugin retried on stream 8 with a different nonce and succeeded.

## Key Differences from /tmp/sdvr/ Implementation
| Feature | sdvr (old) | Actual Protocol |
|---------|-----------|-----------------|
| Class field | 0x6614 | 0x6514 (login), 0x6414 (commands) |
| Auth | Plaintext user/pass | Two-phase MD5 challenge-response |
| Commands | Binary fields | XML payloads |
| Video start | Binary packet 0x03 | XML Preview with channelId, handle, streamType |
| Payload format | Fixed offsets | XML strings |

## Existing Open Source Implementation
This protocol is implemented by the `neolink` project (Rust-based Reolink camera client):
https://github.com/thirtythreeforty/neolink
