FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

WORKDIR /app

COPY requirements_fastapi.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements_fastapi.txt

COPY . .

CMD ["sh", "-c", "uvicorn app_fastapi:socket_app --host 0.0.0.0 --port ${PORT:-8080} --log-level info"]