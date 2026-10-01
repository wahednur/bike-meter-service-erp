#!/bin/sh
set -eu

# Dokploy injects configuration at runtime. Running migrations here keeps a
# normal deploy self-contained; set RUN_MIGRATIONS=false for worker replicas.
if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
    python manage.py migrate --noinput
fi

python manage.py collectstatic --noinput

exec "$@"
