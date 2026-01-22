# Playbook: How to Add Firmware Features (API-First)

*Status: Stable*

## Objective
To ensure rapid, reliable development where **Firmware**, **Docs**, and **Python Client** remain strictly synchronized. All firmware features must be immediately testable via the Python API.

## Prerequisites
*   `api/README.md` is the Source of Truth for features.
*   Python environment set up in `api/`.

## Workflow Step-by-Step

### 1. Define the Interface (Spec-First)
Before writing C++ code, update the documentation to define the contract.

1.  **Update `api/README.md`**:
    *   Add the new Command ID (`0xXX`) or Endpoint to the table.
    *   Mark it as "❌ (Planned)".
2.  **Define Python Method**:
    *   Decide how the Python client will invoke this (e.g., `client.set_modulation(MOD_ASK)`).

### 2. Implement Python Test (TDD)
Write the test *before* or *simultaneously* with the feature. This acts as your "Runner" to verify the firmware.

1.  **Create Test**: `api/tests/test_[feature].py`.
2.  **Logic**:
    *   Connect to device.
    *   Send command.
    *   Assert expected response/behavior.
    *   *Note*: The test will fail initially.

### 3. Implement Firmware Logic
1.  **Modify `firmware/cc1101_tcp/cc1101_tcp.ino`**:
    *   Add the command handler in the TCP loop.
    *   Implement the hardware logic (CC1101 driver calls).
2.  **Refactor**: Keep the `.ino` file clean; separate complex logic into header files if needed.

### 4. Implement Python Client
1.  **Update `api/cc1101_client.py`**:
    *   Add the method to the class.
    *   Ensure it constructs the correct binary packet.

### 5. Validate & Mark Complete
1.  **Deploy Firmware**: Use `upload_ota.ps1`.
2.  **Run Validation**: `pytest api/tests/test_[feature].py`.
3.  **Update Docs**: Change "❌" to "✅" in `api/README.md`.

## Definition of Done
*   [ ] `api/README.md` updated.
*   [ ] Firmware feature works.
*   [ ] Python Client method exists.
*   [ ] Test script passes against live hardware.
