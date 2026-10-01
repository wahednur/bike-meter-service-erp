# Production image for deploying the Django API as a Dokploy application.
FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=8000

WORKDIR /app

# psycopg2-binary normally needs no compiler. libpq is retained for runtime
# compatibility with PostgreSQL connection strings supplied by Dokploy.
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system django \
    && useradd --system --gid django django

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . ./
RUN chmod +x docker-entrypoint.sh \
    && mkdir -p /app/media /app/staticfiles \
    && chown -R django:django /app

USER django

EXPOSE 8000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--access-logfile", "-", "--error-logfile", "-"]
