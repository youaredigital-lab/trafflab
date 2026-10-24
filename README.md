# TrafficLab

Платформа обучения и операционной работы арбитражной команды: уроки с видео, квизами и ДЗ, записи митов, офферы и предложения офферов от учеников, тесты офферов, дневник медиабайера, заявки (аккаунты, **карты**, креативы, обращения, созвоны), тикеты с SLA, Trust Level и админка. Чёрный интерфейс.

**Стек:** FastAPI · SQLAlchemy 2 (async) · Alembic · PostgreSQL 16 · React 18 · Vite · TypeScript · TanStack Query · Tailwind · nginx · Docker Compose · GitHub Actions.

---

## Быстрый старт (Docker)

Нужны Docker 24+ и Docker Compose v2.

```bash
cp .env.example .env            # при желании поменяйте пароли и SECRET_KEY
make up                         # или: docker compose up -d --build
make seed                       # стартовые уроки, офферы и демо-пользователи
```

Откройте **http://localhost:8080**. Документация API — http://localhost:8080/api/docs.

| Демо-пользователь | Пароль | Роль |
| --- | --- | --- |
| `admin@trafficlab.dev` | `trafficlab123` | администратор |
| `curator@trafficlab.dev` | `trafficlab123` | куратор |
| `student@trafficlab.dev` | `trafficlab123` | ученик |

Пароль задаётся `SEED_DEMO_PASSWORD` в `.env`. Новые пользователи регистрируются как ученики; роли выдаёт админ в разделе «Админка».

Что поднимается:

| Сервис | Что делает |
| --- | --- |
| `db` | PostgreSQL 16, данные в volume `pgdata` |
| `backend` | FastAPI; при старте применяет миграции; видео в volume `media` |
| `frontend` | nginx: статика React, проксирование `/api` в backend, большие загрузки потоком |

Полезное: `make logs`, `make ps`, `make down`, `make shell-db`, `make clean` (удалит БД и видео).

## Тесты

```bash
make test             # бэкенд (ruff + pytest на отдельном Postgres) и фронтенд (tsc + vitest) в Docker
make smoke            # сквозная проверка запущенного приложения через nginx
```

Без Docker — `docs/local-dev.md`.

## CI/CD

`.github/workflows/ci.yml` на каждый push и pull request:

1. **Backend** — ruff, миграции вверх/вниз/вверх и проверка расхождения моделей (`alembic check`), идемпотентность сида, pytest на Postgres.
2. **Frontend** — `tsc`, vitest, production-сборка.
3. **Docker Compose · smoke** — поднимает весь стек `docker compose up --wait`, сидирует и прогоняет `scripts/smoke.sh`.
4. **Images** — при push в `main` или тег `v*` собирает и публикует образы `ghcr.io/<owner>/trafficlab-backend` и `-frontend` (теги `sha-…`, `latest`, версия).

`.github/workflows/deploy.yml` — ручной деплой выбранного тега на сервер по SSH (см. `docs/deploy.md`).

## Структура

```
CLAUDE.md, .claude/rules/   архитектура, бизнес-логика, контракт API, соглашения
backend/                    FastAPI: app/core, app/models, app/modules/<домен>, alembic, tests
frontend/                   React: src/pages/<домен>, src/api, src/components, src/lib
docker-compose*.yml         локально, тесты, прод
scripts/smoke.sh            сквозная проверка
```

Бизнес-правила (роли, Trust Level, статусы, права) описаны в `.claude/rules/business-logic.md` и проверяются на бэкенде тестами.
