from typing import Optional, List

from pydantic import BaseModel, Field

class StartSessionRequest(BaseModel):
    temperature: int = Field()
    humidity: int = Field()
    session_length: int = Field()  # in seconds
    uid: str = Field()


class StopSessionRequest(BaseModel):
    session_id: str
    user_id: Optional[str] = None



class SaunaRecommendationRequest(BaseModel):
    age: int
    gender: str
    height: int
    weight: int
    goals: List[str]

#NOT USED
class ChatMessageRequest(BaseModel):
    message: str

class QuestionRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = Field(None, description="Client-managed session ID")

class ClearSessionRequest(BaseModel):
    session_id: str = Field(..., min_length=1)