# cc1101_tcp

##  A CC1101 `rtl_tcp`-Compatible RSSI Streaming for Ultra‑Low‑Cost VLBI‑Inspired Arrays — Design Document (v0.1)

> This document specifies a practical, low-cost, distributed **RF sensing** architecture that can plug into existing SDR ecosystems by borrowing the *shape* of the mainstream `rtl_tcp` API. It is designed primarily for **real-time RSSI waterfall streaming** from CC1101 nodes.

---

## 0. Executive summary

### 0.1 Goals

**Primary goal**

* Implement a CC1101-backed network service that can **stream RSSI waterfall data in real time** into **existing SDR pipelines and software**, with minimal friction.

**Secondary goal**

* Provide a clean, extensible protocol and implementation architecture for future research to add more advanced CC1101 capabilities (adaptive scanning, triggers/events, calibration, multi-node orchestration, packet stats, etc.).

### 0.2 VLBI reality check (what we borrow, what we relax)

**Terminology:** In interferometry, array participants are typically called **elements** (and in some VLBI literature, **stations**). In this document:

* **Element** = an array participant that produces measurements.
* **Node** = the networked device implementing this protocol (often one element, sometimes multiple elements).

VLBI does **not** require a shared real-time phase reference (no common LO distributed across continents). Each element can observe independently, and correlation/fringe-fitting can estimate relative clock terms during analysis; rough a priori alignment mostly reduces search space.

**About time-tagging (and why we make it optional here):** Classical VLBI correlation workflows rely on aligning voltage recordings along a time axis, but for **RSSI-waterfall sensing** and **pattern/event fusion**, explicit time tags are not always necessary. In many practical sensing workflows, streams can be aligned by:

* **Feature-based alignment:** distinctive spectral/temporal events make it obvious how streams fit together.
* **Reference-based alignment:** a known periodic transmitter (e.g., a Meshtastic node or dedicated beacon) provides alignment features visible to all elements.
* **Coarse wall-clock alignment:** NTP/chrony reduces ambiguity when available, but is not required to derive value.

**Implication for CC1101 RSSI streaming:**

* A CC1101 RSSI sweep stream is optimized for occupancy/power sensing, event coincidence, cueing, and spatial inference.
* Some experiments (including TDOA-style work) are still possible when elements can establish time/position relative to a known reference (see §12.4).

This document is designed to ensure API consumers cannot accidentally treat RSSI streams as true wideband I/Q.

### 0.3 Success criteria

A build is “successful” when it can do all of the following:

1. **Stream real-time waterfall**

* From one CC1101 node: show a stable waterfall (or equivalent) in a consumer app.

2. **Be honest about semantics**

* Consumers can know (without guessing) whether data is **simultaneous** (FFT snapshot) or **sequential** (sweep).

3. **Scale to arrays**

* Multiple nodes can stream into a fusion process that merges rows and/or event streams with clear timestamp quality.

4. **Enable hybrid workflows**

* CC1101 nodes publish events to cue a smaller number of coherent I/Q nodes.

---

## 1. Background: mainstream `rtl_tcp`

### 1.1 What `rtl_tcp` is

`rtl_tcp` (from the rtl-sdr ecosystem) is a lightweight TCP server that:

* controls a locally-attached RTL-SDR dongle,
* streams continuous **raw 8-bit interleaved I/Q** samples over TCP,
* accepts a minimal binary control protocol.

### 1.2 Why compatibility matters

Many SDR tools can already:

* connect to an `rtl_tcp` endpoint,
* render FFT/waterfalls,
* feed into GNU Radio graphs,
* record streams.

If CC1101 nodes can present compatible interfaces (or a simple proxy can), we inherit large parts of the SDR ecosystem.

---

## 2. Mainstream `rtl_tcp` protocol (compatibility reference)

> This section defines the subset of `rtl_tcp` behaviors we target as a compatibility baseline.

### 2.1 Transport

* TCP stream server.
* Common default port: **1234**.
* No auth/encryption.

### 2.2 Byte order

* Control messages use **network byte order** (big-endian) for the 32-bit argument.

### 2.3 Control message format

* Client sends fixed-size **5-byte** commands:

  * `cmd` (uint8)
  * `arg` (uint32, big-endian)

