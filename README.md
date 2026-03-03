# SplitLLM — Flutter Web

Production-grade Flutter Web rewrite of the SplitLLM React frontend. Features Firebase Authentication, Riverpod state management, and Dio-based API integration with the existing Flask backend.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Web + Android + iOS) |
| State Management | Riverpod |
| Routing | go_router |
| HTTP Client | Dio |
| Auth | Firebase Authentication |
| Charts | fl_chart |
| Hosting | Firebase Hosting |
| CI/CD | GitHub Actions |

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)

### 1. Clone & Install

```bash
cd flutter-app
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** → Sign-in methods:
   - Email/Password
   - Google
3. Enable **Hosting**
4. Configure Flutter:

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart` with your real config.

5. Update `.firebaserc`:
```json
{
  "projects": {
    "default": "YOUR_PROJECT_ID"
  }
}
```

### 3. Run Locally

```bash
# Development (default API: http://localhost:5000)
flutter run -d chrome

# With custom API URL
flutter run -d chrome --dart-define=API_BASE_URL=https://your-api.domain.com
```

### 4. Build for Production

```bash
flutter build web \
  --release \
  --dart-define=API_BASE_URL=https://your-api.domain.com \
  --web-renderer html \
  --tree-shake-icons
```

### 5. Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

## GitHub Actions (CI/CD)

Automatic deployment on push to `main`. Set these GitHub Secrets:

| Secret | Description |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON key |
| `PROJECT_ID` | Firebase project ID |
| `API_BASE_URL` | Production API base URL |

Generate the service account key:
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Copy the full JSON content into the `FIREBASE_SERVICE_ACCOUNT` secret

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp.router
├── firebase_options.dart              # Firebase config (generated)
├── core/
│   ├── constants/constants.dart       # API URL, app constants
│   ├── models/                        # Data models
│   │   ├── user_model.dart
│   │   ├── event_model.dart
│   │   ├── expense_model.dart
│   │   ├── share_model.dart
│   │   └── filter_input_model.dart
│   ├── services/
│   │   ├── api_client.dart            # Dio + Firebase token interceptor
│   │   └── auth_service.dart          # Firebase Auth abstraction
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

Build with `--dart-define` for different environments:

```bash
# Development
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000

# Staging
flutter build web --dart-define=API_BASE_URL=https://staging-api.domain.com

# Production
flutter build web --dart-define=API_BASE_URL=https://api.domain.com
```

## Backend Integration

The Flutter app sends `Authorization: Bearer <firebase_id_token>` in all API requests. Your Flask backend must be updated to validate Firebase ID tokens:

```python
# pip install firebase-admin
import firebase_admin
from firebase_admin import auth as firebase_auth

firebase_admin.initialize_app()

def verify_firebase_token(id_token):
    decoded = firebase_auth.verify_id_token(id_token)
    return decoded['uid'], decoded['email']
```

## Migration Checklist

- [x] Analyze React repository
- [x] Create Flutter project structure
- [x] Core infrastructure (Dio, Firebase Auth, Riverpod, go_router)
- [x] Data models (User, Event, Expense, Share, FilterInput)
- [x] Auth feature (Login, Sign-up, Google Sign-In, Forgot Password)
- [x] Dashboard (Summary cards, Pie chart, Quick actions)
- [x] Events (List, Detail, Create/Edit, Delete)
- [x] Expenses (Create/Edit, Detail, Share Bill)
- [x] Friends (List, Detail, Add, Delete, Settle)
- [x] Personal Expenses (List, LLM Chatbot)
- [x] Account (Profile, QR Code, UPI, Change Password, Sign Out)
- [x] Payment page (Public payment with QR)
- [x] Firebase config (firebase.json, .firebaserc)
- [x] GitHub Actions CI/CD workflow
- [ ] Run `flutterfire configure` (manual step)
- [ ] Update Flask backend to validate Firebase tokens
- [ ] Set GitHub Secrets for deployment
