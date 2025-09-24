.PHONY: help build rebuild up down restart ps logs web-logs db-logs migrate makemigrations createsuperuser shell sh manage test collectstatic health dbshell psql dumpdata loaddata db-reset migrate-reset lint lint-fix format clean-pyc seed

COMPOSE := docker compose
WEB := web
DB := db
PORT := 8002

# DB credentials must match docker-compose.yml
DB_NAME := auth_api
DB_USER := auth_user
PGPASSWORD := auth_pass

# Fixtures
FIXTURES_DIR := fixtures
FIXTURE := initial

help:
	@echo "Make targets disponibles:"
	@echo "  build             - Construire l'image web"
	@echo "  rebuild           - Reconstruire sans cache"
	@echo "  up                - Démarrer les services (detached)"
	@echo "  down              - Arrêter et supprimer les services"
	@echo "  restart           - Redémarrer le service web"
	@echo "  ps                - Statut des services"
	@echo "  logs              - Logs du service web (suivi)"
	@echo "  web-logs          - Alias de logs"
	@echo "  db-logs           - Logs de Postgres (suivi)"
	@echo "  migrate           - Appliquer les migrations"
	@echo "  makemigrations    - Créer des migrations (APP=mon_app)"
	@echo "  createsuperuser   - Créer un superuser interactif"
	@echo "  shell             - Ouvrir manage.py shell"
	@echo "  sh                - Shell bash dans le conteneur web"
	@echo "  manage            - Exécuter manage.py avec CMD='...'"
	@echo "  test              - Lancer les tests (APP=mon_app)"
	@echo "  collectstatic     - Collecter les fichiers statiques"
	@echo "  health            - Vérifier l'endpoint de santé"
	@echo "  dbshell           - Ouvrir dbshell via Django"
	@echo "  psql              - Ouvrir psql sur la base"
	@echo "  dumpdata          - Exporter les données vers $(FIXTURES_DIR)/$(FIXTURE).json"
	@echo "  loaddata          - Importer les données depuis $(FIXTURES_DIR)/$(FIXTURE).json"
	@echo "  db-reset          - Drop & recreate la base Postgres"
	@echo "  migrate-reset     - db-reset puis migrate"
	@echo "  lint              - Ruff check"
	@echo "  lint-fix          - Ruff check --fix"
	@echo "  format            - Black sur le code"
	@echo "  clean-pyc         - Supprimer les fichiers *.pyc/__pycache__"
	@echo "  seed              - Créer/mettre à jour les SocialApp (Google/Facebook) depuis .env"

build:
	$(COMPOSE) build

rebuild:
	$(COMPOSE) build --no-cache

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart $(WEB)

ps:
	$(COMPOSE) ps

logs: web-logs

web-logs:
	$(COMPOSE) logs -f --tail=200 $(WEB)

db-logs:
	$(COMPOSE) logs -f --tail=200 $(DB)

migrate:
	$(COMPOSE) exec $(WEB) python manage.py migrate

makemigrations:
	$(COMPOSE) exec $(WEB) python manage.py makemigrations $(APP)

createsuperuser:
	$(COMPOSE) exec $(WEB) python manage.py createsuperuser

shell:
	$(COMPOSE) exec $(WEB) python manage.py shell

sh:
	$(COMPOSE) exec $(WEB) bash

manage:
ifndef CMD
	$(error Veuillez fournir CMD, ex: make manage CMD="showmigrations")
endif
	$(COMPOSE) exec $(WEB) python manage.py $(CMD)

test:
	$(COMPOSE) exec $(WEB) python manage.py test $(APP)

collectstatic:
	$(COMPOSE) exec $(WEB) python manage.py collectstatic --noinput

health:
	@curl -fsS http://localhost:$(PORT)/health/ > /dev/null && echo "OK" || (echo "KO" && exit 1)

dbshell:
	$(COMPOSE) exec $(WEB) python manage.py dbshell

psql:
	$(COMPOSE) exec -e PGPASSWORD=$(PGPASSWORD) $(DB) psql -U $(DB_USER) -d $(DB_NAME)

# Fixtures
$(FIXTURES_DIR):
	@mkdir -p $(FIXTURES_DIR)

dumpdata: $(FIXTURES_DIR)
	# Redirection sur l'hôte; -T pour désactiver le tty
	$(COMPOSE) exec -T $(WEB) python manage.py dumpdata --natural-foreign --natural-primary --indent 2 > $(FIXTURES_DIR)/$(FIXTURE).json

loaddata:
	$(COMPOSE) exec $(WEB) python manage.py loaddata $(FIXTURES_DIR)/$(FIXTURE).json

# Reset DB (termine les connexions actives, drop puis recreate)
db-reset:
	$(COMPOSE) exec -e PGPASSWORD=$(PGPASSWORD) $(DB) psql -U $(DB_USER) -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$(DB_NAME)' AND pid <> pg_backend_pid();"
	$(COMPOSE) exec -e PGPASSWORD=$(PGPASSWORD) $(DB) dropdb -U $(DB_USER) --if-exists $(DB_NAME)
	$(COMPOSE) exec -e PGPASSWORD=$(PGPASSWORD) $(DB) createdb -U $(DB_USER) $(DB_NAME)

migrate-reset: db-reset migrate

# Qualité code
lint:
	$(COMPOSE) exec $(WEB) ruff check .

lint-fix:
	$(COMPOSE) exec $(WEB) ruff check . --fix

format:
	$(COMPOSE) exec $(WEB) black .

clean-pyc:
	find . -name "*.pyc" -delete -o -name "*.pyo" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +

seed:
	$(COMPOSE) exec $(WEB) python manage.py seed_social
