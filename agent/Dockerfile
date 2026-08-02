# NUR Agent — Instagram AI sotuv agenti (alohida image, ERP'ga tegmaydi)
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Avval kutubxonalar (layer keshi uchun)
COPY requirements.txt ./
RUN pip install -r requirements.txt

# Ilova kodi (dev'da volume bilan ulanadi, prod'da image ichida "baked")
COPY . .

EXPOSE 8000

# Prod: --workers 2. Webhook Meta 5 soniya ichida javob kutadi — og'ir ish
# BackgroundTasks'ga topshiriladi, shuning uchun ikki worker yetarli.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