### 2.4 Common command IDs (mainstream)

| ID   | Name                | Typical meaning                 |
| ---- | ------------------- | ------------------------------- |
| 0x01 | SET_FREQ            | Center frequency (Hz)           |
| 0x02 | SET_SR              | I/Q sample rate (samples/sec)   |
| 0x03 | SET_GAIN_MODE       | 0=auto, 1=manual                |
| 0x04 | SET_GAIN            | Gain value (often tenths of dB) |
| 0x05 | SET_PPM             | Frequency correction (PPM)      |
| 0x06 | SET_IF_GAIN         | IF gain stage/value             |
| 0x07 | SET_TESTMODE        | 0/1                             |
| 0x08 | SET_AGC_MODE        | 0/1                             |
| 0x09 | SET_DIRECT_SAMPLING | 0/1/2                           |
| 0x0A | SET_OFFSET_TUNING   | 0/1                             |
| 0x0B | SET_RTL_XTAL        | RTL crystal Hz                  |
| 0x0C | SET_TUNER_XTAL      | tuner crystal Hz                |
| 0x0D | SET_GAIN_BY_INDEX   | gain table index                |
| 0x0E | SET_BIAS_TEE        | 0/1                             |

### 2.5 Stream expectations

* Classic `rtl_tcp` streams continuous bytes that are interpreted as interleaved I/Q (`I0,Q0,I1,Q1,...`).
* Many clients expect an initial “device info” header (varies by implementation). For maximum compatibility we provide a safe header strategy (see §6).

---

## 3. Hardware comparison: RTL-SDR vs CC1101 (why semantics differ)

### 3.1 RTL-SDR class device (RTL2832U + tuner)

* Provides **wideband complex baseband** (I/Q) to host.
* A waterfall row is typically computed as an FFT snapshot over ~MHz of instantaneous bandwidth.
* “Row time” is effectively the FFT window length, and the row is **simultaneous across bins** (to first order).

### 3.2 CC1101 class device

* Narrowband sub-GHz transceiver with internal modem.
* Does **not** expose wideband I/Q.
* Can provide:

  * synthesizer tuning,
  * channel filter bandwidth selection,
  * RSSI power estimate,
  * packet/FIFO modes,
  * AGC/AFC behaviors.

### 3.3 Key difference: simultaneity

* RTL-SDR waterfall row: simultaneous snapshot across bins.
* CC1101 waterfall row: **sequential sweep** over bins with non-zero sweep duration.

This must be conveyed in the API: every row MUST include either (A) wall-clock timestamps (`TS_START_NS`,`TS_END_NS`) **or** (B) a sequence-based timing model (`ROW_SEQ`,`ROW_TIME_US_EST`), plus `SIMULTANEITY=SEQUENTIAL_SWEEP`.

---

## 4. System architecture overview

### 4.1 Two compatibility modes

We implement two modes to balance “works everywhere” and “honest semantics.”

**Mode A — IQ Emulation Stream (drop‑in waterfall compatibility)**

* Stream *synthetic* I/Q whose FFT reproduces the RSSI waterfall.
* Lets legacy FFT/waterfall apps work immediately.
* Must be explicitly tagged as **emulated**.

**Mode B — Framed WATERFALL_RSSI Stream (truthful + extensible)**

* Stream framed waterfall rows with metadata.
* Best for research, fusion, eventing, and correctness.
* Requires a consumer (GNU Radio block, custom UI, or a proxy).

### 4.2 Recommended deployment patterns

**Pattern 1 (fastest path to reuse legacy apps)**

```
CC1101 Node (Mode A IQ emulation)  --->  legacy SDR app (waterfall)
```

**Pattern 2 (best practice: truthful protocol + optional proxy)**

```
CC1101 Node (Mode B frames)  --->  Proxy/Adapter  ---> legacy SDR app (IQ emulation)
                                     |
                                     +---> native consumers (GNU Radio / dashboards)
```

---

## 5. Capability signaling (non‑negotiable)

### 5.1 Why capability signaling must be first-class

Many `rtl_tcp` clients silently assume:

* commands succeed,
* stream is real I/Q,
* rows represent simultaneous observations.

For CC1101 arrays, those assumptions can produce invalid conclusions. Therefore:

