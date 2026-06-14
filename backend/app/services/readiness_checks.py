from ..mongo_client import MongoDBClient
import logging

logger = logging.getLogger(__name__)

async def check_database_readiness() -> str:
    """
    Ping the MongoDB cluster to ensure it is reachable.
    """
    try:
        if MongoDBClient.client is not None:
            # Send a ping to confirm a successful connection
            await MongoDBClient.client.admin.command('ping')
            return "healthy"
        return "disconnected"
    except Exception as e:
        logger.error(f"Database readiness check failed: {e}")
        return "unhealthy"

async def check_all_dependencies() -> dict:
    return {
        "database": await check_database_readiness(),
    }
