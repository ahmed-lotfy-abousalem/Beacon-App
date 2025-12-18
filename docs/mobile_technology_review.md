# BEACON Mobile Technology & Protocol Notes

## 1. Why Wi‑Fi Direct / Nearby Connections
- **Wi‑Fi Direct (Wi‑Fi P2P)** pairs Android devices without infrastructure, negotiates a group owner that routes traffic, and reaches ~200 m line-of-sight. Discovery relies on `WifiP2pManager.discoverPeers`, followed by socket negotiation over the group owner’s soft AP. Throughput up to 250 Mbps is possible, which suits bulk file or voice transfer. Trade-offs: discovery pauses when the screen is off, location permission is mandatory, and iOS lacks full support.
- **Nearby Connections / Nearby Share** (Google Play Services) abstracts the radio: the API automatically switches between Bluetooth, BLE, and peer-to-peer Wi‑Fi hotspots. Latency is higher than raw Wi‑Fi Direct but it keeps peers online even when Wi‑Fi Direct negotiation fails. Range: ~30 m on BLE, ~100 m on Wi‑Fi. Requires Google Play Services and user consent prompts.
- **Hybrid approach**: BEACON can advertise over Nearby for quick discovery, then upgrade high-throughput links to Wi‑Fi Direct sockets. The `P2PService` class describes this layered approach and currently simulates discovery so the UI/database flow can be tested without hardware dependencies.

## 2. Protocol Envelope
- Messages are UTF‑8 JSON blobs sent over the transport stream or byte payload.
- Recommended envelope:
  ```json
  {
    "type": "status|chat|alert|heartbeat",
    "senderId": "<uuid>",
    "timestamp": "<iso8601>",
    "payload": { "... domain specific ..." }
  }
  ```
- Heartbeats every 20 seconds keep the dashboard updated; missed heartbeats for >2 intervals mark a peer as “standby”.
- Each event is logged into the encrypted SQLite `network_activity` table for auditing.

## 3. Automatic Peer Discovery Flow
1. Start advertising (`NearbyConnections#startAdvertising`) or peer scanning (`WifiP2pManager.discoverPeers`).
2. On discovery, exchange capabilities (supported channels, battery, role) and assign a `peerId` UUID to log in SQLite.
3. Attempt socket upgrade (Wi‑Fi Direct) when RSSI is high; otherwise remain on Nearby’s managed transport.
4. Emit a heartbeat immediately and schedule periodic updates so UI timestamps stay fresh.

## 4. Data Security Notes
- Database uses **SQLCipher** via `sqflite_sqlcipher`. The AES‑256 key is generated once, stored with `flutter_secure_storage`, and never hard-coded.
- `BeaconProvider` watches `AppLifecycleState`; when the app pauses, it calls `DatabaseService.close()`. Closing the SQLCipher database flushes and keeps the file encrypted at rest.
- On resume the database reopens with the secure key and state is repopulated into Provider models.

## 5. Future Enhancements
- Replace the simulated discovery stream with real platform channels for Wi‑Fi Direct / Nearby once hardware testing is available.
- Add optional Bluetooth LE mesh fallbacks for environments without Wi‑Fi support.
- Extend the schema with message delivery receipts and per-peer reliability metrics.