* We define **CAPS** advertisement.
* We define **ACK** responses for extended commands.
* We embed **self-describing frame metadata**.

### 5.2 Feature tiers (array reasoning)

Nodes advertise a tier. These are *contracts* with measurable expectations.

* **Tier 0 — Presence / occupancy sensing (RSSI)**

  * RSSI sweeps with at least a **row sequence counter**; timestamps optional.
  * Best for: visualization, occupancy maps, lightweight eventing, feature-based alignment.

* **Tier 1 — Calibrated power sensing (RSSI + calibration)**

  * Stable sweep grid; per-node calibration applied; repeatable gain/AGC behavior.
  * Supports one or more alignment models:

    * **WALL_CLOCK**: timestamps + stated time quality (NTP/chrony/PPS/GPSDO), or
    * **SEQUENCE**: stable cadence + sequence timing, or
    * **REFERENCE_BEACON**: documented beacon alignment mode.
  * Best for: multi-element fusion, comparisons over time, more reliable triggers.

* **Tier 2 — Voltage time series available (I/Q or equivalent)**

  * Provides a voltage time series suitable for time-domain correlation within its bandwidth.
  * Alignment may be explicit (timestamps) or implicit (recoverable via correlation), but the data product is a voltage stream.

* **Tier 3 — Classical VLBI-capable (correlatable for imaging/geodesy)**

  * Records time-indexed voltage data and has sufficient frequency/phase stability for the intended integration time and observing frequency.
  * Time alignment can be solved in correlation, but practical systems still benefit from good a priori constraints.

CC1101 nodes are expected to be Tier 0–1.

---

## 6. Protocol specification (v0.3)

This project defines a protocol family called **RSP** (RF Sensing Protocol):

* **RSP‑A**: `rtl_tcp`-shape IQ emulation stream.
* **RSP‑B**: framed waterfall + events + telemetry.

### 6.1 Common concepts

* **Node**: a device that can stream sensing data.
* **Stream type**: IQ8_EMULATED, WATERFALL_RSSI, EVENTS, TELEMETRY.
* **Grid**: the set of frequencies a row covers.
* **Row**: one sweep (CC1101) or one snapshot (FFT).

### 6.2 RSP‑B framing

#### 6.2.1 Frame header (binary)

All multi-byte fields are big-endian.

| Field       | Size        | Notes            |
| ----------- | ----------- | ---------------- |
| magic       | 4           | ASCII `RSP0`     |
| version     | 1           | currently `0x01` |
| frame_type  | 1           | enum             |
| flags       | 2           | bitflags         |
| header_len  | 2           | bytes            |
| payload_len | 4           | bytes            |
| header      | header_len  | TLV section      |
| payload     | payload_len | data             |

#### 6.2.2 TLV encoding (header section)

* TLV: `type:uint16, len:uint16, value:len bytes`
* Unknown TLVs MUST be ignored (forward compatibility).

#### 6.2.3 Frame types

| frame_type | Meaning                |
| ---------- | ---------------------- |
| 0x01       | CAPS                   |
| 0x02       | ACK                    |
| 0x10       | WATERFALL_RSSI         |
| 0x11       | WATERFALL_FFT (future) |
| 0x20       | EVENTS                 |
| 0x30       | TELEMETRY              |

### 6.3 CAPS message (required)

CAPS MUST be the first frame sent after connection establishment in RSP‑B.

#### 6.3.1 Required CAPS fields (TLVs)

* `NODE_ID` (string)
* `DEVICE_CLASS` (enum: IQ_WIDEBAND, RSSI_SCANNER, HYBRID)
* `TIER` (uint8)
* `STREAM_TYPES` (bitset)
* `SUPPORTED_COMMANDS` (bitset or list)
* `FREQ_RANGES` (list of [start_hz:uint32, end_hz:uint32])
* `TIME_SOURCE` (enum: NONE, NTP, PPS, GPSDO)
* `TIME_MODEL` (enum: WALL_CLOCK, SEQUENCE, REFERENCE_BEACON)
* `EST_TIME_ERROR_US` (uint32) — if `TIME_MODEL!=WALL_CLOCK`, set to `0xFFFFFFFF` and rely on sequence/reference metadata

