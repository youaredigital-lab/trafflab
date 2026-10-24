-include .env
export

COMPOSE      = docker compose
COMPOSE_TEST = docker compose -f docker-compose.test.yml

.PHONY: help env up down logs ps seed migrate shell-db test test-backend test-frontend lint smoke e2e clean

help:            ## Список команд
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-15s %s\n", $$1, $$2}'

env:             ## Создать .env из примера (если его нет)
	@test -f .env || cp .env.example .env

up: env          ## Собрать и запустить приложение → http://localhost:8080
	$(COMPOSE) up -d --build
	@echo "Готово: http://localhost:$${APP_PORT:-8080}  (API: /api/docs). Контент: make seed"

down:            ## Остановить
	$(COMPOSE) down

logs:            ## Логи всех сервисов
	$(COMPOSE) logs -f --tail=100

ps:
	$(COMPOSE) ps

seed:            ## Стартовый контент и демо-пользователи (admin@/curator@/student@trafficlab.dev)
	$(COMPOSE) exec backend python -m app.seed --demo

migrate:         ## Применить миграции вручную
	$(COMPOSE) exec backend alembic upgrade head

shell-db:        ## psql в базе
	$(COMPOSE) exec db sh -c 'psql -U $$POSTGRES_USER -d $$POSTGRES_DB'

test: test-backend test-frontend   ## Все тесты в Docker

test-backend:    ## Линт + pytest бэкенда в Docker
	$(COMPOSE_TEST) run --rm --build backend-test; rc=$$?; $(COMPOSE_TEST) down -v; exit $$rc

test-frontend:   ## Типы + vitest фронтенда в Docker
	$(COMPOSE_TEST) run --rm --build frontend-test

lint:            ## Линтеры локально (без Docker)
	cd backend && ruff check . && ruff format --check .
	cd frontend && npm run lint

smoke:           ## Сквозная проверка запущенного приложения
	./scripts/smoke.sh http://localhost:$${APP_PORT:-8080}

e2e:             ## Браузерные E2E-тесты (Playwright) против запущенного приложения
	cd e2e && npm ci && npx playwright install chromium && E2E_BASE_URL=http://localhost:$${APP_PORT:-8080} npm test

clean:           ## Остановить и удалить данные (БД и видео!)
	$(COMPOSE) down -v
