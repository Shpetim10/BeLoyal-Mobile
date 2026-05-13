# Customer Home Screen Requirements

This document describes the current customer home screen requirements, the related "View All" pages, and the recommended backend contract for integrating the frontend cleanly.

Source references:
- `lib/features/customer_ui/presentation/tabs/customer_home_tab.dart`
- `lib/features/customer_ui/presentation/pages/customer_view_all_businesses_page.dart`
- `lib/features/customer_ui/presentation/pages/customer_view_all_coupons_page.dart`
- `lib/features/customer_ui/presentation/pages/customer_view_all_transactions_page.dart`
- `lib/features/customer_ui/mock/customer_mock_data.dart`

## Current Screen Structure

The customer home screen currently contains:

1. Stats hero card
2. Quick shortcuts
3. Categories
4. Your Businesses
5. Discover Businesses
6. Coupons & Offers
7. Almost There
8. Top Businesses
9. Recent Activity
10. Expiring Soon

Important change:
- There is no separate customer "View All Offers" page in the current flow.
- The home deals section is now conceptually `Coupons & Offers`.
- The horizontal deal cards on home are currently backed by `hotOffers`, which is derived from the coupons dataset:
  - `hotOffers => coupons.where((c) => c.isHot).toList()`

Because of that, backend integration should treat offers and coupons as one promotions domain, with optional flags that control where they appear.

## Best Backend Integration Approach

The cleanest integration is:

1. Backend returns stable domain data and enum keys.
2. Frontend maps enum keys to presentation metadata such as color, emoji, and icon.
3. Backend may optionally send display metadata overrides, but the frontend should not depend on raw color strings for core rendering.

This is especially important for categories, because:
- the backend already uses enums
- colors are presentation concerns
- emojis are presentation concerns
- label text may be localized later

Recommended strategy:

1. Backend sends category enum key, label, and id.
2. Frontend keeps a local category presentation map keyed by enum.
3. Backend can optionally include `displayName` and `sortOrder`.
4. Frontend derives:
   - emoji
   - selected tab color
   - category chip color
   - business card category tint

This gives a stable contract without mixing UI styling too deeply into the backend.

## Recommended Top-Level API Shape

Recommended single endpoint:

`GET /customer/home`

Recommended response shape:

```json
{
  "summary": {},
  "categories": [],
  "businesses": [],
  "promotions": [],
  "transactions": []
}
```

Recommended behavior:
- `summary` powers the hero card
- `categories` powers filters and category tabs
- `businesses` powers:
  - Your Businesses
  - Home Discover Businesses
  - Discover Businesses
  - Almost There
  - Top Businesses
- `promotions` powers:
  - home Coupons & Offers carousel
  - Expiring Soon
  - View All Coupons page
- `transactions` powers:
  - Recent Activity
  - View All Transactions page

Alternative split, if you prefer smaller endpoints:

1. `GET /customer/home/summary`
2. `GET /customer/home/categories`
3. `GET /customer/home/businesses`
4. `GET /customer/home/promotions`
5. `GET /customer/home/transactions?limit=5`
6. `GET /customer/promotions`
7. `GET /customer/points-transactions`

The single home endpoint is the best first integration because the page is a dashboard and the sections are tightly related.

## Category Contract

## Backend

Since categories exist as enums in backend, the recommended payload is:

```json
{
  "id": 1,
  "key": "RESTAURANTS",
  "label": "Restaurants",
  "businessCount": 24,
  "sortOrder": 1
}
```

Recommended backend fields:
- `id`: integer
- `key`: enum string
- `label`: string
- `businessCount`: integer
- `sortOrder`: integer

Optional:
- `isEnabled`: boolean

## Frontend

Frontend should map `key` to presentation metadata.

Recommended local mapping:

