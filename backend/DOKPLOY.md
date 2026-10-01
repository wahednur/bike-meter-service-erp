# Dokploy deployment (backend only)

Create a **Docker** application in Dokploy from this repository.

## Build and networking

- **Build path / context:** `backend`
- **Dockerfile:** `backend/Dockerfile` (or `Dockerfile` when Dokploy's build
  path is `backend`)
- **Container port:** `8000`
- **Health check path:** `/healthz/`

Attach the application's public domain, for example `api.example.com`. Do not
publish port 8000 directly to the Internet; Dokploy's proxy should route the
domain to it.

## Persistent storage

Add a Dokploy volume mounted at `/app/media`. Uploaded meter, product, asset,
and receipt files are stored there. Without this volume they are lost whenever
the container is redeployed.

Static files are collected at startup and served by WhiteNoise, so they do not
need a persistent volume.

## Environment variables

Set these in the Dokploy application, never in the Dockerfile or repository:

```dotenv
DEBUG=False
SECRET_KEY=<a-long-random-secret>
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DBNAME?sslmode=require
DATABASE_SSL_REQUIRE=False
ALLOWED_HOSTS=api.example.com
CORS_ALLOWED_ORIGINS=https://app.example.com
CSRF_TRUSTED_ORIGINS=https://api.example.com,https://app.example.com
TRUST_X_FORWARDED_HEADERS=True
RUN_MIGRATIONS=true
```

`ALLOWED_HOSTS` contains hostnames only (no `https://`), while CORS and CSRF
values are full origins and must use `https://`. Use comma-separated values
when more than one frontend domain is allowed.

For a database deployed through Dokploy, use that database service's internal
Postgres connection URL and set `DATABASE_SSL_REQUIRE=False`: the internal
Postgres service does not provide TLS. For Neon or another managed database,
use its TLS connection URL and set `DATABASE_SSL_REQUIRE=True`.

## First deployment

Deploy once, confirm `/healthz/` returns `ok`, then create the initial admin:

```sh
python manage.py createsuperuser
```

Run that command in Dokploy's application terminal. The entrypoint automatically
runs migrations and collects static files on every normal API deploy.
