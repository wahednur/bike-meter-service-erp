#!/usr/bin/env bash
# Render build script: install deps, run migrations, collect static files.
# Migrate runs before collectstatic so a static-file problem can never (via
# `set -o errexit`) block the database from getting migrated.
set -o errexit

pip install -r requirements.txt

python manage.py migrate

python manage.py collectstatic --no-input
