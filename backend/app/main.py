from contextlib import asynccontextmanager
from fastapi import FastAPI

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Application startup logic
    print("Starting up SmartAid backend...")
    yield
    # Application shutdown logic
    print("Shutting down SmartAid backend...")

app = FastAPI(
    title="SmartAid API",
    description="Backend API for SmartAid Emergency Response System",
    version="1.0.0",
    lifespan=lifespan,
)

@app.get("/health", tags=["System"])
async def health_check():
    return {"status": "ok", "service": "SmartAid Backend"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
