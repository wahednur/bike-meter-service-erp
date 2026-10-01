# Dokploy deployment (frontend)

Create a second **Docker** application in Dokploy using this repository.
This is separate from the Django backend application.

## Build and domain

- **Build path / context:** `frontend`
- **Dockerfile:** `Dockerfile`
- **Container port:** `3000`
- **Health check path:** `/api/health/`
- Attach the frontend domain, for example `meter.example.com`.

## Required build argument

Set this in Dokploy's **Build Arguments** before deploying:

```dotenv
NEXT_PUBLIC_API_BASE_URL=https://mapi.example.com/api
```

For this project, use:

```dotenv
NEXT_PUBLIC_API_BASE_URL=https://mapi.wahednur.tech/api
```

This is a build argument because `NEXT_PUBLIC_*` values are compiled into the
JavaScript sent to browsers. Changing it requires a new frontend deployment.

## Backend CORS setting

The backend application's environment variables must allow the frontend:

```dotenv
CORS_ALLOWED_ORIGINS=https://meter.example.com
CSRF_TRUSTED_ORIGINS=https://mapi.example.com,https://meter.example.com
```

Use the actual domains you attach in Dokploy. `ALLOWED_HOSTS` on the backend
must still include its API hostname only, such as `mapi.example.com`.
