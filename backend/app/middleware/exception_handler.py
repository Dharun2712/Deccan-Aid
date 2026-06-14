from fastapi import Request, FastAPI
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
import logging

logger = logging.getLogger(__name__)

def add_exception_handlers(app: FastAPI):
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(request: Request, exc: StarletteHTTPException):
        logger.warning(f"HTTP exception: {exc.detail} on {request.url}")
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": True, "message": exc.detail, "data": None},
        )

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        logger.error(f"Unhandled exception on {request.url}: {str(exc)}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={"error": True, "message": "An unexpected error occurred.", "data": None},
        )
