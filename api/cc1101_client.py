import socket
import struct
import time
import json
import os

# Load Configuration
CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'config.json')
try:
    with open(CONFIG_PATH, 'r') as f:
        API_CONFIG = json.load(f)
except FileNotFoundError:
    print("Warning: config.json not found, using compile-time defaults.")
    API_CONFIG = {
        "device": {"host": "127.0.0.1", "port": 1234},
        "radio": {"frequency": {"min": 300000000, "max": 928000000, "default": 915000000}},
    }

class CC1101Client:
    def __init__(self, host=None, port=None, element_index=0):
        """
        Initialize the client.
        If host/port are provided (host is not None), they take precedence.
        Otherwise, loads the element at `element_index` from config.json.
        """
        if host:
            self.host = host
            self.port = port if port else 1234
        else:
            # Pick from config based on element_index
            elements = API_CONFIG.get('elements', [])
            if not elements:
                # Fallback to legacy 'device' key if elements missing (migration safety)
                fallback = API_CONFIG.get('device')
                if fallback:
                   self.host = fallback.get('host', '127.0.0.1')
                   self.port = fallback.get('port', 1234)
                else: 
                   raise ValueError("No elements defined in config.json")
            elif element_index >= len(elements):
                 raise ValueError(f"element_index {element_index} out of range (0-{len(elements)-1})")
            else:
                el = elements[element_index]
                self.host = el['host']
                self.port = el.get('port', 1234)
                print(f"Initialized client for element: {el.get('name', 'unknown')} ({self.host}:{self.port})")
            
        self.sock = None
        
        # Load constraints
        self.freq_min = API_CONFIG['radio']['frequency']['min']
        self.freq_max = API_CONFIG['radio']['frequency']['max']

    def connect(self):
        """Establish TCP connection to the device."""
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.settimeout(API_CONFIG.get('timeouts', {}).get('connection', 2.0))
        self.sock.connect((self.host, self.port))
        print(f"Connected to {self.host}:{self.port}")

    def close(self):
        if self.sock:
            self.sock.close()

    def _send_command(self, cmd_id, param):
        """Send a standard 5-byte rtl_tcp command."""
        # cmd (1 byte) + param (4 bytes big-endian)
        packet = struct.pack('>BI', cmd_id, param)
        self.sock.sendall(packet)

    def set_frequency(self, freq_hz):
        """0x01: Set Center Frequency"""
        if not (self.freq_min <= freq_hz <= self.freq_max):
            raise ValueError(f"Frequency {freq_hz} out of range ({self.freq_min}-{self.freq_max})")
        
        self._send_command(0x01, freq_hz)

    def set_sample_rate(self, rate_hz):
        """0x02: Set Sample Rate"""
        self._send_command(0x02, rate_hz)

    def set_gain_mode(self, manual):
        """0x03: Set Gain Mode (0=Auto, 1=Manual)"""
        self._send_command(0x03, 1 if manual else 0)

    def set_gain(self, gain_tenths_db):
        """0x04: Set Gain (tenths of dB)"""
        self._send_command(0x04, gain_tenths_db)

    # Future: Custom commands
