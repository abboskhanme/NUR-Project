"""Custom HTTP exceptions and global handlers."""
from fastapi import HTTPException, Request, status
from fastapi.responses import JSONResponse


class AppException(HTTPException):
    """Base application exception."""


class NotFoundException(AppException):
    def __init__(self, detail: str = "Topilmadi"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class BadRequestException(AppException):
    def __init__(self, detail: str = "So'rov noto'g'ri"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


class ForbiddenException(AppException):
    def __init__(self, detail: str = "Ruxsat yo'q"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


class ConflictException(AppException):
    def __init__(self, detail: str = "Konflikt"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)


async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=500,
        content={"detail": "Ichki server xatoligi", "type": type(exc).__name__},
    )
