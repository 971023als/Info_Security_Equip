import abc
import json
import os

class BaseVendorParser(abc.ABC):
    """
    Base class for vendor-specific configuration parsers.
    Phase 1 will implement specific subclasses for Fortinet, Palo Alto, etc.
    """
    
    def __init__(self, config_path):
        self.config_path = config_path
        self.raw_config = ""
        self.parsed_data = {}

    def load_config(self):
        if not os.path.exists(self.config_path):
            raise FileNotFoundError(f"Config file not found: {self.config_path}")
        with open(self.config_path, 'r', encoding='utf-8', errors='ignore') as f:
            self.raw_config = f.read()

    @abc.abstractmethod
    def parse(self):
        """Parse raw config into structured data."""
        pass

    def get_value(self, key, default=None):
        return self.parsed_data.get(key, default)

    def save_parsed_json(self, output_path):
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(self.parsed_data, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    print("BaseVendorParser frame initialized.")
