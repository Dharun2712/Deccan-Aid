import time
import logging
from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger("api_requests")

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        response = await call_next(request)
        
        process_time = time.time() - start_time
        logger.info(
            f"method={request.method} path={request.url.path} "
            f"status={response.status_code} duration={process_time:.3f}s"
        )
        return response

def add_request_logging(app: FastAPI):
    app.add_middleware(RequestLoggingMiddleware)
