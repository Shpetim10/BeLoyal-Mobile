# Business Onboarding Feature (REQ-03)

This feature implements the complete business registration and approval workflow for the BeLoyal/BesaHub Flutter app.

## Overview

The business onboarding flow allows restaurant owners to register their business on the platform. The registration goes through an admin review process, and pending businesses are shown an "Under Review" screen until approved.

## Architecture

### Folder Structure

```
lib/features/business_onboarding/
├── api/
│   └── business_onboarding_api.dart      # API client for backend calls
├── models/
│   ├── business_registration_dto.dart     # Business registration data model
│   ├── register_user_dto.dart             # User registration DTO (for new accounts)
│   ├── submit_application_models.dart     # Request/Response models + BusinessStatus enum
│   └── verify_ownership_models.dart       # Verify ownership request/response
├── pages/
│   ├── business_registration_entry_page.dart        # Entry point
│   ├── business_account_choice_page.dart            # Choose existing vs new account
│   ├── existing_account_verify_page.dart            # Verify existing account
│   ├── new_account_for_business_page.dart           # Create new user account
│   ├── business_details_form_page.dart             # Business details form
│   ├── under_review_confirmation_page.dart          # Success confirmation
│   └── under_review_gate_page.dart                 # Pending approval screen
├── state/
│   ├── business_registration_draft.dart            # Draft state model
│   └── business_registration_notifier.dart         # Riverpod state management
└── README.md
```

## Flow

1. **Entry** → `/business/register`
   - User clicks "Register as Business"
   - Shows introduction and "Start Business Registration" button

2. **Account Choice** → `/business/register/account-choice`
   - User chooses: "I already have an account" or "I'm new"

3a. **Existing Account** → `/business/register/existing-account`
   - User enters email + password
   - Calls `POST /besahub/auth/verify-ownership`
   - On success, stores `ownershipToken` in draft state
   - If email not verified, shows warning + resend option

3b. **New Account** → `/business/register/new-account`
   - User fills: firstName, lastName, username, email, phone, password, confirmPassword, T&C
   - Stores `RegisterUserDto` in draft state (no API call yet)

4. **Business Details** → `/business/register/details`
   - User fills business form:
     - businessName* (required)
     - businessType* (Restaurant/Café/Bar/Other)
     - address (optional)
     - city* (required)
     - country (optional)
     - businessEmail* (required)
     - businessPhoneNumber* (required)
     - vatId (optional)
     - websiteUrl (optional, URL validated)
     - logoUrl (optional, URL validated)
     - businessDescription (optional, max 1000 chars)
   - On submit: Calls `POST /onboarding/business/applications`
   - Payload:
     - If existing user: `{ businessRegistrationDto, ownershipToken }`
     - If new user: `{ businessRegistrationDto, userDto }`

5. **Confirmation** → `/business/register/under-review-confirmation`
   - Success message
   - Shows business name and status
   - "Go to Dashboard" button → routes to `/business/under-review`

6. **Under Review Gate** → `/business/under-review`
   - Shown to users with `businessStatus == PENDING_APPROVAL`
   - Explains review process
   - "Refresh Status" button calls `GET /business/me`
   - If status becomes `ACTIVE`, auto-redirects to `/business/dashboard`
   - Blocks business admin features (client-side)

## State Management

Uses Riverpod for state:

- **`businessRegistrationDraftProvider`** (StateNotifier)
  - Stores multi-step form draft:
    - `ownerMode`: NEW_ACCOUNT | EXISTING_AUTHENTICATED
    - `ownershipToken`: String? (for existing users)
    - `newUserDto`: RegisterUserDto? (for new users)
    - `businessRegistrationDto`: BusinessRegistrationDto?

- **`verifyOwnershipNotifierProvider`** (AsyncNotifier)
  - Handles ownership verification API call
  - Updates draft state on success

- **`submitBusinessApplicationNotifierProvider`** (AsyncNotifier)
  - Handles business application submission
  - Clears draft on success

- **`refreshBusinessStatusNotifierProvider`** (AsyncNotifier)
  - Fetches current business status
  - Used by UnderReviewGatePage

## API Endpoints

Configured in `BusinessOnboardingEndpoints`:

- `POST /besahub/auth/verify-ownership`
  - Body: `{ email, password }`
  - Response: `{ approved, emailVerified, ownershipToken }`

- `POST /onboarding/business/applications`
  - Body: `{ businessRegistrationDto, ownershipToken? }` OR `{ businessRegistrationDto, userDto? }`
  - Response: `{ success, message?, businessId?, businessName?, status? }`

- `GET /business/me`
  - Response: `{ businessStatus, businessName, ... }`

**Note**: Adjust endpoint paths in `lib/features/business_onboarding/api/business_onboarding_api.dart` if your backend uses different routes.

## Integration

### 1. Add Entry Point

Add a "Register as Business" button somewhere accessible (e.g., login page, register page, or a dedicated landing page):

```dart
TextButton(
  onPressed: () => context.go('/business/register'),
  child: const Text('Register as Business'),
)
```

### 2. Route Business Dashboard Based on Status

Update `/business/dashboard` route in `app_router.dart` to check business status and redirect to `/business/under-review` if pending:

```dart
// In app_router.dart redirect logic:
if (path == '/business/dashboard' && isLoggedIn) {
  // Check business status (you'll need to fetch this)
  // If PENDING_APPROVAL → redirect to '/business/under-review'
  // If ACTIVE → proceed to dashboard
}
```

**Future Enhancement**: Create a `businessProfileProvider` that fetches business status on login and stores it in session, then use it in router redirect logic.

### 3. Handle Business Status After Login

When a user logs in with `restaurantAdmin` role, check their business status:

- If `PENDING_APPROVAL` → show `UnderReviewGatePage`
- If `ACTIVE` → show business dashboard

You can extend `sessionController` or create a separate provider to fetch and cache business status.

## Error Handling

- **Field Errors**: Backend validation errors are shown inline under respective form fields
- **General Errors**: Displayed via `StatusBanner` at top of form
- **Network Errors**: Handled gracefully with user-friendly messages

## Styling

All pages use existing app theme:
- `AuthShell` for consistent background
- `GlassCard` for form containers
- `PremiumTextField` for inputs
- `PrimaryGradientButton` for CTAs
- `StatusBanner` for messages
- `AppColors` for colors

## Testing Checklist

- [ ] Entry page loads correctly
- [ ] Account choice navigation works
- [ ] Existing account verification flow
- [ ] New account creation flow
- [ ] Business details form validation
- [ ] Form submission with both account types
- [ ] Error handling (network, validation, duplicate)
- [ ] Under review confirmation page
- [ ] Under review gate page
- [ ] Status refresh functionality
- [ ] Navigation back buttons work
- [ ] Draft state persists across navigation
- [ ] Draft clears after successful submission

## Notes

- The `acceptedTcVersion` is hardcoded to `'v1.0'` (matching existing registration flow)
- Business status enum: `PENDING_APPROVAL`, `ACTIVE`, `REJECTED`, `INACTIVE`
- All endpoints are relative to the base URL configured in `dioProvider` (`/api/beloyal`)
- The flow prevents duplicate submissions by clearing draft state after success