```dart
const categoryPresentation = {
  'RESTAURANTS': CategoryPresentation(
    emoji: '🍽️',
    color: Color(0xFFEF4444),
  ),
  'CAFES': CategoryPresentation(
    emoji: '☕',
    color: Color(0xFFF59E0B),
  ),
  'FITNESS': CategoryPresentation(
    emoji: '💪',
    color: Color(0xFF22C55E),
  ),
};
```

Why this is the best approach:
- backend enums remain stable
- frontend keeps full control over design consistency
- clients do not depend on backend color formatting
- localization becomes easier because `label` can change without affecting colors/emojis

## If backend wants to send UI metadata too

This is acceptable as an optional enhancement:

```json
{
  "id": 1,
  "key": "RESTAURANTS",
  "label": "Restaurants",
  "presentation": {
    "emoji": "🍽️",
    "colorHex": "#EF4444"
  }
}
```

Recommended rule:
- frontend should still have a local fallback map even if backend sends UI metadata
- local fallback prevents broken UI when metadata is missing

## Summary Contract

Used by the home hero card.

Required fields:
- `currentPoints`: number
- `lifetimePoints`: number
- `spentPoints`: number
- `businessesVisited`: number
- `activeCoupons`: number
- `activeRewards`: number
- `memberSinceLabel`: string
- `memberCode`: string

Optional fields:
- `firstName`
- `lastName`
- `email`
- `phone`

Recommended payload:

```json
{
  "currentPoints": 3240,
  "lifetimePoints": 14820,
  "spentPoints": 11580,
  "businessesVisited": 18,
  "activeCoupons": 4,
  "activeRewards": 7,
  "memberSinceLabel": "March 2023",
  "memberCode": "ALEX-8472"
}
```

Notes:
- `memberSinceLabel` is better than sending a raw date if the backend already owns membership semantics.
- If backend sends a raw membership date instead, frontend will need a formatting rule.

## Business Contract

Businesses drive multiple sections:
- Your Businesses
- Home Discover Businesses
- Discover Businesses
- Almost There
- Top Businesses
- Business detail navigation
- View All Businesses page

Recommended payload:

```json
{
  "id": 1,
  "name": "Noir Bistro",
  "categoryId": 1,
  "categoryKey": "RESTAURANTS",
  "categoryLabel": "Restaurants",
  "points": 310,
  "nextRewardPoints": 500,
  "distanceKm": 0.3,
  "distanceLabel": "0.3 km",
  "isOpen": true,
  "rating": 4.8,
  "logoEmoji": "🍽️",
  "hasLogo": true,
  "brandColorHex": "#9B5DE5",
  "gradientHex": ["#1A0535", "#9B5DE5"],
  "address": "Rruga Elbasanit 12, Tirana",
  "phone": "+355 4 222 3344",
  "email": "info@nourbistro.al",
  "openingHoursLabel": "Mon-Fri 11:00-23:00 · Sat-Sun 12:00-00:00",
  "description": "Fine dining with a modern twist.",
  "hasOffer": true,
  "offerLabel": "2x pts today"
}
```

Required fields:
- `id`
- `name`
- `categoryId`
- `categoryKey`
- `categoryLabel`
- `points`
- `nextRewardPoints`
- `isOpen`
- `rating`
- `hasLogo`
- `address`
- `phone`
- `email`
- `description`

Strongly recommended:
- `distanceLabel`
- `gradientHex`
- `logoEmoji`
- `openingHoursLabel`

Optional:
- `hasOffer`
- `offerLabel`
- `brandColorHex`

Frontend notes:
- `nextRewardPoints` must be greater than `0`
- if `distanceLabel` is not provided, frontend must format `distanceKm`
- `offerLabel` should be non-empty whenever `hasOffer == true`
- if `gradientHex` is not sent, frontend should derive fallback colors from category presentation

## Business Section Logic

### Your Businesses

Current frontend rule:
- source is businesses where `points > 0`
- on home, this section is additionally filtered by selected category

