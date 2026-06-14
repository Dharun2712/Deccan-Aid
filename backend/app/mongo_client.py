from motor.motor_asyncio import AsyncIOMotorClient
from .config import settings
import logging

logger = logging.getLogger(__name__)

class MongoDBClient:
    client: AsyncIOMotorClient = None

    @classmethod
    async def connect(cls):
        if cls.client is None:
            try:
                cls.client = AsyncIOMotorClient(
                    settings.MONGODB_URI,
                    minPoolSize=settings.MONGODB_MIN_POOL_SIZE,
                    maxPoolSize=settings.MONGODB_MAX_POOL_SIZE
                )
                logger.info("Successfully connected to MongoDB")
            except Exception as e:
                logger.error(f"Failed to connect to MongoDB: {str(e)}")
                raise e

    @classmethod
    async def close(cls):
        if cls.client is not None:
            cls.client.close()
            cls.client = None
            logger.info("MongoDB connection closed")

    @classmethod
    def get_database(cls):
        if cls.client is None:
            raise Exception("Database client not initialized")
        return cls.client[settings.MONGODB_DB_NAME]