#### 6.3.2 Recommended CAPS fields

* `RSSI_UNIT` (enum: INT8_REL, INT16_TENTH_DB, FLOAT_DBM)
* `RSSI_CALIBRATED` (bool)
* `CAL_VERSION` (string)
* `SWEEP_LIMITS` (struct)

  * `MAX_BINS` (uint16)
  * `MIN_STEP_HZ` (uint32)
  * `MIN_DWELL_US` (uint32)
  * `MAX_ROWS_PER_SEC` (uint16)
* `COMMAND_SEMANTICS` (string or structured TLVs)

  * Used to disclose emulation mappings (e.g., SET_SR => ROW_RATE).

#### 6.3.3 Example CAPS (human-readable)

* device_class: RSSI_SCANNER
* tier: 0
* stream_types: WATERFALL_RSSI, EVENTS, TELEMETRY
* supported_commands: SET_FREQ, SET_SR (emulated), SET_GAIN_MODE (profile), SET_GAIN (preset)
* time_source: NTP
* est_time_error_us: 20000
* sweep_limits: max_bins=520, min_step_hz=25000, min_dwell_us=150

### 6.4 ACK frame (recommended, required for extended commands)

ACK is emitted in response to a command (classic or extended) when the client participates in RSP‑B control.

Fields:

* `REQ_ID` (uint32)
* `CMD_ID` (uint16)
* `STATUS` (enum)
* `APPLIED_ARGS` (TLVs)
* `NOTE_CODE` (uint16)

Status enum:

* OK
* UNSUPPORTED
* OUT_OF_RANGE
* BUSY
* DEGRADED
* EMULATED

### 6.5 WATERFALL_RSSI frame (required for Mode B)

#### 6.5.1 Required metadata

To support both timestamped and non-timestamped fusion, each row supports **two equivalent alignment models**. The node MUST provide one of them.

**A) Wall-clock model (timestamps present)**

* `TS_START_NS` (uint64)
* `TS_END_NS` (uint64)

**B) Sequence model (timestamps absent or unreliable)**

* `ROW_SEQ` (uint64) — monotonically increasing per-connection
* `ROW_TIME_US_EST` (uint32) — best estimate of row duration

**Always required (both models)**

* `SIMULTANEITY` (enum: SEQUENTIAL_SWEEP, SIMULTANEOUS)
* `FREQ_START_HZ` (uint32)
* `STEP_HZ` (uint32)
* `BINS` (uint16)
* `DWELL_US` (uint32)
* `SETTLE_US` (uint32)
* `RSSI_UNIT` (enum)

#### 6.5.2 Payload

* Array length = `BINS`.
* Type determined by `RSSI_UNIT`.

**Alignment note:**

* If `TIME_MODEL=SEQUENCE` (CAPS) or `TIME_SOURCE=NONE`, the node MUST provide `ROW_SEQ` + `ROW_TIME_US_EST`.
* If timestamps are provided, nodes SHOULD still include `ROW_SEQ` to simplify ordering and loss detection.

### 6.6 EVENTS frame (recommended)

Events are first-class to support “cheap nodes cue expensive nodes.”

Event fields (per event):

* `freq_hz` (uint32)
* `rssi` (same unit as stream or explicitly typed)
* **Time/alignment (choose one, matching TIME_MODEL):**

  * `event_time_ns` (uint64) — for WALL_CLOCK, **or**
  * `event_row_seq` (uint64) + `event_row_offset_us` (uint32) — for SEQUENCE/REFERENCE_BEACON
* `bandwidth_est_hz` (uint32, optional)
* `persistence_rows` (uint16)
* `confidence` (uint8 0–100)
* `node_id` (string or index)

### 6.7 TELEMETRY frame (recommended)

Telemetry helps operators understand quality:

* `rows_sent`, `rows_dropped`, `socket_overruns`
* `sweep_overruns`, `avg_row_time_us`, `row_jitter_us`
* `time_sync_state`, `est_time_error_us`
* `rssi_histogram` (optional)

---

## 7. Classic `rtl_tcp` command mapping on CC1101

This section defines deterministic semantics so existing clients behave predictably.

### 7.1 Mapping table

