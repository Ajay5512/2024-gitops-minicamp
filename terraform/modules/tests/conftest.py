import sys
from unittest.mock import MagicMock

# Set up mock modules before any tests are loaded
sys.modules["awsglue"] = MagicMock()
sys.modules["awsglue.context"] = MagicMock()
sys.modules["awsglue.job"] = MagicMock()
