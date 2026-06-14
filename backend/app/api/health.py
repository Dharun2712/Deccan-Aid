from fastapi import APIRouter
from datetime import datetime
from ..schemas.service_status import ServiceStatus
from ..services.readiness_checks import check_all_dependencies
from ..config import settings

router = APIRouter()

@router.get("/readiness", response_model=ServiceStatus, tags=["System"])
async def readiness_check():
    """
    Detailed readiness probe for orchestrators like Kubernetes.
    Validates backend logic and external database connectivity.
    """
    dependencies = await check_all_dependencies()
    is_healthy = all(status == "healthy" for status in dependencies.values())
    
    return ServiceStatus(
        service=settings.PROJECT_NAME,
        status="ready" if is_healthy else "degraded",
        dependencies=dependencies,
        timestamp=datetime.utcnow().isoformat()
    )
