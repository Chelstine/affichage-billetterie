#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ENV_FILE="${ENV_FILE:-.env.production}"
BRANCH="${BRANCH:-}"
COMPOSE_CMD="${COMPOSE_CMD:-docker compose}"

cd "$APP_DIR"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Fichier $ENV_FILE introuvable. Copie .env.example vers $ENV_FILE puis renseigne les variables." >&2
    exit 1
fi

if [[ -n "$BRANCH" && -d .git ]]; then
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
    git pull --ff-only origin "$BRANCH"
fi

export APP_ENV_FILE="$ENV_FILE"

$COMPOSE_CMD --env-file "$ENV_FILE" config >/dev/null
$COMPOSE_CMD --env-file "$ENV_FILE" up -d --build --remove-orphans
$COMPOSE_CMD --env-file "$ENV_FILE" ps
