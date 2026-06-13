from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..schemas.hospital import HospitalCreate, HospitalResponse, CapacityUpdate
from ..schemas.admission import AdmissionCreate, AdmissionResponse
from ..schemas.api_response import APIResponse
from ..services.hospital_service import HospitalService
from ..services.admission_service import AdmissionService
from ..repositories.hospital_repository import HospitalRepository
from ..repositories.admission_repository import AdmissionRepository
from ..database import get_db

router = APIRouter(tags=["Hospital"])

async def get_hospital_service(db=Depends(get_db)) -> HospitalService:
    repository = HospitalRepository(db)
    return HospitalService(repository)

async def get_admission_service(db=Depends(get_db), hospital_service: HospitalService = Depends(get_hospital_service)) -> AdmissionService:
    repository = AdmissionRepository(db)
    return AdmissionService(repository, hospital_service)

@router.post("/hospitals", response_model=APIResponse[HospitalResponse], status_code=status.HTTP_201_CREATED)
async def create_hospital(
    request: HospitalCreate,
    service: HospitalService = Depends(get_hospital_service)
):
    try:
        hospital = await service.create_hospital(request)
        return APIResponse(data=HospitalResponse.model_validate(hospital))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/hospitals", response_model=APIResponse[List[HospitalResponse]])
async def list_hospitals(
    service: HospitalService = Depends(get_hospital_service)
):
    hospitals = await service.get_all_hospitals()
    return APIResponse(data=[HospitalResponse.model_validate(h) for h in hospitals])

@router.get("/hospitals/{id}", response_model=APIResponse[HospitalResponse])
async def get_hospital(
    id: str,
    service: HospitalService = Depends(get_hospital_service)
):
    hospital = await service.get_hospital(id)
    if not hospital:
        raise HTTPException(status_code=404, detail="Hospital not found")
    return APIResponse(data=HospitalResponse.model_validate(hospital))

@router.patch("/hospitals/{id}/capacity", response_model=APIResponse[HospitalResponse])
async def update_capacity(
    id: str,
    capacity: CapacityUpdate,
    service: HospitalService = Depends(get_hospital_service)
):
    try:
        hospital = await service.update_capacity(id, capacity)
        if not hospital:
            raise HTTPException(status_code=404, detail="Hospital not found")
        return APIResponse(data=HospitalResponse.model_validate(hospital))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/admissions", response_model=APIResponse[AdmissionResponse], status_code=status.HTTP_201_CREATED)
async def request_admission(
    request: AdmissionCreate,
    service: AdmissionService = Depends(get_admission_service)
):
    try:
        admission = await service.create_admission(request)
        return APIResponse(data=AdmissionResponse.model_validate(admission))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/admissions/{id}/approve", response_model=APIResponse[AdmissionResponse])
async def approve_admission(
    id: str,
    service: AdmissionService = Depends(get_admission_service)
):
    try:
        admission = await service.approve_admission(id)
        if not admission:
            raise HTTPException(status_code=404, detail="Admission not found")
        return APIResponse(data=AdmissionResponse.model_validate(admission))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.patch("/admissions/{id}/reject", response_model=APIResponse[AdmissionResponse])
async def reject_admission(
    id: str,
    service: AdmissionService = Depends(get_admission_service)
):
    try:
        admission = await service.reject_admission(id)
        if not admission:
            raise HTTPException(status_code=404, detail="Admission not found")
        return APIResponse(data=AdmissionResponse.model_validate(admission))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
