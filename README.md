# Auth API

API d'authentification (email + Google/Facebook) basée sur Django, Django REST Framework, django-allauth et dj-rest-auth. Environnement dockerisé calqué sur le projet API existant.

## Prérequis
- Docker et Docker Compose
- Make (macOS: fourni par défaut)

## Ports
- API: http://localhost:8002
- Health check: http://localhost:8002/health/
- Admin Django: http://localhost:8002/admin/
- Postgres: localhost:5433 (host) -> 5432 (container)

## Démarrage rapide
1) Configurer l'environnement
- Copier/adapter `.env` (déjà créé) et renseigner au besoin:
  - DEBUG, SECRET_KEY, ALLOWED_HOSTS, SITE_ID
  - DB_HOST, DB_NAME, DB_USER, DB_PASS, DB_PORT
  - GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
  - FACEBOOK_APP_ID, FACEBOOK_APP_SECRET

2) Construire et lancer:
- make build
- make up

3) Migrations et superuser:
- make migrate
- make createsuperuser

4) Vérifier la santé:
- make health  # doit afficher OK

## Endpoints principaux
- Auth (dj-rest-auth): `/api/auth/`
- Registration (email): `/api/auth/registration/`
- Admin: `/admin/`
- Health: `/health/`

## Authentification sociale (Google/Facebook)
- Créez vos credentials chez les providers:
  - Google: OAuth client (Web), redirections typiques à configurer côté front (cette API échange les tokens)
  - Facebook: App ID / Secret
- Renseignez `.env`:
  - GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
  - FACEBOOK_APP_ID, FACEBOOK_APP_SECRET
- Seed des SocialApp depuis `.env`:
  - make seed
  - Idempotent: met à jour/lie au Site (SITE_ID) sans dupliquer

Vous pouvez aussi gérer manuellement via l'admin:
- /admin/socialaccount/socialapp/add/

## Makefile: commandes disponibles
- build: construire l'image web
- rebuild: reconstruire sans cache
- up / down / restart / ps / logs / web-logs / db-logs
- migrate / makemigrations APP=mon_app
- createsuperuser / shell / sh / manage CMD="..."
- test APP=mon_app
- collectstatic
- health
- dbshell / psql
- dumpdata FIXTURE=initial -> fixtures/initial.json
- loaddata FIXTURE=initial <- fixtures/initial.json
- db-reset / migrate-reset
- lint (ruff) / lint-fix / format (black)
- clean-pyc
- seed (création/mise à jour des SocialApp depuis .env)

## Structure Docker
- docker-compose.yml:
  - service db: postgres:15, volume `postgres_data`, port hôte 5433
  - service web: Django, port hôte 8002, monte le code local (`.:/code`), charge `.env`
- Dockerfile:
  - Python 3.11, installe les dépendances depuis `requirements.txt`

## Configuration Django
- Base de données: Postgres (paramétrée via `.env`)
- DRF + TokenAuth activés
- django-allauth: email-only (username désactivé), providers Google/Facebook inclus
- dj-rest-auth: endpoints d'auth et de registration exposés
- Sites Framework: SITE_ID paramétrable via `.env`

## Fixtures et reset DB
- Export: `make dumpdata FIXTURE=initial`
- Import: `make loaddata FIXTURE=initial`
- Reset complet: `make migrate-reset` (drop DB puis migrate)

## Développement: qualité
- Linter: `make lint` (ruff)
- Auto-fix: `make lint-fix`
- Formatage: `make format` (black)

## Notes
- La clé `version` de docker-compose est obsolète; ignorée par Compose. On peut la retirer plus tard.
- Des warnings de dépréciation allauth peuvent apparaître; on pourra migrer vers la nouvelle config (ACCOUNT_LOGIN_METHODS, ACCOUNT_SIGNUP_FIELDS) si souhaité.
