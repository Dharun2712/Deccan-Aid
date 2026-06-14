from functools import lru_cache
from .settings import Settings

@lru_cache()
def get_settings() -> Settings:
    """
    Returns a cached instance of the settings object.
    Since reading from env and validating can be slow, 
    we cache the result using lru_cache.
    """
    return Settings()

settings = get_settings()
