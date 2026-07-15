# SplitLLM — Flutter Web

Smart expense-splitting app built with Flutter Web, featuring Supabase Authentication, Riverpod state management, LLM-powered natural language expense parsing, and a FastAPI backend.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Web + Android + iOS) |
| State Management | Riverpod |
| Routing | go_router |
| HTTP Client | Dio |
| Auth | Supabase Authentication |
| Config | flutter_dotenv (`.env`) |
| Charts | fl_chart |
| Hosting / CI | Vercel |

## Features

- **Dashboard** — Summary cards, pie charts, quick actions
- **Events** — Create, view, edit, delete group events
- **Expenses** — Add expenses, split bills, track who owes what
- **Friends** — Add friends by code, view balances, settle up
- **Personal Expenses** — Track personal spending with LLM chatbot parsing
- **Account** — Profile management, QR code, UPI payment links
- **Payments** — Public payment page with QR code

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.2.0

### 1. Clone & Install

```bash
cd flutter-app
flutter pub get
```

### 2. Configure environment

Runtime configuration lives in a `.env` file (loaded at startup via `flutter_dotenv`). Copy the template and fill in your values:

```bash
cp .env.example .env
```

```dotenv
# .env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=sb_publishable_xxx        # publishable/anon key — safe in client
API_BASE_URL=http://localhost:8081
```

`.env` is git-ignored. To change Supabase or the backend URL later, just edit `.env`
(local) or the Vercel Environment Variables (production) — no Dart code changes needed.

> Resolution order for each value: `.env` → `--dart-define=KEY=value` → built-in default.

### 3. Run Locally

```bash
flutter run -d chrome
```

`.env` is picked up automatically. You can still override per-run with
`--dart-define=API_BASE_URL=https://your-api.domain.com` if you prefer.

### 4. Build for Production

```bash
flutter build web --release --tree-shake-icons
```

Output is written to `build/web`.

## Deployment (Vercel)

The app deploys to Vercel via [`vercel.json`](./vercel.json) + [`vercel_build.sh`](./vercel_build.sh).
Because Vercel's build image has no Flutter SDK, the build script installs Flutter,
writes a `.env` from the project's Environment Variables, then runs `flutter build web`.

**Setup:**

1. Import the repository into Vercel (Root Directory = `flutter-app`).
2. Vercel reads `vercel.json` automatically:
   - Build command: `bash vercel_build.sh`
   - Output directory: `build/web`
3. In **Project Settings → Environment Variables**, add:

   | Variable | Description |
   |---|---|
   | `SUPABASE_URL` | Supabase project URL |
   | `SUPABASE_ANON_KEY` | Supabase publishable / anon key |
   | `API_BASE_URL` | Production backend API base URL |

4. Push to your default branch — Vercel builds and deploys automatically.

`vercel.json` also configures SPA rewrites (all routes → `index.html`) and security
headers (`X-Frame-Options`, `Strict-Transport-Security`, etc.).

## Project Structure

```
lib/
├── main.dart                          # Entry point (loads .env, inits Supabase)
├── app.dart                           # MaterialApp.router
├── core/
│   ├── constants/constants.dart       # Config resolved from .env / dart-define
│   ├── models/                        # Data models
│   │   ├── user_model.dart
│   │   ├── event_model.dart
│   │   ├── expense_model.dart
│   │   ├── share_model.dart
│   │   └── filter_input_model.dart
│   ├── services/
│   │   ├── api_client.dart            # Dio + Supabase token interceptor
│   │   └── auth_service.dart          # Supabase Auth abstraction
│   ├── router/router.dart             # go_router with auth guard
│   ├── providers.dart                 # Top-level Riverpod providers
│   ├── utils/
│   │   ├── app_theme.dart             # Material 3 dark theme
│   │   ├── date_utils.dart            # Date formatting
│   │   └── helpers.dart               # Utilities
│   └── widgets/shell_screen.dart      # Responsive nav shell
└── features/
    ├── auth/presentation/login_screen.dart
    ├── dashboard/presentation/dashboard_screen.dart
    ├── events/presentation/
    │   ├── events_screen.dart
    │   ├── event_detail_screen.dart
    │   └── create_event_screen.dart
    ├── expenses/presentation/
    │   ├── create_expense_screen.dart
    │   ├── expense_detail_screen.dart
    │   └── share_bill_screen.dart
    ├── friends/presentation/
    │   ├── friends_screen.dart
    │   ├── friend_detail_screen.dart
    │   └── add_friend_screen.dart
    ├── personal_expenses/presentation/
    │   └── personal_expenses_screen.dart
    ├── account/presentation/account_screen.dart
    └── settlements/presentation/payment_screen.dart
```

## Environment Configuration

All runtime config (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL`) is resolved
at startup, in order of precedence:

1. the bundled `.env` file (`flutter_dotenv`),
2. a compile-time `--dart-define=KEY=value`,
3. a built-in default.

```bash
# Local dev: values come from .env
flutter run -d chrome

# Override a single value at build time
flutter build web --release --dart-define=API_BASE_URL=https://api.domain.com

# Production: Vercel injects env vars → vercel_build.sh writes them into .env
```

## Backend Integration

The Flutter app sends `Authorization: Bearer <supabase_access_token>` in all API
requests. The FastAPI backend validates the Supabase JWT against the project's JWKS
endpoint and reads the user id from the `sub` claim.

## Deployment (Zoho Catalyst Web Hosting)

The web app is hosted on Catalyst in project **SplitLLM** (`46831000000013050`,
org `60078340202`, IN DC) and served under `/app/`:
`https://splitllm-60078340202.development.catalystserverless.in/app/index.html`.

```bash
catalyst project:use SplitLLM --org 60078340202   # one-time binding
sh scripts/build_client.sh                        # flutter build web -> client/
catalyst deploy                                   # ships client/
```

Notes:

- **`--base-href /app/` is mandatory** (already in `scripts/build_client.sh`)
  because Catalyst serves the client under `/app/`; without it the page spins
  forever on a 404'd bootstrap JS. Re-check this if/when a custom domain or
  production mapping changes the serving path.
- Dart-defines (`API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`) come from
  `.env` locally; CI passes them from GitHub Actions variables.
- CI deploys automatically on push to `main` (see
  `.github/workflows/deploy.yml`; needs the `CATALYST_TOKEN` repo secret from
  `catalyst token:generate`).
- The API lives in a separate AppSail service — see the
  `github.com/splitllmbill/backend` repo.
