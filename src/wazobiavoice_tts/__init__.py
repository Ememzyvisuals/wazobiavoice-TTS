try:
    from importlib.metadata import version
except ImportError:
    from importlib_metadata import version  # For Python <3.8

__version__ = version("wazobiavoice-tts")


from .tts import WazobiaVoiceTTS
from .vc import WazobiaVoiceVC
from .mtl_tts import WazobiaVoiceMultilingualTTS, SUPPORTED_LANGUAGES
