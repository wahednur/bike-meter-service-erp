# Dokploy/Docker production image (ARCHITECTURE §13 Decision Log —
# supersedes the earlier bare-metal systemd+Gunicorn plan). One image, three
# roles depending on the CMD Dokploy is told to run: the API+WebSocket app
# (Daphne, config/asgi.py's ProtocolTypeRouter already serves both HTTP and
# /ws/ through one ASGI app — no separate Gunicorn process), the Celery
# worker, and Celery beat. See docs/DOKPLOY-DEPLOY.md for how each is wired
# up as its own Dokploy application.
#
# Multi-stage: the builder stage's compiler toolchain (gcc/libpq-dev, a
# safety net for any dependency without a prebuilt wheel) never ships in
# the final image — only the populated venv + app code do.

FROM python:3.14-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements/ requirements/
RUN pip install --no-cache-dir -r requirements/prod.txt

FROM python:3.14-slim

# libpq5 only (runtime client lib, no compiler/headers) — psycopg[binary]
# bundles its own libpq internally already; kept as a safety net, not a
# hard requirement, same reasoning as the builder stage's own extras.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r django && useradd -r -g django django

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=config.settings.prod

COPY . .
RUN chmod +x docker-entrypoint.sh \
    && mkdir -p staticfiles \
    && chown -R django:django /app

USER django

EXPOSE 8000

ENTRYPOINT ["./docker-entrypoint.sh"]
# Default role: API + WebSocket. Override CMD per Dokploy app for the
# Celery worker/beat roles — see docs/DOKPLOY-DEPLOY.md.
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "config.asgi:application"]