| `rtl_tcp` cmd        | RTL-SDR meaning  | CC1101 semantics (this project)                            | Support           |
| -------------------- | ---------------- | ---------------------------------------------------------- | ----------------- |
| 0x01 SET_FREQ        | center frequency | Sets **sweep center** (or single tune if sweep span=0)     | Native            |
| 0x02 SET_SR          | I/Q sample rate  | **Emulated:** sets **ROW_RATE target** (best-effort)       | EMULATED          |
| 0x03 SET_GAIN_MODE   | auto/manual      | Select AGC profile: 0=auto profile, 1=manual preset        | EMULATED          |
| 0x04 SET_GAIN        | gain value       | Select preset index derived from value; disclosure in CAPS | EMULATED          |
| 0x05 SET_PPM         | ppm correction   | Maps to AFC enable + optional offset (if supported)        | EMULATED/Optional |
| 0x06 SET_IF_GAIN     | IF gain          | Not applicable                                             | UNSUPPORTED       |
| 0x07 SET_TESTMODE    | test             | Optional diagnostics (fixed pattern rows)                  | OPTIONAL          |
| 0x08 SET_AGC_MODE    | AGC              | Toggle AGC profile family                                  | EMULATED          |
| 0x09 DIRECT_SAMPLING | bypass tuner     | Not applicable                                             | UNSUPPORTED       |
| 0x0A OFFSET_TUNING   | DC avoidance     | Not applicable                                             | UNSUPPORTED       |
| 0x0B/0x0C XTAL       | xtal             | Not applicable                                             | UNSUPPORTED       |
| 0x0D GAIN_BY_INDEX   | gain index       | Preset index                                               | EMULATED          |
| 0x0E BIAS_TEE        | antenna power    | GPIO-controlled LNA power (board-defined)                  | OPTIONAL          |

### 7.2 Required disclosures

* CAPS MUST include `COMMAND_SEMANTICS` so consumers can see the mapping.
* WATERFALL rows MUST include `SIMULTANEITY=SEQUENTIAL_SWEEP`.

---

## 8. Extended scanner-native control surface (RSP‑B)

### 8.1 Extended command IDs (proposed)

| CMD_ID | Name            | Args                                |
| ------ | --------------- | ----------------------------------- |
| 0x1001 | SET_SWEEP_RANGE | start_hz:uint32, end_hz:uint32      |
| 0x1002 | SET_SWEEP_STEP  | step_hz:uint32                      |
| 0x1003 | SET_DWELL_US    | dwell_us:uint32                     |
| 0x1004 | SET_SETTLE_US   | settle_us:uint32                    |
| 0x1005 | SET_GRID_LIST   | count:uint16 + list(freq_hz:uint32) |
| 0x1006 | SET_ROW_RATE    | target_rows_per_sec:uint16          |
| 0x1007 | SET_RSSI_UNIT   | enum                                |
| 0x1008 | SET_TRIGGER     | threshold + persistence             |
| 0x1009 | GET_TELEMETRY   | none                                |

### 8.2 Negotiation workflow (recommended)

Client can request intent:

* “902–928 MHz, 25 kHz resolution, 10 fps.”

Node responds with ACK:

* STATUS=DEGRADED
* applied: step=50 kHz, fps=4
* note: LIMIT_MAX_BINS

---

## 9. RSSI waterfall engineering: timing, profiles, and math

### 9.1 Row timing model

For a CC1101 sequential sweep:

* `row_time_us ≈ bins * (settle_us + dwell_us + overhead_us)`

Overhead includes SPI transactions, state changes, and scheduler jitter.

### 9.2 Worked example: 902–928 MHz ISM

Span: 26 MHz.

**Case A: 50 kHz step**

* bins = 26,000,000 / 50,000 = **520 bins**
* settle_us = 150
* dwell_us = 250
* overhead_us = 100

Per bin = 500 us

* row_time = 520 * 500 us = **260,000 us** = **260 ms**
* rows/sec ≈ **3.85 fps**

**Case B: 200 kHz step (fast scan)**

* bins = 130
* per bin 500 us
* row_time = 65 ms
* rows/sec ≈ 15.4 fps

This is why arrays often partition bands across nodes.

### 9.3 Recommended scan profiles

