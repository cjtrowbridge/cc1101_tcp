# cc1101_tcp Firmware Roadmap

This document serves as the **Authoritative Execution Plan** for the firmware. All development must proceed by checking off tasks in this list.

## 1. Core System & Connectivity
- [x] **WiFi Connection**: Connect to SSID defined in `secrets.h`.
- [x] **OTA Support**: Enable `ArduinoOTA` for fleet updates.
- [x] **Driver Init**: Initialize `ELECHOUSE_CC1101_SRC_DRV` with correct SPI pinout.
    - [x] CSN: 10, SCK: 12, MOSI: 11, MISO: 13
- [ ] **Status LED**: Implement implicit status indication via on-board LED (Blink codes for connecting/ready).

## 2. TCP Protocol Layer (Port 1234)
- [ ] **TCP Server Init**: Listen on Port 1234.
- [ ] **Client Connection Handling**:
    - [ ] Accept incoming client.
    - [ ] Stop radio/scanning when client connects (clean state).
    - [ ] Detect disconnects and reset state.
- [ ] **Command Parsing**:
    - [ ] Read 5-byte header (`[CmdID:1][Param:4]`).
    - [ ] Handle Big-Endian conversion for Parameter.
    - [ ] Switch-Case dispatcher for commands.

## 3. rtl_tcp Command Implementation
*Reference `api/README.md` for Protocol Spec*
- [ ] **0x01 SET_FREQ**:
    - [ ] Validate frequency (MHz).
    - [ ] Call `cc1101.setSpiInTx(0)`? No, RX mode.
    - [ ] Call `cc1101.setMHZ(freq)`.
- [ ] **0x02 SET_SAMPLE_RATE**:
    - [ ] Stub (ack only). CC1101 sample rate is fixed/complex.
- [ ] **0x04 SET_GAIN**:
    - [ ] Map "tenths of dB" or auto/manual to CC1101 gain registers.
- [ ] **0x90 GET_STATUS (Custom)**:
    - [ ] Return JSON blob with uptime, RSSI, current frequency.

## 4. Streaming Logic
- [ ] **Task Separation**: Run TCP loop on Core 1, Radio loop on Core 0? (Or minimal blocking).
- [ ] **RSSI Polling**: Read RSSI from CC1101.
- [ ] **Waterfall Encoding** (The core challenge):
    - [ ] **Mode A (Fast)**: Fake I/Q. Send constant I/Q pairs that don't represent signal, but use a side-channel for RSSI?
    - [ ] **Mode B (Sweep)**: Perform frequency sweep, collect RSSI array, packetize.
- [ ] **Stream Output**: Write buffer to TCP client.

## 5. Optimization & Reliability
- [ ] **Watchdog**: Enable WDT to handle radio lockups.
- [ ] **Buffer Management**: Ensure TCP backpressure doesn't crash the MCU.
