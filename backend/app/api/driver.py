from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas.driver import DriverCreate, DriverResponse, DriverAvailabilityEnum, DriverStatusEnum
from ..schemas.api_response import APIResponse
from ..services.driver_service import DriverService
from ..repositories.driver_repository import DriverRepository
from ..database import get_db

router = APIRouter(prefix="/drivers", tags=["Driver"])

async def get_driver_service(db=Depends(get_db)) -> DriverService:
    repository = DriverRepository(db)
    return DriverService(repository)

@router.post("", response_model=APIResponse[DriverResponse], status_code=status.HTTP_201_CREATED)
async def create_driver(
    request: DriverCreate,
    service: DriverService = Depends(get_driver_service)
):
    try:
        driver = await service.create_driver(request)
        return APIResponse(data=DriverResponse.model_validate(driver))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/available", response_model=APIResponse[List[DriverResponse]])
async def get_available_drivers(
    service: DriverService = Depends(get_driver_service)
):
    drivers = await service.get_available_drivers()
    return APIResponse(data=[DriverResponse.model_validate(d) for d in drivers])

@router.get("/{driver_id}", response_model=APIResponse[DriverResponse])
async def get_driver(
    driver_id: str,
    service: DriverService = Depends(get_driver_service)
):
    driver = await service.get_driver(driver_id)
    if not driver:
        raise HTTPException(status_code=404, detail="Driver not found")
    return APIResponse(data=DriverResponse.model_validate(driver))

@router.patch("/{driver_id}/availability", response_model=APIResponse[DriverResponse])
async def update_driver_availability(
    driver_id: str,
    availability: DriverAvailabilityEnum,
    service: DriverService = Depends(get_driver_service)
):
    try:
        driver = await service.update_availability(driver_id, availability.value)
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found")
        return APIResponse(data=DriverResponse.model_validate(driver))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/{driver_id}/status", response_model=APIResponse[DriverResponse])
async def update_driver_status(
    driver_id: str,
    status: DriverStatusEnum,
    service: DriverService = Depends(get_driver_service)
):
    try:
        driver = await service.update_status(driver_id, status.value)
        if not driver:
            raise HTTPException(status_code=404, detail="Driver not found")
        return APIResponse(data=DriverResponse.model_validate(driver))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
