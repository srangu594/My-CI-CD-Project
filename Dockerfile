# ── Stage 1: Build & Test ──────────────────────────────────────────
FROM python:3.11-slim AS builder
 
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
COPY tests/ ./tests/
 
# Run tests during build — fail fast if tests fail
RUN python -m pytest tests/ -v --tb=short
 
# ── Stage 2: Production image ───────────────────────────────────────
FROM python:3.11-slim AS production
 
# Security: run as non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
 
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
 
COPY app/ .
RUN chown -R appuser:appuser /app
 
USER appuser
 
EXPOSE 5000
 
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3     CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"
 
ENV FLASK_ENV=production
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
 
CMD ["python", "app.py"]