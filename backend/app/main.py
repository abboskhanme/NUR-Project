"""NurBunker ERP/CRM — FastAPI application entrypoint."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.api.v1 import api_router
from app.core.config import settings
from app.core.exceptions import global_exception_handler


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"[{settings.APP_NAME}] starting in {settings.APP_ENV} mode")
    yield
    logger.info(f"[{settings.APP_NAME}] shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="NUR TECHNO GROUP — ichki ERP/CRM tizimi",
    version="0.1.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global exception handler (only outside of debug)
if not settings.DEBUG:
    app.add_exception_handler(Exception, global_exception_handler)


@app.get("/", tags=["health"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": "0.1.0",
        "env": settings.APP_ENV,
        "docs": "/api/docs",
    }


@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "ok"}


# API v1 routers
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
