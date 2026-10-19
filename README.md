# Milestone

A client portal for a software house. Every project walks through the five phases an agency sells,
**Discovery → Specification → Design → Development → Launch**, with a checklist per phase,
progress that the client can see, and a comment thread for questions.

Built in two days as a working answer to one question: *can you ship Flutter and NestJS?*

| | |
|---|---|
| **iOS app (TestFlight)** | _link below once the build clears Beta App Review_ |
| **API** | `https://API_URL_PLACEHOLDER` |
| **API docs (Swagger)** | `https://API_URL_PLACEHOLDER/docs` |
| **Demo account** | `demo@milestone.app` / `demo1234` |

## What it does

- Sign up or log in (JWT). A demo account is seeded with two projects so reviewers can look around in one tap.
- Create a project for a client: it starts with the five standard phases and their default tasks.
- Tick tasks off. When every task in a phase is done, the phase closes and the next one opens on its own.
- Progress per project, current phase, counts, all computed server-side and shown in the list and the detail.
- Comments per project, swipe to delete tasks, pull to refresh, light and dark theme.

## Stack

**`app/` — Flutter 3.47**

- Riverpod 3 (`Notifier` / `AsyncNotifier`, optimistic task toggles, invalidation across screens)
- go_router with an auth-aware redirect (splash → login → projects)
- Dio with a bearer interceptor; a 401 anywhere signs the user out
- `flutter_secure_storage` for the session token
- Material 3, no code generation, no third-party UI kit
- Base URL injected at build time: `--dart-define=API_URL=…`

**`api/` — NestJS 12 (ESM, strict TypeScript)**

- Modules: `auth` (Passport JWT, bcrypt), `users`, `projects` (projects, phases, tasks, comments), `health`
- TypeORM with SQLite (`better-sqlite3`); swap `DATABASE_PATH` or the driver for Postgres, the entities don't change
- `class-validator` DTOs with `whitelist` + `forbidNonWhitelisted`, Helmet, CORS, rate limiting (`@nestjs/throttler`)
- Swagger generated from the controllers at `/docs`
- Phase progression is a pure function (`projects/progress.ts`) with unit tests; an end-to-end test drives the API from register to a closed phase with supertest
- Seed service creates the demo account on an empty database
- Multi-stage Dockerfile, deployed on Cloud Run

## Run it locally

```bash
# API
cd api
npm ci
cp .env.example .env
npm run start:dev          # http://localhost:3000, docs at /docs
npm test && npm run test:e2e

# App (iOS simulator or Android emulator)
cd ../app
flutter pub get
flutter run --dart-define=API_URL=http://localhost:3000
```

On an Android emulator use `http://10.0.2.2:3000` as `API_URL`.

## API in one screen

| Method | Route | What |
|---|---|---|
| POST | `/auth/register` | Create an account, get a token |
| POST | `/auth/login` | Log in, get a token |
| GET | `/auth/me` | Who am I |
| GET | `/projects` | My projects with progress and current phase |
| POST | `/projects` | New project with the five phases |
| GET | `/projects/:id` | Phases, tasks, comments |
| PATCH | `/projects/:id` | Rename, describe, archive |
| DELETE | `/projects/:id` | Delete |
| POST | `/projects/:id/phases/:phaseId/tasks` | Add a task |
| PATCH | `/projects/:id/tasks/:taskId` | Rename or toggle a task |
| DELETE | `/projects/:id/tasks/:taskId` | Remove a task |
| POST | `/projects/:id/comments` | Comment |
| GET | `/health` | Liveness |

## Honest notes

- SQLite on Cloud Run keeps data for the life of the instance; a redeploy reseeds the demo. For a real client this is a Postgres connection string away.
- No refresh tokens, no password reset, no roles. The entities carry an `ownerId` and the service checks it on every route, so adding a `studio` role that sees every project is a guard, not a rewrite.
- Hebrew / RTL is not localised yet; the layout uses logical paddings and Material widgets, so it would mostly be strings.

## Author

Mathias Erligmann — [100-8.studio](https://100-8.studio) · [LinkedIn](https://linkedin.com/in/mathias-erligmann)
