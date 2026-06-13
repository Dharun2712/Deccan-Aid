from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas.dispatch import DispatchCreate, DispatchResponse
from ..schemas.api_response import APIResponse
from ..services.dispatch_service import DispatchService
from ..services.assignment_engine import AssignmentEngine
from ..services.driver_service import DriverService
from ..repositories.dispatch_repository import DispatchRepository
from ..repositories.driver_repository import DriverRepository
from ..repositories.hospital_repository import HospitalRepository
from ..repositories.emergency_repository import EmergencyRepository
from ..database import get_db

router = APIRouter(prefix="/dispatches", tags=["Dispatch"])

async def get_dispatch_service(db=Depends(get_db)) -> DispatchService:
    dispatch_repo = DispatchRepository(db)
    driver_repo = DriverRepository(db)
    hospital_repo = HospitalRepository(db)
    emergency_repo = EmergencyRepository(db)
    
    engine = AssignmentEngine(driver_repo, hospital_repo, emergency_repo)
    driver_service = DriverService(driver_repo)
    
    return DispatchService(dispatch_repo, engine, driver_service)

@router.post("", response_model=APIResponse[DispatchResponse], status_code=status.HTTP_201_CREATED)
async def create_dispatch(
    request: DispatchCreate,
    service: DispatchService = Depends(get_dispatch_service)
):
    try:
        dispatch = await service.create_dispatch(request)
        return APIResponse(data=DispatchResponse.model_validate(dispatch))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/{id}", response_model=APIResponse[DispatchResponse])
async def get_dispatch(
    id: str,
    service: DispatchService = Depends(get_dispatch_service)
):
    dispatch = await service.repository.get_by_id(id)
    if not dispatch:
        raise HTTPException(status_code=404, detail="Dispatch not found")
    return APIResponse(data=DispatchResponse.model_validate(dispatch))

@router.patch("/{id}/accept", response_model=APIResponse[DispatchResponse])
async def accept_dispatch(
    id: str,
    service: DispatchService = Depends(get_dispatch_service)
):
    try:
        dispatch = await service.accept_dispatch(id)
        if not dispatch:
            raise HTTPException(status_code=404, detail="Dispatch not found")
        return APIResponse(data=DispatchResponse.model_validate(dispatch))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{id}/complete", response_model=APIResponse[DispatchResponse])
async def complete_dispatch(
    id: str,
    service: DispatchService = Depends(get_dispatch_service)
):
    try:
        dispatch = await service.complete_dispatch(id)
        if not dispatch:
            raise HTTPException(status_code=404, detail="Dispatch not found")
        return APIResponse(data=DispatchResponse.model_validate(dispatch))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{id}/cancel", response_model=APIResponse[DispatchResponse])
async def cancel_dispatch(
    id: str,
    service: DispatchService = Depends(get_dispatch_service)
):
    try:
        dispatch = await service.cancel_dispatch(id)
        if not dispatch:
            raise HTTPException(status_code=404, detail="Dispatch not found")
        return APIResponse(data=DispatchResponse.model_validate(dispatch))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