| Profile     | Step    | Typical bins (902–928) | Target fps | Use case                        |
| ----------- | ------- | ---------------------- | ---------- | ------------------------------- |
| FAST_COARSE | 200 kHz | 130                    | 10–20      | UI feel, burst detection cueing |
| MEDIUM      | 100 kHz | 260                    | 5–10       | occupancy + events              |
| FINE        | 50 kHz  | 520                    | 2–5        | detailed band mapping           |

### 9.4 RSSI representation

Canonical recommendation:

* **INT16_TENTH_DB** in Mode B (stable math, small payload).

Mode A (IQ emulation) may operate internally in float but output IQ8.

---

## 10. Mode A: IQ emulation (drop‑in legacy waterfall)

### 10.1 Non-negotiable safety constraints

* Stream type MUST be labeled `IQ8_EMULATED` in CAPS.
* If exposing a classic rtl_tcp port, a separate RSP‑B control port MUST be available for consumers that want truth.
* Consumers must be warned: **do not demodulate**.

### 10.2 Recommended encoding method: “FFT-bin synthesis”

For each waterfall row:

1. Create a complex frequency-domain vector `X[k]` with magnitudes derived from RSSI bins.
2. Assign random phases (or deterministic seeded phases for repeatability).
3. Run inverse FFT to produce time-domain `x[n]`.
4. Quantize to unsigned 8-bit IQ centered at 128.
5. Stream blocks at a chosen “synthetic sample rate.”

### 10.3 Deterministic semantics for classic controls in Mode A

**SET_FREQ**

* Sets sweep center for RSSI acquisition.

**SET_SR**

* Sets *synthetic output sample rate* to keep legacy apps happy.
* Also sets row target rate best-effort via mapping:

  * higher SET_SR -> higher desired fps (clamped).
* CAPS must disclose mapping.

**SET_GAIN / SET_GAIN_MODE**

* Map to CC1101 AGC preset family and preset index.

### 10.4 Known limitations

* Any downstream decoder expecting real RF I/Q is invalid.
* Waterfall visualization is valid as a display of the measured RSSI grid.

---

## 11. CC1101 implementation requirements (scanner engine)

### 11.1 Minimum viable configuration abstraction

Implementation MUST provide a stable abstraction for:

* frequency set / hop
* RX enable
* RSSI read
* channel bandwidth selection
* AGC profile selection
* AFC enable/disable (optional)

The implementation should isolate CC1101 register specifics behind:

* `radio_set_freq(hz)`
* `radio_set_rx_mode(cfg)`
* `radio_read_rssi()`
* `radio_set_bw(hz)`
* `radio_set_agc_profile(id)`

### 11.2 RSSI sampling policy

Define and document:

* single read vs N-sample average
* median-of-3 recommended for noise robustness
* discard reads during settle window

Recommended default:

* settle_us = 150
* dwell_us = 250
* rssi_reads_per_bin = 3
* rssi_stat = median

### 11.3 Adaptive settle (optional but valuable)

A research extension:

* sample RSSI repeatedly after hop until variance falls below a threshold or max settle hit.

### 11.4 Backpressure and buffering

Node MUST avoid unbounded buffering.

* If client is slow, prefer:

  * drop oldest frames,
  * keep newest row,
  * publish telemetry drops.

---

## 12. Array-level architecture (multi-node sensing)

### 12.1 Frequency partitioning

To increase effective fps:

* split a band into sub-bands per **element** (often implemented as one node per element),
* fuse by stitching rows into a composite spectrum.
* fuse by stitching rows into a composite spectrum.

### 12.2 Alignment (timestamps, sequences, and feature matching)

Fusion SHOULD support three alignment approaches, as declared by CAPS `TIME_MODEL`:

1. **WALL_CLOCK**

* Use `[TS_START, TS_END]` and (optionally) `EST_TIME_ERROR_US`.
* Best when NTP/chrony is stable on a LAN or when PPS/GPSDO is available.

2. **SEQUENCE**

* Use `ROW_SEQ` and `ROW_TIME_US_EST`.
* Best when absolute time is unavailable but sweep cadence is stable.

3. **REFERENCE_BEACON**

