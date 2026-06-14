from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas.emergency_request import EmergencyRequestCreate
from ..schemas.emergency_response import EmergencyResponse
from ..schemas.api_response import APIResponse
from ..services.emergency_service import EmergencyService
from ..repositories.emergency_repository import EmergencyRepository
from ..database import get_db

router = APIRouter(prefix="/emergencies", tags=["Emergency"])

async def get_emergency_service(db=Depends(get_db)) -> EmergencyService:
    repository = EmergencyRepository(db)
    return EmergencyService(repository)

@router.post("", response_model=APIResponse[EmergencyResponse], status_code=status.HTTP_201_CREATED)
async def create_emergency(
    request: EmergencyRequestCreate,
    service: EmergencyService = Depends(get_emergency_service)
):
    try:
        emergency = await service.create_emergency(request)
        return APIResponse(data=EmergencyResponse.model_validate(emergency))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{id}", response_model=APIResponse[EmergencyResponse])
async def get_emergency(
    id: str,
    service: EmergencyService = Depends(get_emergency_service)
):
    emergency = await service.get_emergency(id)
    if not emergency:
        raise HTTPException(status_code=404, detail="Emergency not found")
    return APIResponse(data=EmergencyResponse.model_validate(emergency))

@router.get("", response_model=APIResponse[List[EmergencyResponse]])
async def list_emergencies(
    skip: int = 0,
    limit: int = 100,
    service: EmergencyService = Depends(get_emergency_service)
):
    emergencies = await service.list_emergencies(skip=skip, limit=limit)
    return APIResponse(data=[EmergencyResponse.model_validate(e) for e in emergencies])

@router.patch("/{id}/cancel", response_model=APIResponse[EmergencyResponse])
async def cancel_emergency(
    id: str,
    service: EmergencyService = Depends(get_emergency_service)
):
    try:
        emergency = await service.cancel_emergency(id)
        if not emergency:
            raise HTTPException(status_code=404, detail="Emergency not found")
        return APIResponse(data=EmergencyResponse.model_validate(emergency))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
