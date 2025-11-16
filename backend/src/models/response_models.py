from datetime import datetime, timezone
from typing import List

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = "ok"
    time: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class SuccessResponse(BaseModel):
    success: bool = True

class Friend(BaseModel):
    id: str
    name: str
    status: str = "offline"

class FriendsResponse(BaseModel):
    friends: List[Friend]

class StartSessionResponse(BaseModel):
    session_id: str
    started_at: datetime
    sauna_type: str

class StopSessionResponse(BaseModel):
    session_id: str
    user_id: str
    started_at: datetime
    stopped_at: datetime
    duration_seconds: int

class SaunaRecommendationResponse(BaseModel):
    temperature: float  # in Celsius
    humidity: float  # in percentage
    session_length: float  # in minutes
    goals_used: List[str]

#NOT USED
class ChatMessageResponse(BaseModel):
    answer: str
    sources: List[str] = []
    session_id: str
    chat_history: List[dict] = []
