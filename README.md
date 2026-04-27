# Red Shop

Red Shop is a Flutter + Firebase shop management app for small retail workflows.
It includes owner and clerk roles, inventory management, sales/POS, restocking,
expenses, and dashboard reporting.

## Core Features

- Firebase email/password authentication
- Role-based access (`owner`, `clerk`)
- First-time owner registration flow
- Product inventory tracking (stock, cost, suggested selling price)
- POS sales with stock deduction and profit calculation
- Restocking/purchase recording with average-cost recalculation
- Expense tracking (operating + withdrawal)
- Dashboard summary (revenue, profit, low stock, top sellers)
- English/Amharic language support
- Developer cheatsheet preview screens for fast UI checks

## Tech Stack

- Flutter (Material)
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Provider (state management)

## Project Structure

```text
lib/
  localization/        # app language + strings
  models/              # domain models and dashboard aggregation
  providers/           # app-level state providers
  screens/
    auth/              # login/register
    owner/             # owner workflows
    clerk/             # clerk home
    pos/               # point-of-sale flow
    dev/               # cheatsheet preview UIs
  services/            # Firebase auth + shop data logic
  theme/               # app theme + style tokens
  widgets/             # shared UI widgets
```

## Prerequisites

- Flutter SDK installed
- Dart SDK compatible with this project (`sdk: ^3.9.2` in `pubspec.yaml`)
- Firebase project configured for your target platform(s)

## Setup

1. Install dependencies:

```bash
flutter pub get
```

2. Configure Firebase (if not already configured for your machine/project):

- Create a Firebase project
- Enable **Authentication > Email/Password**
- Create **Cloud Firestore** database
- Generate platform config using FlutterFire CLI (recommended)

3. Run the app:

```bash
flutter run
```

## Firestore Collections Used

- `users`
- `products`
- `sales`
- `purchases`
- `expenses`

## Development Preview Mode

In debug mode, you can preview UI states using URL query parameters on web:

- `?preview=login`
- `?preview=owner-dashboard`
- `?preview=owner-inventory`
- `?preview=clerk-pos`

Optional language override:

- `&lang=am` for Amharic
- default is English

Example:

```text
http://localhost:8080/?preview=owner-dashboard&lang=am
```

Note: preview mode is disabled in release builds.

## Useful Commands

```bash
flutter analyze
flutter test
flutter run -d chrome
```

## Notes

- Only owners can create staff accounts.
- Accounts marked inactive are blocked at login.
- Product deletion is blocked when stock is greater than zero.
