from .mongo_client import MongoDBClient

async def get_db():
    """
    Dependency to get the database instance for FastAPI endpoints.
    """
    return MongoDBClient.get_database()
