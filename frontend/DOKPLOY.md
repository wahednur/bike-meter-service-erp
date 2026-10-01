# Dokploy deployment (frontend)

Create a second **Docker** application in Dokploy using this repository.
This is separate from the Django backend application.

## Build and domain

- **Build path / context:** `frontend`
- **Dockerfile:** `Dockerfile`
- **Container port:** `3000`
- **Health check path:** `/api/health/`
- Attach the frontend domain, for example `meter.example.com`.

## Required environment variable

Set this in Dokploy's normal **Environment Variables** section:

```dotenv
API_BASE_URL=https://mapi.example.com/api
```

For this project, use:

```dotenv
API_BASE_URL=https://mapi.wahednur.tech/api
```

The container generates its browser runtime configuration at startup, so this
works on Dokploy versions that do not offer a Build Arguments section.

## Backend CORS setting

The backend application's environment variables must allow the frontend:

```dotenv
CORS_ALLOWED_ORIGINS=https://meter.example.com
CSRF_TRUSTED_ORIGINS=https://mapi.example.com,https://meter.example.com
```

Use the actual domains you attach in Dokploy. `ALLOWED_HOSTS` on the backend
must still include its API hostname only, such as `mapi.example.com`.
