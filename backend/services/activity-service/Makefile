COMPOSE_FILE=deploy/docker-compose.yml
DOCKER_COMPOSE=docker compose -f $(COMPOSE_FILE)

.PHONY: up down restart logs ps build rebuild \
        activity-up activity-down activity-restart activity-logs activity-build activity-rebuild \
        activity-db-logs activity-db-shell activity-shell

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

restart:
	$(DOCKER_COMPOSE) restart

logs:
	$(DOCKER_COMPOSE) logs -f

ps:
	$(DOCKER_COMPOSE) ps

build:
	$(DOCKER_COMPOSE) build

rebuild:
	$(DOCKER_COMPOSE) build --no-cache

activity-up:
	$(DOCKER_COMPOSE) up -d activity-postgres activity-service

activity-down:
	$(DOCKER_COMPOSE) stop activity-service activity-postgres

activity-restart:
	$(DOCKER_COMPOSE) restart activity-service

activity-logs:
	$(DOCKER_COMPOSE) logs -f activity-service

activity-db-logs:
	$(DOCKER_COMPOSE) logs -f activity-postgres

activity-build:
	$(DOCKER_COMPOSE) build activity-service

activity-rebuild:
	$(DOCKER_COMPOSE) build --no-cache activity-service

activity-shell:
	$(DOCKER_COMPOSE) exec activity-service sh

activity-db-shell:
	$(DOCKER_COMPOSE) exec activity-postgres psql -U inflap -d activity_service_db