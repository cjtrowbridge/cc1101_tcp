# Playbook: How to Modify Firmware

*Status: Stable*

## Objective
To implement new features or fixes in the ESP32 firmware while ensuring strict alignment with the Python API and documentation.

## Prerequisites
1.  **Repo State**: Clean git status.
2.  **API Config**: Valid `api/config.json` pointing to your test device.
3.  **Dependencies**: `arduino-cli` and `SmartRC-CC1101-Driver-Lib` installed (handled by `upload_ota.ps1`).

## Workflow: The Atomic Task Loop

### 1. Select & Plan
1.  Open `firmware/README.md`.
2.  Identify the next unchecked item in the Roadmap.
3.  **Check API**: Does this feature exist in `api/README.md`? If not, add it as "❌".

### 2. Write the Test (Test-Driven)
*Before writing firmware, define success.*
1.  Create or open `api/tests/test_[feature].py`.
2.  Implement a test case that sends the command and asserts the expected behavior (or just successful transmission if closed-loop isn't possible yet).
3.  Run the test: `pytest api/tests/test_[feature].py`.
    *   **Expectation**: It fails (Connection refused, or timeout, or missing feature).

### 3. Implement Firmware Logic
1.  Open `firmware/cc1101_tcp/cc1101_tcp.ino`.
2.  Implement the logic.
    *   *Tip*: Keep `loop()` functionality non-blocking.
    *   *Tip*: Use `Serial.printf` for debugging (viewed via USB or future UDP logger).
3.  **Compile & Deploy**:
    ```powershell
    cd firmware
    .\upload_ota.ps1
    ```
    *   Wait for "SUCCESS".

### 4. Validate
1.  Run the test again: `pytest api/tests/test_[feature].py`.
2.  If it fails, debug firmware -> Deploy -> Retry.
3.  If it passes:
    *   Update `firmware/README.md`: Mark task as [x].
    *   Update `api/README.md`: Mark feature as ✅.

### 5. Commit
1.  Run `playbooks/how_to_commit_changes.md`.
