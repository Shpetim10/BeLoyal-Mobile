<div align="center">

<img src="https://img.shields.io/badge/BeLoyal-Mobile-7C3AED?style=for-the-badge&logoColor=white" alt="BeLoyal Mobile" />

# BeLoyal — Loyalty Rewards Mobile App

**A cross-platform mobile application for customers and businesses to manage loyalty programs.**  
Built with Flutter · Dart · Riverpod · GoRouter · Dio

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-SDK_^3.9.2-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.2.1-00BCD4?style=flat-square&logoColor=white)](https://riverpod.dev/)
[![License](https://img.shields.io/badge/License-See_Repo-gray?style=flat-square)](./LICENSE)

</div>

---

## Table of Contents

- [About](#about)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Running Locally](#running-locally)
- [Project Structure](#project-structure)
- [Key Dependencies](#key-dependencies)
- [Screens Overview](#screens-overview)
- [Author](#author)

---

## About

**BeLoyal Mobile** is the Flutter frontend for the BesaHub loyalty platform. It serves two distinct roles in a single app:

- **Business users** (owners and staff) can manage their loyalty program, handle customer registrations, configure earning rules, issue coupons, and view transaction history.
- **Customers** can discover businesses, track their loyalty points across multiple merchants, view available rewards and coupons, and present QR codes at the point of sale.

The app communicates exclusively with the [BeLoyal API](../BeLoyal-API) over a secured REST interface using JWT-based authentication.

---

## Architecture

The app uses a feature-first folder structure with a clean separation between presentation, domain, and data layers inside each feature module.

```
User Interaction
       │
       ▼
┌────────────────┐
│  Page / Widget │  ◄── Renders UI, delegates interactions
└───────┬────────┘
        │
        ▼
┌────────────────┐
│   Controller   │  ◄── Riverpod Notifier, manages async state
│   (Riverpod)   │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│   Repository   │  ◄── Issues HTTP requests, maps JSON to models
└───────┬────────┘
        │
        ▼
┌────────────────┐
│   Dio Client   │  ◄── Auth interceptor, token refresh, base URL
└───────┬────────┘
        │
        ▼
┌────────────────┐
│  BeLoyal API   │  ◄── Spring Boot backend
└────────────────┘
```

**Session state** (authenticated user, active role, active business) is held in a dedicated `SessionController` that is the single source of truth across the entire app.

---

## Features

| Area | Capabilities |
|---|---|
| **Authentication** | Login, registration, account activation via deep link, password reset |
| **Role Management** | Business owner, staff, customer, and super admin roles within one app |
| **Business Onboarding** | Multi-step onboarding flow with pending/under-review/approved states |
| **Loyalty Dashboard** | Business dashboard with overview stats and recent activity |
| **Earning Points** | Staff-facing bill scanning and manual point registration flow |
| **Points Transactions** | Transaction history for businesses and customers |
| **Coupons** | Coupon creation, management, and QR code redemption flow |
| **Loyalty Cards** | Customer-side loyalty card with QR code display |
| **Customer Lookup** | Business-side customer lookup by code or QR scan |
| **Catalog** | Product categories and item management |
| **Customer Loyalty UI** | Customer-facing screens for points, merchants, and rewards |
| **Staff Management** | Invite staff, manage roles and membership |
| **Profile** | User profile editing with image upload |
| **Media** | In-app image picker and camera integration |
| **Deep Links** | Invitation acceptance and activation link handling |
| **Secure Storage** | JWT tokens stored via `flutter_secure_storage` |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Dart |
| Framework | Flutter |
| SDK Requirement | Dart SDK `^3.9.2` |
| State Management | flutter_riverpod 3.2.1 |
| Routing | go_router 17.1.0 |
| HTTP Client | dio 5.9.1 |
| Secure Storage | flutter_secure_storage 9.0.0 |
| Fonts | google_fonts 8.0.1 |
| Animations | flutter_animate 4.5.2 |
| QR Display | qr_flutter 4.1.0 |
| QR Scanning | mobile_scanner 7.2.0 |
| Image Picking | image_picker 1.0.7 |
| Deep Links | app_links 7.0.0 |
| Internationalization | intl 0.20.2 |
| Unique IDs | uuid 4.5.1 |
| Testing | flutter_test |

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Flutter SDK | Install from [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | Included with Flutter (requires `^3.9.2`) |
| Android Studio / Xcode | For running on Android or iOS simulators/devices |
| BeLoyal API | The backend must be running and accessible — see [BeLoyal API](../BeLoyal-API) |

Verify your Flutter setup:

```bash
flutter doctor
```

---

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd BeLoyal-Mobile/beloyal_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the API base URL

The app connects to the BeLoyal API. Locate the Dio client configuration in:

```
lib/core/network/
```

Update the base URL to point to your running API instance (default is `http://localhost:8080`). For physical devices, use your machine's local network IP instead of `localhost`.

### 4. Run the app

```bash
flutter run
```

Select your target device when prompted (Android emulator, iOS simulator, or a connected physical device).

---

## Running Locally

### Start the app on a connected device or emulator

```bash
flutter run
```

### Run on a specific device

```bash
flutter devices              # List available devices
flutter run -d <device-id>
```

### Run tests

```bash
flutter test
```

### Run a specific test file

```bash
flutter test test/path_to_test.dart
```

### Static analysis

```bash
flutter analyze
```

### Format code

```bash
dart format lib test
```

### Build a release APK (Android)

```bash
flutter build apk --release
```

### Build for iOS

```bash
flutter build ios --release
```

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
│
├── core/
│   ├── network/                     # Dio client, auth interceptor, token refresh
│   ├── router/                      # GoRouter setup, route definitions, redirects
│   ├── services/                    # Secure token storage, deep-link service
│   ├── theme/                       # App-wide theme, typography, color tokens
│   ├── utils/                       # Shared helper functions
│   └── widgets/                     # Reusable UI components
│
└── features/
    ├── auth/                        # Login, registration, activation, password reset
    │   ├── presentation/pages/
    │   ├── presentation/widgets/
    │   ├── presentation/controllers/
    │   ├── data/repositories/
    │   └── data/models/
    │
    ├── business_onboarding/         # Multi-step business setup flow
    ├── business_loyalty/            # Loyalty settings configuration
    ├── dashboard/                   # Business owner and staff dashboard
    ├── earn_points/                 # Bill scanning and point registration
    ├── point_transactions/          # Transaction history
    ├── coupons/                     # Coupon management and redemption
    ├── customer_loyalty/            # Customer-facing loyalty and QR screens
    ├── customer_ui/                 # Customer discovery and merchant browsing
    ├── catalog_categories/          # Product category management
    ├── catalog_items/               # Product and item management
    ├── staff/                       # Staff management and invitations
    ├── profile/                     # User profile and image upload
    ├── media/                       # Media handling utilities
    ├── splash/                      # Splash screen and initial routing
    └── admin/                       # Super admin views
```

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | Reactive state management with providers and notifiers |
| `go_router` | Declarative navigation with redirect guards |
| `dio` | HTTP client with interceptor for JWT auth and token refresh |
| `flutter_secure_storage` | Encrypted on-device storage for access and refresh tokens |
| `mobile_scanner` | Camera-based QR code scanning |
| `qr_flutter` | QR code generation and display |
| `image_picker` | Profile image selection from camera or gallery |
| `app_links` | Deep link and universal link handling |
| `flutter_animate` | Declarative animation utilities |
| `google_fonts` | Custom typography from Google Fonts |
| `intl` | Date, number, and locale formatting |

---

## Screens Overview

| Screen | Role | Description |
|---|---|---|
| Splash | All | Initial load, session restoration, routing |
| Login / Register | All | Account authentication and onboarding |
| Activation | All | Account activation via deep link |
| Password Reset | All | Password recovery via email link |
| Business Dashboard | Owner / Staff | Loyalty program overview and stats |
| Earn Points | Staff | Scan customer QR and register bill points |
| Transaction History | Owner / Staff | View point and bill transaction history |
| Loyalty Settings | Owner | Configure loyalty program parameters |
| Coupon Management | Owner | Create, list, and manage coupons |
| Staff Management | Owner | Invite and manage business staff |
| Catalog | Owner | Manage product categories and items |
| Loyalty Card | Customer | Display personal QR loyalty card |
| Merchant Discovery | Customer | Browse available businesses |
| Customer Coupons | Customer | View and redeem owned coupons |
| Profile | All | Edit personal profile and upload photo |

---

## Author

<div align="center">

**Shpétim Shabanaj**

*BSc Software Engineering — BesaHub Loyalty Platform*

</div>
