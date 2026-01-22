import pytest
from cc1101_client import CC1101Client, API_CONFIG
import os

# Read target from environment, config override, or default to first element
TARGET_IP = os.getenv("CC1101_HOST")
DEFAULT_FREQ = API_CONFIG['radio']['frequency']['default']

@pytest.fixture
def client():
    # Use config defaults (element 0) or explicit host
    if TARGET_IP:
        c = CC1101Client(host=TARGET_IP)
    else:
        c = CC1101Client(element_index=0)
        
    try:
        c.connect()
        yield c
    except OSError:
        # If we can't connect, we skip. But if we selected a specific IP and failed, maybe fail?
        # For now, skip is safer for generic test suites.
        pytest.skip(f"Could not connect to {c.host}:{c.port}")
    finally:
        c.close()


def test_connection(client):
    assert client.sock is not None

def test_set_frequency(client):
    # Pass valid frequency from config
    client.set_frequency(DEFAULT_FREQ)
    
def test_set_frequency_out_of_range(client):
    # Test validation logic
    with pytest.raises(ValueError):
        client.set_frequency(100) # Way below min