* Align streams by matching known features:

  * a periodic beacon transmitter,
  * a known reference emitter (e.g., a Meshtastic node periodically transmitting),
  * or other distinctive external transmissions.

For burst detection and cueing, prefer EVENTS, which follow the same TIME_MODEL (timestamped or sequence-indexed).

### 12.3 Hybrid cue-and-capture workflow

```
CC1101 elements: continuous scan + EVENTS
        |
        +----> event bus ----> coherent SDR elements (IQ capture)
                              |
                              +--> correlation / advanced analysis
```

This is the recommended pathway toward “VLBI-inspired” research while remaining explicit about what each data product can and cannot support.

### 12.4 Optional TDOA-style experiments (reference-assisted)

While the baseline design does not depend on TDOA, it can be explored when elements can establish time/position relative to a known reference. Practical patterns include:

* A **reference transmitter** with known location emitting periodic pulses or structured bursts.
* Elements with known locations (GPS) using those bursts to estimate per-element timing offsets.
* A fusion layer that uses those offsets to tighten cross-element alignment beyond NTP.

These experiments require careful characterization of:

* beacon timing stability,
* element receiver latency and sweep/measurement latency,
* multipath and RF propagation effects.

---

## 13. Interoperability matrix (initial targets)

> This section guides implementation choices for maximum reuse.

### 13.1 Legacy apps (via Mode A or proxy)

| Tool                            | `rtl_tcp` connect | Waterfall works | Demod valid   | Notes                                    |
| ------------------------------- | ----------------- | --------------- | ------------- | ---------------------------------------- |
| GNU Radio (osmosdr/rtl_tcp src) | Yes               | Yes             | No (emulated) | Best with proxy + native block           |
| SDR++                           | Often             | Yes             | No            | Behavior depends on build/plugin support |
| GQRX                            | Yes               | Yes             | No            | Great for quick waterfall UI             |
| SDR#                            | Yes (via plugins) | Yes             | No            | Windows-specific quirks                  |

**Recommendation:** treat Mode A as “visualization only.”

### 13.2 Native consumers (Mode B)

| Consumer                      | Effort | Best use                    |
| ----------------------------- | ------ | --------------------------- |
| GNU Radio custom source block | Medium | research pipelines + fusion |
| Simple Python client          | Low    | testing + validation        |
| Custom web UI                 | Medium | dashboards                  |

---

## 14. Security, operability, and robustness

### 14.1 Security posture

* No auth by default.
* Deployment recommendations:

  * bind to LAN only,
  * tunnel over WireGuard/SSH if remote.

### 14.2 Reliability behaviors (must document)

* Reconnect behavior: client reconnect gets new CAPS.
* Slow consumer policy: drop frames, publish telemetry.
* Max frame size: configurable.

### 14.3 Telemetry counters (minimum set)

* `rows_sent`, `rows_dropped`, `frames_sent`, `frames_dropped`
* `avg_row_time_us`, `row_jitter_us`, `max_row_time_us`
* `socket_backpressure_events`
* `time_source`, `est_time_error_us`

---

## 15. Versioning and compatibility guarantees

### 15.1 Protocol versioning

* `RSP0` magic + `version=1` in frame header.
* TLV unknown types MUST be ignored.
* Breaking changes bump version.

### 15.2 Backward compatibility rules

* New optional TLVs allowed.
* New frame types allowed.
* Existing frame types/required TLVs must remain stable.

---

## 16. Compliance test plan (must-pass)

### 16.1 Node compliance tests

* CAPS is first frame and parses.
* WATERFALL_RSSI frames include required metadata.
* Alignment model compliance:

  * If `TIME_MODEL=WALL_CLOCK`: `TS_END >= TS_START` and (optionally) matches measured sweep duration within tolerance.
  * If `TIME_MODEL=SEQUENCE`: `ROW_SEQ` is monotonic and `ROW_TIME_US_EST > 0`.
  * If `TIME_MODEL=REFERENCE_BEACON`: node documents the beacon/alignment mode in CAPS/telemetry.
* Grid invariants:
* Grid invariants:

  * bins > 0
  * step_hz > 0
  * payload length matches bins * element_size
* Telemetry increments appropriately.

### 16.2 Consumer sanity tests

