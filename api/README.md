# cc1101_tcp Python API

This directory contains the reference Python client implementation and validation suite for the `cc1101_tcp` firmware. 

**Critical Rule**: Any feature added to the firmware MUST have a corresponding method in this Python API and a validation test script.

## Feature Registry & Endpoints

### 1. TCP Control & Stream (Port 1234)
The primary interface is a TCP socket compatible with the `rtl_tcp` protocol.

**Standard `rtl_tcp` Commands**
| Command ID | Name | Description | Implemented? |
| :--- | :--- | :--- | :--- | 
| `0x01` | `SET_FREQ` | Set center frequency (Hz) | ❌ |
| `0x02` | `SET_SAMPLE_RATE` | Set sample rate (Hz) | ❌ |
| `0x04` | `SET_GAIN` | Set tuner gain | ❌ |
| `0x05` | `SET_PPM` | Set freq correction | ❌ |
| `0x08` | `SET_AGC` | Enable/Disable AGC | ❌ |

**Custom Extensions**
| Command ID | Name | Description | Implemented? |
| :--- | :--- | :--- | :--- |
| `0x90` | `GET_STATUS` | Request JSON status blob (Protocol Extension) | ❌ |
| `0x91` | `RESTART` | Reboot the device | ❌ |

### 2. Management (HTTP)
*While the WebUI is removed, simple HTTP endpoints are retained for fleet discovery and health checks if necessary, though TCP is preferred.*

| Endpoint | Method | Description | Implemented? |
| :--- | :--- | :--- | :--- |
| `/status` | `GET` | Return device health, RSSI, and uptime. | ❌ |

## Configuration
The Python client uses `config.json` to define the array of available elements and hardware constraints.

```json
{
    "elements": [
        {
            "id": 1,
            "name": "node-01",
            "host": "192.168.1.100",
            "port": 1234
        }
    ],
    "radio": {
        "frequency": {
            "min": 300000000,
            "max": 928000000,
            "default": 433920000
        }
    }
}
```

## Usage

```python
from cc1101_client import CC1101Client

# Connect to the first element in config.json
client = CC1101Client(element_index=0)

# Connect to a specific element by index
client_2 = CC1101Client(element_index=1)

# Manual override
client_3 = CC1101Client(host="10.0.0.5")

client.connect()
```

## Testing & Validation
All new features must be validated using `pytest`.

```bash
pytest tests/test_basic_connection.py
```
