import sys
from unittest.mock import MagicMock

sys.modules["awsglue"] = MagicMock()
sys.modules["awsglue.context"] = MagicMock()
sys.modules["awsglue.job"] = MagicMock()
sys.modules["awsglue.utils"] = MagicMock()
sys.modules["awsglue.transforms"] = MagicMock()
sys.modules["awsglue.dynamicframe"] = MagicMock()