Current home card style:
- larger card
- strong gradient header
- top-left category emoji badge
- centered logo chip tinted by category color when `hasLogo == true`
- body shows points progress state

Displayed fields:
- `name`
- `categoryLabel`
- `rating`
- `points`
- `nextRewardPoints`
- `gradientHex`
- `logoEmoji`
- `hasLogo`
- category presentation metadata

Derived values:
- `remaining = nextRewardPoints - points`
- `progress = points / nextRewardPoints`

### Home Discover Businesses

Current frontend rule:
- source is businesses where `points == 0`
- on home, this section is additionally filtered by selected category

Current home card style:
- separate horizontal carousel
- smaller card than `Your Businesses`
- muted gradient header
- centered compact logo chip
- emphasis on discovery instead of reward progress

Displayed fields:
- `name`
- `rating`
- `distanceLabel`
- `gradientHex`
- `logoEmoji`

Derived UI behavior:
- no progress bar
- no current points display
- shows CTA chip:
  - `Start earning`

Empty state:
- if no zero-point businesses match the selected category, show:
  - `No new businesses in this category.`

### Discover Businesses

Current frontend rule:
- source is businesses where `points == 0`

Displayed fields:
- `name`
- `categoryLabel`
- `rating`
- `distanceLabel`
- `nextRewardPoints`
- `gradientHex`
- `logoEmoji`
- `hasLogo`

Discover mode behavior:
- does not show progress bar
- shows CTA-like message:
  - `Start earning points`
  - `Up to {nextRewardPoints} pts reward`

### Almost There

Current frontend rule:
- `0 < nextRewardPoints - points <= 200`

Displayed fields:
- `name`
- `logoEmoji`
- `gradientHex`
- `points`
- `nextRewardPoints`

### Top Businesses

Current frontend rule:
- sorted by `rating` descending

Displayed fields:
- `name`
- `logoEmoji`
- `gradientHex`
- `rating`
- `distanceLabel`
- `isOpen`

## Promotions Contract

The app now effectively treats coupons and offers as one promotions dataset.

Recommended payload:

```json
{
  "id": 5,
  "businessId": 3,
  "businessName": "FitZone Pro",
  "title": "Free Class Pass",
  "description": "One free group class of your choice.",
  "promotionType": "FREE_PRODUCT",
  "status": "EXPIRING",
  "discountValue": 0,
  "discountDisplay": "Free Class",
  "multiplierLabel": "+200 pts",
  "pointCost": 600,
  "expiresAt": "2026-05-11T18:00:00Z",
  "gradientHex": ["#052E16", "#22C55E"],
  "isHot": true,
  "isUsed": false,
  "usageCount": 0,
  "usageLimit": 1,
  "termsAndConditions": "Must book 24h in advance."
}
```

Required fields:
- `id`
- `businessId`
- `businessName`
- `title`
- `promotionType`
- `status`
- `discountValue`
- `discountDisplay`
- `pointCost`
- `expiresAt`
- `gradientHex`
- `isUsed`
- `usageCount`

Strongly recommended:
- `description`
- `isHot`
- `multiplierLabel`
- `usageLimit`
- `termsAndConditions`

Recommended enum values:

Promotion type:
- `FREE_PRODUCT`
- `PERCENTAGE_DISCOUNT`
- `FIXED_AMOUNT_DISCOUNT`

Promotion status:
- `ACTIVE`
- `EXPIRING`
- `USED`
- `EXPIRED`

Important backend/frontend note:
- backend should ideally return enum keys in uppercase
- frontend can map them to lowercase/localized labels as needed
- current mock/UI logic uses lowercase strings in places, so introducing typed mapping on the frontend would be a good cleanup

## Promotions Usage On Home

### Coupons & Offers Carousel

Current frontend source:
- promotions where `isHot == true`

Displayed fields:
- `title`
- `businessName`
- `gradientHex`
- `expiresAt`
- `isHot`
- `multiplierLabel` if present
- otherwise fallback to `discountDisplay`

