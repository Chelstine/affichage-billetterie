# Tableau de Bord Billetterie

Dashboard Node.js/Express pour afficher les donnees de billetterie Airtable, proteger l'acces par mot de passe, et declencher des actions de backup/restauration via webhook.

## Stack

- Node.js 18+
- Express
- Frontend statique servi par `server.js`
- Airtable appele uniquement depuis le serveur
- Webhooks n8n optionnels pour backup, restauration et recuperation

## Configuration

Copie `.env.example` vers `.env` en local ou `.env.production` sur le VPS.

Variables minimales:

- `DASHBOARD_PASSWORD`
- `AIRTABLE_API_KEY`
- `AIRTABLE_BASE_ID`
- `AIRTABLE_TABLE_NAME`

Variables optionnelles:

- `AIRTABLE_VIEW_NAME`
- `AIRTABLE_TECHNICAL_TABLE_NAME`
- `AIRTABLE_TECHNICAL_PARAM_FIELD`
- `AIRTABLE_TECHNICAL_VALUE_FIELD`
- `AIRTABLE_TECHNICAL_LAST_SYNC_PARAM`
- `N8N_RESTORE_WEBHOOK_URL`
- `N8N_RESTORE_WEBHOOK_METHOD`
- `N8N_RECOVERY_FEVER_WEBHOOK_URL`
- `N8N_RECOVERY_FEVER_WEBHOOK_METHOD`
- `N8N_BACKUP_WEBHOOK_URL`
- `N8N_BACKUP_WEBHOOK_METHOD`

Variables en plus pour le deploiement VPS:

- `APP_DOMAIN`
- `LETSENCRYPT_CA` 

## Lancement local

```bash
npm install
npm start
```

Puis ouvre `http://localhost:3000`.

Authentification:

- utilisateur: `admin`
- mot de passe: valeur de `DASHBOARD_PASSWORD`

## Deploiement VPS

Le chemin recommande est `Docker Compose + Caddy`.

- Guide complet: `DEPLOY_VPS.md`
- Configuration proxy HTTPS: `deploy/caddy/Caddyfile`
- Script de redeploiement: `scripts/deploy-vps.sh`

## Notes de securite

- Les secrets Airtable restent cote serveur.
- Le navigateur consomme uniquement les routes `/api/*`.
- Un endpoint `GET /healthz` est disponible pour la supervision.
