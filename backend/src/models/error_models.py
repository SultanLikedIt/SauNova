from fastapi import HTTPException
from starlette import status

auth_fail = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="User authentication failed."
)

def generic_fail(detail: str = "An error occurred."):
    return HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=detail
    )