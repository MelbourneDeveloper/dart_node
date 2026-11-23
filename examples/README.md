# Full-Stack Dart Example

A task management app with both frontend and backend written entirely in Dart.

## Architecture

```
examples/
├── frontend/   → React UI (Dart → Browser JS)
├── backend/    → Express API (Dart → Node.js)
└── shared/     → Common models (User, Task)
```

## How They Connect

```
┌─────────────────┐         HTTP/JSON          ┌─────────────────┐
│    Frontend     │ ◄─────────────────────────►│     Backend     │
│  (Browser JS)   │    localhost:3000/api      │    (Node.js)    │
└─────────────────┘                            └─────────────────┘
        │                                               │
        └───────────────┬───────────────────────────────┘
                        ▼
                ┌───────────────┐
                │    Shared     │
                │  User, Task   │
                └───────────────┘
```

## API Endpoints

| Method | Path              | Auth | Description           |
|--------|-------------------|------|-----------------------|
| POST   | /auth/register    | No   | Create account        |
| POST   | /auth/login       | No   | Get auth token        |
| GET    | /tasks            | Yes  | List user's tasks     |
| POST   | /tasks            | Yes  | Create task           |
| GET    | /tasks/:id        | Yes  | Get single task       |
| PUT    | /tasks/:id        | Yes  | Update task           |
| DELETE | /tasks/:id        | Yes  | Delete task           |

Auth: `Authorization: Bearer <token>`

## Quick Start

```bash
# 1. Build and run backend
dart run tools/build/build.dart backend
cd examples/backend && npm install && node build/server.js

# 2. Build and serve frontend (separate terminal)
dart run tools/build/build.dart frontend
cd examples/frontend && npx serve web
```

Frontend runs at `http://localhost:3000` (or whatever port serve picks).
Backend API at `http://localhost:3000`.

## Shared Package

Both frontend and backend depend on `shared/` which contains:

- `User` - user record with id, email, name, role
- `Task` - task record with id, title, completed, priority
- `CreateUserData`, `LoginData` - auth request types
- `CreateTaskData`, `UpdateTaskData` - task request types

This eliminates duplication and ensures type consistency across the stack.