Current navigation:
- all carousel cards route to View All Coupons

### Expiring Soon

Current frontend source:
- promotions where status is expiring

Displayed fields:
- `title`
- `businessName`
- `discountDisplay`
- `expiresAt`
- `gradientHex`

## Transactions Contract

Recommended payload:

```json
{
  "id": 1,
  "businessId": 2,
  "businessName": "Bravo Coffee",
  "type": "EARN",
  "points": 45,
  "date": "2026-05-09T10:00:00Z",
  "description": "Flat White + Croissant",
  "netAmount": 4.50,
  "billAmount": 4.50,
  "logoEmoji": "☕",
  "referenceId": "ORD-2024-0891",
  "discountAmount": null
}
```

Required fields:
- `id`
- `businessId`
- `businessName`
- `type`
- `points`
- `date`
- `description`
- `netAmount`
- `billAmount`

Strongly recommended:
- `logoEmoji`
- `referenceId`

Recommended transaction enum values:
- `EARN`
- `REDEEM`
- `REFUND`
- `ADJUSTMENT`
- `EXPIRED`
- `COUPON_PURCHASE`

Recent Activity uses:
- `businessName`
- `description`
- `points`
- `logoEmoji`

View All Transactions additionally uses:
- `type`
- `date`
- `billAmount`

## Home Section Requirements

## Stats Hero Card

Displays:
- current points
- member since label
- lifetime points
- spent points
- businesses visited
- active coupons
- active rewards
- member code

Navigation:
- Lifetime -> Transactions page with `initialFilter = EARN`
- Spent -> Transactions page with `initialFilter = REDEEM`
- Businesses -> View All Businesses
- Coupons -> View All Coupons
- Rewards -> View All Businesses

## Quick Shortcuts

Current shortcuts:
- Scan Card
- Rewards
- Transactions
- Businesses
- Coupons

Only navigation and local icon metadata are required here.

## Categories

Current behavior:
- selected category id is stored on home
- `0` means All
- selected category filters both:
  - home `Your Businesses`
  - home `Discover Businesses`

Recommended frontend category model:

```json
{
  "id": 1,
  "key": "RESTAURANTS",
  "label": "Restaurants"
}
```

Recommended frontend presentation resolution:
- `emoji` from `key`
- `color` from `key`
- fallback label from `label`

## Your Businesses

Behavior:
- if selected category is `0`, show all businesses with points
- otherwise filter by `categoryId`
- if empty, show empty state

Display details that matter:
- card width is currently wider than before and optimized for a richer header
- category identity is shown twice:
  - category emoji badge in the top-left of the header
  - category label in the body row
- logo display is conditional:
  - if `hasLogo == true`, show centered logo chip
  - chip tint comes from category presentation color
- rating is shown inline beside category label
- progress bar and remaining points are required for this section

## Home Discover Businesses

Behavior:
- source is businesses where `points == 0`
- if selected category is `0`, show all zero-point businesses
- otherwise filter by `categoryId`
- if empty, show empty state

Display details that matter:
- this is a distinct home-only discovery section, separate from the promotions section
- card uses a muted version of the business gradient
- card shows:
  - logo emoji
  - business name
  - rating
  - distance label
  - discovery CTA chip
- this section does not use:
  - points
  - progress bar
  - remaining-to-reward messaging

Backend implication:
- the frontend currently derives this section by `points == 0`
- if backend wants more control later, it could send `isDiscoveredByCustomer` or `hasCustomerPoints`

## Coupons & Offers

Behavior:
- home carousel uses hot promotions from the promotions dataset
- the section title is currently broader than coupons alone
- clicking View All goes to coupons page

Recommendation:
- backend should expose a single promotions resource with filters:
  - `isHot`
  - `status`
  - `promotionType`

## Almost There

Behavior:
- section only renders if at least one business is within 200 points of next reward