* A reference client can:

  * plot waterfall,
  * compute row_time distribution,
  * detect dropped frames,
  * confirm simultaneity flag.

---

## 17. Engineering plan

### Phase 1 — Mode B baseline

1. CC1101 RSSI read + stable RX configuration
2. Deterministic sweep engine (range, step, dwell, settle)
3. TCP server streaming RSP‑B frames
4. CAPS + TELEMETRY
5. Reference Python client

### Phase 2 — Events + triggers

1. Peak detection and persistence logic
2. EVENTS frames
3. Triggered zoom scanning (optional)

### Phase 3 — Mode A IQ emulation

1. FFT-bin synthesis implementation
2. Legacy `rtl_tcp` port (or proxy)
3. Interop testing with GQRX/SDR++/GNU Radio

### Phase 4 — Tier 1 upgrades

1. Calibration workflow
2. Better time sync options (NTP discipline, optional PPS)
3. Fusion reference implementation (multi-node stitching)

---

## 18. Open questions (with recommended defaults)

1. **Bands**

* Default: 902–928 MHz ISM (US), plus optional 433 MHz.

2. **Baseline profile**

* Default: MEDIUM (100 kHz step), dwell 250 us, settle 150 us.

3. **Time sync**

* Default: NTP with telemetry reporting; optional GPS time for Tier 1.

4. **RSSI units**

* Default: INT16_TENTH_DB.

---

## 19. Glossary

* **Element**: a participant in an interferometry/sensing array (the measurement unit).
* **Node**: the networked device implementing this protocol (often one element, sometimes more).
* **Bin**: one frequency point in a sweep.
* **Row**: a set of bins that form one waterfall line.
* **Grid**: mapping from bin index to frequency.
* **Dwell**: time spent measuring RSSI at one bin.
* **Settle**: time waiting after frequency hop before measuring.
* **Simultaneity**: whether bins were measured at the same time.
* **Time model**: how rows/events are aligned across elements (WALL_CLOCK, SEQUENCE, REFERENCE_BEACON).
* **IQ Emulation**: generating synthetic I/Q so legacy FFT displays can show a waterfall.
* **Cueing**: using cheap sensors to trigger higher-cost coherent capture.

---

## Appendix A — TLV type registry (starter)

| TLV                | Type ID | Value          |
| ------------------ | ------- | -------------- |
| NODE_ID            | 0x0001  | string         |
| DEVICE_CLASS       | 0x0002  | uint8          |
| TIER               | 0x0003  | uint8          |
| STREAM_TYPES       | 0x0004  | uint32 bitset  |
| SUPPORTED_COMMANDS | 0x0005  | uint32/var     |
| FREQ_RANGES        | 0x0006  | repeated pairs |
| TIME_SOURCE        | 0x0007  | uint8          |
| TIME_MODEL         | 0x0008  | uint8          |
| EST_TIME_ERROR_US  | 0x0009  | uint32         |
| RSSI_UNIT          | 0x0009  | uint8          |
| RSSI_CALIBRATED    | 0x000A  | uint8          |
| CAL_VERSION        | 0x000B  | string         |
| SWEEP_LIMITS       | 0x000C  | struct         |
| COMMAND_SEMANTICS  | 0x000D  | string/struct  |
| TS_START_NS        | 0x0101  | uint64         |
| TS_END_NS          | 0x0102  | uint64         |
| ROW_SEQ            | 0x0109  | uint64         |
| ROW_TIME_US_EST    | 0x010A  | uint32         |
| SIMULTANEITY       | 0x0103  | uint8          |
| FREQ_START_HZ      | 0x0104  | uint32         |
| STEP_HZ            | 0x0105  | uint32         |
| BINS               | 0x0106  | uint16         |
| DWELL_US           | 0x0107  | uint32         |
| SETTLE_US          | 0x0108  | uint32         |

---

## Appendix B — ASCII diagrams (quick reference)

### B.1 Mode B framing

```
[RSP0][ver][type][flags][hlen][plen][ TLVs... ][ payload... ]
```

### B.2 Hybrid array workflow

```
CC1101 scan nodes  --->  EVENTS  --->  coherent IQ nodes  --->  advanced analysis
        |                         
        +--> WATERFALL_RSSI ---> dashboards / fusion
```
