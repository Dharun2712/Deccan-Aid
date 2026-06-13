from pydantic import BaseModel, ConfigDict
from datetime import datetime

class BaseSchema(BaseModel):
    model_config = ConfigDict(populate_by_name=True, from_attributes=True)

class TimestampSchema(BaseSchema):
    created_at: datetime
    updated_at: datetime