Recommendation:
- this can stay frontend-derived
- or backend can provide `isAlmostThere` if business rules become more complex later

## Top Businesses

Behavior:
- rendered from businesses sorted by rating descending

Recommendation:
- if ranking logic becomes more advanced, backend should send an explicit sorted list

## Recent Activity

Behavior:
- home currently uses the first five transactions from the transactions dataset

Recommendation:
- backend should send transactions already sorted descending by date

## Expiring Soon

Behavior:
- section only renders when there are expiring promotions

Recommendation:
- backend should expose status cleanly as enum
- frontend should map enum to display state

## View All Businesses Page

Current behavior:
- one page with two sections:
  - Your Businesses
  - Discover Businesses

Filters:
- search by business name or category label
- filter by category id

Data split:
- Your Businesses = businesses with `points > 0`
- Discover Businesses = businesses with `points == 0`

Displayed fields:
- `name`
- `categoryLabel`
- `rating`
- `distanceLabel`
- `points`
- `nextRewardPoints`
- `gradientHex`
- `logoEmoji`
- `hasLogo`
- `hasOffer`
- `offerLabel`

Important note:
- this page no longer accepts custom title/subtitle/list overrides
- backend contract should assume one canonical businesses dataset, not page-specific variants

## View All Coupons Page

Current behavior:
- shows all promotions currently represented as coupons
- supports search and status filters
- shows expiring summary banner

Page input:
- `initialFilter`

Current filters:
- `all`
- `active`
- `expiring`
- `used`
- `expired`

Displayed fields:
- `discountDisplay`
- `gradientHex`
- `promotionType`
- `title`
- `status`
- `businessName`
- `expiresAt`
- `isUsed`

Derived UI behavior:
- opacity reduced when used or expired
- left panel becomes gray when used or expired
- "Use Now" is shown only for active or expiring items

## View All Transactions Page

Page inputs:
- `initialFilter`
- `title`
- `transactions` optional override

Current tab filters:
- `ALL`
- `EARN`
- `REDEEM`

Displayed fields:
- `businessName`
- `description`
- `type`
- `date`
- `billAmount`
- `points`
- `logoEmoji`

Derived behavior:
- transactions are sorted descending by date
- grouped into:
  - Today
  - Yesterday
  - weekday name
  - full date
- summary pills are derived from the transactions list

## Backend Recommendations That Matter Most

1. Return stable enum keys for categories, promotion status, promotion type, and transaction type.
2. Return labels separately from enum keys so localization stays possible.
3. Let frontend own color and emoji mapping by enum key.
4. Send optional display metadata only as enhancement, not as the only source of truth.
5. Return timestamps in ISO-8601 format for `date` and `expiresAt`.
6. Return businesses in one dataset and let frontend derive:
   - Your Businesses
   - Home Discover Businesses
   - Discover Businesses
   - Almost There
   - Top Businesses
7. Return promotions in one dataset and let frontend derive:
   - hot carousel
   - expiring section
   - coupons page
8. Ensure `nextRewardPoints > 0` for every business.
9. Ensure `offerLabel` is populated whenever `hasOffer == true`.
10. Prefer sending both raw numeric values and preformatted labels when formatting is business-specific:
   - `distanceKm` and `distanceLabel`
   - `memberSinceDate` and/or `memberSinceLabel`
   - `openingHours` raw structure and/or `openingHoursLabel`

## Best Next Step For Implementation

The best production-ready path is:

1. Define backend DTOs with enum keys.
2. Create frontend domain models that use typed enums instead of raw strings.
3. Add a frontend presentation mapper:
   - category enum -> emoji, color
   - promotion status enum -> chip color, label
   - promotion type enum -> icon
   - transaction type enum -> badge color, icon
4. Replace mock-data string matching such as `_categoryEmoji(categoryName)` with enum-based mapping.

That will make the integration safer, more maintainable, and much less fragile than relying on display strings.
