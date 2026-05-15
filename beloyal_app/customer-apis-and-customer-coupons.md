# Customer APIs and Customer Coupon Endpoints

This document covers the current customer-facing API surface implemented in:

- `src/main/java/com/shabanaj/beloyal/features/customerApis`
- `src/main/java/com/shabanaj/beloyal/features/customerCoupon`

Base URL prefix: `/api/besahub`

All customer endpoints require `Authorization: Bearer <access_token>` and role `CUSTOMER`, unless a section explicitly says otherwise. Staff coupon scan endpoints require access to the business as `BUSINESS_ADMIN` or `STAFF`.

Common error response shape from `GlobalExceptionHandler`:

```json
{
  "timestamp": "2026-05-15T10:30:00Z",
  "status": 422,
  "message": "Coupon is not active",
  "path": "/api/besahub/customer/coupons/12/redeem"
}
```

## Endpoint Summary

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/customer/home` | `CUSTOMER` | Aggregated customer home screen data. |
| `GET` | `/customer/businesses` | `CUSTOMER` | List all active businesses with customer points and next reward. |
| `GET` | `/customer/businesses/{businessId}` | `CUSTOMER` | Full business detail, loyalty, catalog, coupons, and recent transactions. |
| `GET` | `/customer/coupons/{couponId}` | `CUSTOMER` | Customer-facing coupon detail, public or owned. |
| `GET` | `/customer/promotions?status={status}` | `CUSTOMER` | List owned and public promotions, optionally filtered by status. |
| `GET` | `/customer/transactions?type={type}` | `CUSTOMER` | List recent customer point transactions, optionally filtered by mapped type. |
| `GET` | `/customer/businesses/{businessId}/available-coupons` | `CUSTOMER` | List coupons available at one business and whether current customer can redeem each. |
| `POST` | `/customer/coupons/{couponId}/validate-redemption` | `CUSTOMER` | Validate if current customer can redeem one coupon. |
| `POST` | `/customer/coupons/{couponId}/redeem` | `CUSTOMER` | Buy/redeem a coupon with points. |
| `GET` | `/customer/my-coupons` | `CUSTOMER` | List coupons already redeemed by current customer. |
| `POST` | `/customer/customer-coupons/{customerCouponId}/apply` | `CUSTOMER` | Attach an optional order id to an owned coupon. |
| `POST` | `/customer/customer-coupons/{customerCouponId}/use` | `CUSTOMER` | Mark an owned coupon as used from customer side. |
| `POST` | `/business/{businessId}/coupons/scan` | `BUSINESS_ADMIN` or `STAFF` | Staff scans a free-product coupon QR and marks it used. |

Related endpoint using `customerApis` service:

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/customer/me/details` | `CUSTOMER` | Customer profile header plus customer summary stats. Implemented in `CustomerProfileController`, backed by `CustomerProfileDetailsService`. |

## Shared Concepts

### Coupon Types

```text
FREE_PRODUCT
PERCENTAGE_DISCOUNT
FIXED_AMOUNT_DISCOUNT
```

### Coupon Statuses

Backend coupon configuration status:

```text
DRAFT
ACTIVE
PAUSED
EXPIRED
ARCHIVED
```

Customer-owned coupon status:

```text
REDEEMED
USED
EXPIRED
CANCELLED
```

Customer API display status values:

```text
ACTIVE
EXPIRING
USED
EXPIRED
```

`EXPIRING` is returned for owned redeemed coupons whose `expiresAt` is before `now + 3 days`, and for public coupon detail when coupon `endDate` is before `now + 3 days`.

### Promotion Type Mapping

In business detail coupons, coupon type is mapped to a frontend-style promotion type:

| Coupon type | `promotionType` |
| --- | --- |
| `PERCENTAGE_DISCOUNT` | `DISCOUNT_PERCENT` |
| `FIXED_AMOUNT_DISCOUNT` | `DISCOUNT_FIXED` |
| `FREE_PRODUCT` | `FREE_PRODUCT` |

In `/customer/promotions`, `promotionType` currently returns the raw coupon type name.

### Transaction Type Mapping

| `PointsType` | Customer API `type` |
| --- | --- |
| `EARN_BILL` | `EARN` |
| `REDEEM_DISCOUNT` | `REDEEM` |
| `REDEEM_OFFER` | `REDEEM` |
| `COUPON_REDEMPTION` | `COUPON_PURCHASE` |
| `EXPIRE` | `EXPIRED` |
| `ADJUSTMENT_PLUS` | `ADJUSTMENT` |
| `ADJUSTMENT_MINUS` | `ADJUSTMENT` |
| `REVERSAL` | `ADJUSTMENT` |

## Customer API Endpoints

## 1. GET `/customer/home`

Returns the customer home screen in one call.

Auth: `CUSTOMER`

Request body: none

Query params: none

Success `200` response:

```json
{
  "summary": {
    "currentPoints": 420,
    "lifetimePoints": 1200,
    "spentPoints": 780,
    "businessesVisited": 5,
    "activeCoupons": 2,
    "activeRewards": 3,
    "memberSinceLabel": "May 2026",
    "memberCode": "ABCD1234"
  },
  "categories": [
    {
      "id": 0,
      "key": "RESTAURANT",
      "label": "Restaurant",
      "businessCount": 4,
      "sortOrder": 0
    }
  ],
  "businesses": [
    {
      "id": 10,
      "name": "Besa Coffee",
      "categoryId": 0,
      "categoryKey": "RESTAURANT",
      "categoryLabel": "Restaurant",
      "points": 120,
      "nextRewardPoints": 250,
      "isOpen": null,
      "rating": 4.8,
      "hasLogo": true,
      "logoUrl": "/uploads/businesses/10/logo.png",
      "brandColorHex": null,
      "gradientHex": null,
      "address": "Main Street",
      "phone": "+355...",
      "email": "hello@example.com",
      "description": "Business description",
      "hasOffer": false,
      "offerLabel": null
    }
  ],
  "promotions": [
    {
      "id": 99,
      "businessId": 10,
      "couponId": 99,
      "businessName": "Besa Coffee",
      "title": "Free Cappuccino",
      "description": "Get a free cappuccino",
      "promotionType": "FREE_PRODUCT",
      "status": "ACTIVE",
      "discountDisplay": "Free Product",
      "pointCost": 250,
      "expiresAt": "2026-06-01T00:00:00",
      "expiresIn": "16 days",
      "gradientHex": null,
      "isHot": true,
      "isUsed": false,
      "usageCount": 0,
      "usageLimit": 1,
      "termsAndConditions": "Valid once.",
      "isOwned": false,
      "qrCode": null,
      "customerRedemptionCount": 0
    }
  ],
  "transactions": [
    {
      "id": 501,
      "businessId": 10,
      "businessName": "Besa Coffee",
      "type": "EARN",
      "points": 20,
      "date": "2026-05-15T12:00:00",
      "description": "Earned points",
      "netAmount": 10.0,
      "billAmount": 10.0,
      "discountAmount": 0.0,
      "currency": "EURO",
      "referenceId": "INV-001",
      "reason": "Purchase",
      "scanMethod": "QR",
      "moneyAmount": 10.0,
      "ruleAmountPer": 1.0,
      "rulePointsPer": 2,
      "note": "Optional bill note"
    }
  ]
}
```

Logic:

- Loads customer summary from `CustomerStatsService`.
- Lists all active businesses from `BusinessViewService`.
- Builds categories only for business categories present in the returned business list.
- Loads promotions using `/customer/promotions` logic with no status filter.
- Loads transactions using `/customer/transactions` logic with no type filter.
- Transactions are capped by service query to the first 200 records.

## 2. GET `/customer/businesses`

Lists all active businesses visible to the customer.

Auth: `CUSTOMER`

Request body: none

Query params: none

Success `200` response:

```json
[
  {
    "id": 10,
    "name": "Besa Coffee",
    "categoryId": 0,
    "categoryKey": "RESTAURANT",
    "categoryLabel": "Restaurant",
    "points": 120,
    "nextRewardPoints": 250,
    "isOpen": null,
    "rating": 4.8,
    "hasLogo": true,
    "logoUrl": "/uploads/businesses/10/logo.png",
    "brandColorHex": null,
    "gradientHex": null,
    "address": "Main Street",
    "phone": "+355...",
    "email": "hello@example.com",
    "description": "Business description",
    "hasOffer": false,
    "offerLabel": null
  }
]
```

Logic:

- Resolves authenticated user and customer profile.
- Loads all loyalty accounts for the customer.
- Loads all businesses with `BusinessStatus.ACTIVE`.
- For each active business:
  - `points` is the customer's available loyalty account points for that business, or `0` when no loyalty account exists.
  - `nextRewardPoints` is the cheapest currently available public active coupon for that business, or `0` when none exists.
  - category values come from `BusinessCategory` ordinal/name/title-case.
  - `isOpen`, brand color, gradient, and offer fields currently return `null` or `false`.

## 3. GET `/customer/businesses/{businessId}`

Returns the complete customer view for one active business.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `businessId` | number | yes | Active business id. |

Request body: none

Success `200` response:

```json
{
  "business": {
    "id": 10,
    "name": "Besa Coffee",
    "categoryId": 0,
    "categoryKey": "RESTAURANT",
    "categoryLabel": "Restaurant",
    "rating": 4.8,
    "hasLogo": true,
    "logoUrl": "/uploads/businesses/10/logo.png",
    "description": "Business description",
    "address": "Main Street",
    "phone": "+355...",
    "email": "hello@example.com",
    "websiteUrl": "https://example.com",
    "location": {
      "addressLine1": "Main Street",
      "addressLine2": null,
      "city": "Tirana",
      "country": "Albania",
      "postalCode": null,
      "latitude": null,
      "longitude": null,
      "mapLabel": "Besa Coffee, Tirana"
    }
  },
  "loyalty": {
    "currentPoints": 120,
    "nextRewardPoints": 250,
    "pointsToNextReward": 130,
    "memberCode": "ABCD1234",
    "loyaltyPolicy": "Earn 2 points for every 1 EUR spent. Redeem from 100 points for a discount.",
    "loyaltySettings": {
      "minPointsToRedeem": 100,
      "maxPointsToRedeem": 1000,
      "pointsPerUnitDiscount": 10,
      "maxPointsPerTransaction": 500,
      "expiryType": "EXPIRE_AFTER_X_MONTHS",
      "monthsToExpire": 12,
      "enabled": true,
      "configured": true
    },
    "earningSettings": {
      "pointsPer": 2,
      "amountPer": 1.0,
      "enabled": true,
      "configured": true
    },
    "lifetimeEarned": 1000,
    "lifetimeRedeemed": 500,
    "lifetimeExpired": 0,
    "lastActivityAt": "2026-05-15T12:00:00"
  },
  "catalog": {
    "categories": [
      {
        "id": 1,
        "name": "Coffee",
        "description": "Hot coffee",
        "sortOrder": 1
      }
    ],
    "items": [
      {
        "id": 11,
        "categoryId": 1,
        "name": "Cappuccino",
        "description": "Classic cappuccino",
        "imageUrl": "/uploads/item.png",
        "isAvailable": true,
        "sortOrder": 1,
        "pointsLabel": "+2 pts",
        "basePrice": 2.5,
        "currency": "EUR",
        "unit": "cup",
        "earnedPoints": 5
      }
    ],
    "variants": [
      {
        "id": 21,
        "itemId": 11,
        "name": "Large",
        "description": "Large cup",
        "price": 3.0,
        "currency": "EUR",
        "isDefault": true,
        "isAvailable": true,
        "earnedPoints": 6
      }
    ]
  },
  "coupons": [
    {
      "customerCouponId": null,
      "couponId": 99,
      "businessId": 10,
      "businessName": "Besa Coffee",
      "title": "Free Cappuccino",
      "description": "Get a free cappuccino",
      "imageUrl": "/uploads/coupon.png",
      "promotionType": "FREE_PRODUCT",
      "status": "ACTIVE",
      "discountDisplay": "Free Product",
      "discountValue": null,
      "pointCost": 250,
      "currency": "EUR",
      "isUsed": false,
      "isOwned": false,
      "usageCount": 0,
      "usageLimit": 1,
      "isFeatured": true,
      "totalRedemptions": 10,
      "totalRedemptionLimit": 500,
      "startDate": "2026-05-01T00:00:00",
      "expiresAt": "2026-06-01T00:00:00",
      "termsAndConditions": "Valid once.",
      "minimumOrderAmount": null,
      "maximumDiscountAmount": null,
      "freeProductCategoryId": 1,
      "freeProductCategoryName": "Coffee",
      "freeProductId": 11,
      "freeProductName": "Cappuccino",
      "freeVariantId": 21,
      "freeVariantName": "Large",
      "freeQuantity": 1,
      "snapshotTitle": null,
      "snapshotDescription": null,
      "snapshotImageUrl": null,
      "snapshotCouponType": null,
      "snapshotMinimumOrderAmount": null,
      "snapshotMaximumDiscountAmount": null,
      "redeemedAt": null,
      "usedAt": null,
      "orderId": null,
      "qrCode": null,
      "expiresIn": "Expires in 16d",
      "customerRedemptionCount": 0
    }
  ],
  "transactions": [
    {
      "id": 501,
      "businessId": 10,
      "businessName": "Besa Coffee",
      "type": "EARN",
      "points": 20,
      "date": "2026-05-15T12:00:00",
      "description": "Earned points",
      "netAmount": 10.0,
      "billAmount": 10.0,
      "discountAmount": 0.0,
      "referenceId": "INV-001",
      "reason": "Purchase",
      "scanMethod": "QR",
      "moneyAmount": 10.0,
      "ruleAmountPer": 1.0,
      "rulePointsPer": 2,
      "currency": "EURO",
      "invoiceReference": "INV-001",
      "note": "Optional bill note"
    }
  ],
  "details": {
    "about": "Business description",
    "phone": "+355...",
    "email": "hello@example.com",
    "categoryLabel": "Restaurant",
    "websiteUrl": "https://example.com",
    "customerNotes": null,
    "termsSummary": null
  }
}
```

Logic:

- Resolves authenticated user, customer profile, and customer loyalty card.
- Requires `businessId` to belong to an active business.
- Loads the customer's loyalty account for this business; if missing, point balances are treated as `0`.
- Loads loyalty settings and earning settings when configured.
- Loads available public coupons through `CouponRepository.findAvailableForBusiness`, meaning:
  - coupon is not deleted,
  - status is `ACTIVE`,
  - visibility is `PUBLIC`,
  - `startDate <= now`,
  - `endDate >= now`,
  - total redemption limit is not reached,
  - ordered by featured, sort order, and created date.
- `loyalty.nextRewardPoints` is the cheapest available coupon that the customer has not exhausted by per-customer limit. If none exists, it falls back to loyalty settings minimum redeem points, or `1`.
- Catalog only returns active, non-deleted categories and active, non-deleted items. Variants are loaded for those items and marked default by first variant per item.
- Coupons include both:
  - owned coupons for this customer/business, ordered newest first,
  - public available coupons not already owned by the customer.
- Owned coupons use snapshot values where available and include `customerCouponId`, `qrCode`, `redeemedAt`, `usedAt`, and `orderId`.
- Public coupons have `customerCouponId: null`, `isOwned: false`, no QR code, and no lifecycle timestamps.
- Transactions are the first 200 point transactions for this customer and business.

## 4. GET `/customer/coupons/{couponId}`

Returns customer-facing coupon detail. This endpoint can show either an active public coupon or a coupon owned by the current customer.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `couponId` | number | yes | Underlying loyalty coupon id, not customer coupon id. |

Request body: none

Success `200` response:

```json
{
  "id": 99,
  "businessId": 10,
  "businessName": "Besa Coffee",
  "title": "Free Cappuccino",
  "discountValue": null,
  "discountDisplay": "Free Product",
  "status": "ACTIVE",
  "type": "FREE_PRODUCT",
  "expiresAt": "2026-06-01T00:00:00",
  "startDate": "2026-05-01T00:00:00",
  "pointCost": 250,
  "description": "Get a free cappuccino",
  "termsAndConditions": "Valid once.",
  "imageUrl": "/uploads/coupon.png",
  "currency": "EURO",
  "isFeatured": true,
  "isUsed": false,
  "isOwned": false,
  "isHot": false,
  "totalRedemptions": 10,
  "totalRedemptionLimit": 500,
  "usageLimit": 1,
  "usageCount": 0,
  "customerCouponId": null,
  "minimumOrderAmount": null,
  "maximumDiscountAmount": null,
  "freeProductCategory": "Coffee",
  "freeProductName": "Cappuccino",
  "freeProductVariant": "Large",
  "freeProductQuantity": 1,
  "redeemedAt": null,
  "usedAt": null,
  "orderId": null,
  "qrCode": null,
  "multiplierLabel": null,
  "expiresIn": "Expires in 16d",
  "customerRedemptionCount": 0
}
```

Logic:

- Loads coupon by `couponId`.
- Allows access when coupon is active public and currently valid, or when the current customer owns the coupon.
- Throws `404 Coupon not found` if the coupon is neither public-active nor owned by the customer.
- Uses owned coupon lifecycle fields when present:
  - `customerCouponId`
  - `redeemedAt`
  - `usedAt`
  - `orderId`
  - `qrCode`
  - owned `expiresAt`
- For discount coupons, returns percentage or fixed amount details from coupon rule or owned snapshot fallback.
- For free-product coupons, returns category/product/variant names and quantity.
- Counts how many times the current customer has redeemed this underlying coupon.

## 5. GET `/customer/promotions`

Returns a combined list of owned promotions and active public coupons.

Auth: `CUSTOMER`

Query params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `status` | string | no | Filters by display status, for example `ACTIVE`, `EXPIRING`, `USED`, `EXPIRED`. Case-insensitive input, compared after uppercasing. |

Request body: none

Success `200` response:

```json
[
  {
    "id": 99,
    "businessId": 10,
    "couponId": 99,
    "businessName": "Besa Coffee",
    "title": "Free Cappuccino",
    "description": "Get a free cappuccino",
    "promotionType": "FREE_PRODUCT",
    "status": "ACTIVE",
    "discountDisplay": "Free Product",
    "pointCost": 250,
    "expiresAt": "2026-06-01T00:00:00",
    "expiresIn": "16 days",
    "gradientHex": null,
    "isHot": true,
    "isUsed": false,
    "usageCount": 0,
    "usageLimit": 1,
    "termsAndConditions": "Valid once.",
    "isOwned": false,
    "qrCode": null,
    "customerRedemptionCount": 0
  }
]
```

Logic:

- Loads all customer-owned coupons with coupon and business details.
- Loads all active public coupons across all businesses:
  - not deleted,
  - status `ACTIVE`,
  - visibility `PUBLIC`,
  - within date range,
  - not sold out.
- Merges lists by `couponId`; owned promotions win over public entries.
- For owned coupons:
  - `id` is the `CustomerCoupon` id,
  - `isOwned` is `true`,
  - `qrCode` is present,
  - `usageCount` is `1` when status is `USED`, else `0`,
  - status is derived from owned coupon state.
- For public coupons:
  - `id` equals `couponId`,
  - `isOwned` is `false`,
  - `qrCode` is `null`,
  - status is always `ACTIVE`.

## 6. GET `/customer/transactions`

Returns recent point transactions for the current customer.

Auth: `CUSTOMER`

Query params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `type` | string | no | Filters by mapped type: `EARN`, `REDEEM`, `COUPON_PURCHASE`, `EXPIRED`, `ADJUSTMENT`. Case-insensitive input, compared after uppercasing. |

Request body: none

Success `200` response:

```json
[
  {
    "id": 501,
    "businessId": 10,
    "businessName": "Besa Coffee",
    "type": "EARN",
    "points": 20,
    "date": "2026-05-15T12:00:00",
    "description": "Earned points",
    "netAmount": 10.0,
    "billAmount": 10.0,
    "discountAmount": 0.0,
    "currency": "EURO",
    "referenceId": "INV-001",
    "reason": "Purchase",
    "scanMethod": "QR",
    "moneyAmount": 10.0,
    "ruleAmountPer": 1.0,
    "rulePointsPer": 2,
    "note": "Optional bill note"
  }
]
```

Logic:

- Queries point transactions for the current user, capped to the first 200 records.
- Maps raw `PointsType` to customer API display types.
- Bill fields are returned only when a point transaction has a linked bill transaction.
- Optional `type` filter is applied after mapping.

## Related Customer Profile Details Endpoint

## 7. GET `/customer/me/details`

This controller is outside `features/customerApis/controller`, but it uses `CustomerProfileDetailsService` from `customerApis`.

Auth: `CUSTOMER`

Request body: none

Query params: none

Success `200` response:

```json
{
  "profile": {
    "firstName": "John",
    "lastName": "Doe",
    "fullName": "John Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "phoneNumber": "+355...",
    "profileImageUrl": "/uploads/profile.png",
    "avatarInitials": "JD",
    "status": "ENABLED",
    "memberSince": "May 2026",
    "memberCode": "ABCD1234",
    "birthDate": "1995-01-01",
    "gender": "MALE",
    "city": "Tirana",
    "country": "Albania",
    "referralCode": "REF123",
    "referredBy": null,
    "notificationEnabled": true,
    "acceptedTerms": true
  },
  "stats": {
    "currentPoints": 420,
    "lifetimePoints": 1200,
    "spentPoints": 780,
    "businessesVisited": 5,
    "activeCoupons": 2,
    "activeRewards": 3,
    "memberSinceLabel": "May 2026",
    "memberCode": "ABCD1234"
  }
}
```

Logic:

- Resolves user, customer profile, and loyalty card.
- Builds display name and avatar initials.
- `acceptedTerms` is `true` when `acceptedTcVersion` exists on user.
- Stats reuse the same customer summary logic as `/customer/home`.

## Customer Coupon Endpoints

## 8. GET `/customer/businesses/{businessId}/available-coupons`

Returns available public coupons for one active business and marks whether the current customer can redeem each.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `businessId` | number | yes | Active business id. |

Request body: none

Success `200` response:

```json
{
  "customerPointBalance": 120,
  "businessCurrency": "EURO",
  "coupons": [
    {
      "couponId": 99,
      "type": "FREE_PRODUCT",
      "title": "Free Cappuccino",
      "description": "Get a free cappuccino",
      "imageUrl": "/uploads/coupon.png",
      "pointsCost": 250,
      "currency": "EURO",
      "startDate": "2026-05-01T00:00:00",
      "endDate": "2026-06-01T00:00:00",
      "totalRedemptionLimit": 500,
      "totalRedemptions": 10,
      "perCustomerRedemptionLimit": 1,
      "termsAndConditions": "Valid once.",
      "isFeatured": true,
      "customerRedemptionCount": 0,
      "canRedeem": false,
      "cannotRedeemReason": "Insufficient points"
    }
  ]
}
```

Logic:

- Requires active business.
- Resolves current customer profile.
- Gets customer point balance for this business; if no loyalty account exists, balance is `0`.
- Loads available public coupons using the same rules as business detail:
  - active,
  - public,
  - not deleted,
  - within date range,
  - not sold out.
- For each coupon:
  - `canRedeem` is `false` with reason `Insufficient points` when balance is below `pointsCost`.
  - `canRedeem` is `false` with reason `Redemption limit reached` when per-customer limit exists and the customer has already reached it.
  - Otherwise `canRedeem` is `true`.

## 9. POST `/customer/coupons/{couponId}/validate-redemption`

Checks if a coupon can be redeemed by the current customer. This endpoint does not mutate data.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `couponId` | number | yes | Underlying loyalty coupon id. |

Request body: none

Success `200` response examples:

```json
{
  "canRedeem": true,
  "reason": null,
  "pointsRequired": 250,
  "customerBalance": 300
}
```

```json
{
  "canRedeem": false,
  "reason": "Insufficient points. Required: 250, available: 120",
  "pointsRequired": 250,
  "customerBalance": 120
}
```

Logic:

- Returns `canRedeem: false` instead of throwing for normal validation failures.
- Failure reasons:
  - `Coupon not found`
  - `Coupon is not active`
  - `Coupon is outside its validity period`
  - `Coupon is sold out`
  - `Insufficient points. Required: X, available: Y`
  - `Redemption limit reached`
- Success requires:
  - coupon exists and is not deleted,
  - status is `ACTIVE`,
  - current time is within coupon date range,
  - total redemption limit is not reached,
  - customer has enough points in that coupon's business loyalty account,
  - per-customer redemption limit is not reached.

## 10. POST `/customer/coupons/{couponId}/redeem`

Redeems or buys a coupon using customer points.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `couponId` | number | yes | Underlying loyalty coupon id. |

Request body: none

Success `201` response:

```json
{
  "customerCouponId": 1001,
  "couponId": 99,
  "status": "REDEEMED",
  "pointsSpent": 250,
  "remainingBalance": 50,
  "currency": "EURO",
  "redeemedAt": "2026-05-15T12:00:00",
  "expiresAt": null,
  "qrCode": "550e8400-e29b-41d4-a716-446655440000",
  "snapshotTitle": "Free Cappuccino",
  "snapshotDescription": "Get a free cappuccino",
  "snapshotImageUrl": "/uploads/coupon.png",
  "snapshotCouponType": "FREE_PRODUCT"
}
```

Logic:

- Runs in a database transaction.
- Loads coupon with pessimistic write lock.
- Validates:
  - coupon exists and is not deleted,
  - coupon status is `ACTIVE`,
  - current time is within coupon date range,
  - coupon is not sold out,
  - customer has not reached per-customer redemption limit.
- Loads the customer's loyalty account for the coupon's business with pessimistic write lock.
- Fails if no loyalty account exists for the business.
- Fails if balance is lower than coupon `pointsCost`.
- Deducts points from loyalty account.
- Increments coupon `totalRedemptions`.
- Creates a `PointsTransaction` audit record with type `COUPON_REDEMPTION` and negative points delta.
- Drains points buckets FIFO through `PointsBucketService.spend`.
- Creates a `CustomerCoupon` snapshot:
  - status `REDEEMED`,
  - redeemed timestamp,
  - points spent,
  - currency,
  - UUID QR code,
  - coupon title/description/image/type snapshot,
  - free-product product and variant snapshot for `FREE_PRODUCT`,
  - discount percentage/amount/minimum/maximum snapshot for discount coupons.

Important current behavior:

- `expiresAt` in the created `CustomerCoupon` is not explicitly set in this service, so it can be `null` unless the entity supplies a default elsewhere.
- The QR code is a UUID string, not an image payload.

Possible errors:

| Status | Message |
| --- | --- |
| `404` | `Coupon not found: {couponId}` |
| `404` | `No loyalty account found for this business` |
| `422` | `Coupon is not active` |
| `422` | `Coupon has expired or is not within its validity period` |
| `422` | `Coupon has reached its total redemption limit` |
| `422` | `You have reached the maximum redemption limit for this coupon` |
| `422` | `Insufficient points. Required: X, available: Y` |

## 11. GET `/customer/my-coupons`

Lists all coupons owned by the current customer.

Auth: `CUSTOMER`

Request body: none

Query params: none

Success `200` response:

```json
[
  {
    "id": 1001,
    "couponId": 99,
    "businessId": 10,
    "status": "REDEEMED",
    "pointsSpent": 250,
    "currency": "EURO",
    "redeemedAt": "2026-05-15T12:00:00",
    "usedAt": null,
    "expiresAt": null,
    "orderId": null,
    "qrCode": "550e8400-e29b-41d4-a716-446655440000",
    "snapshotTitle": "Free Cappuccino",
    "snapshotDescription": "Get a free cappuccino",
    "snapshotImageUrl": "/uploads/coupon.png",
    "snapshotCouponType": "FREE_PRODUCT",
    "snapshotProductId": 11,
    "snapshotVariantId": 21,
    "snapshotDiscountPercentage": null,
    "snapshotDiscountAmount": null,
    "snapshotMinimumOrderAmount": null,
    "snapshotMaximumDiscountAmount": null,
    "createdAt": "2026-05-15T12:00:00"
  }
]
```

Logic:

- Resolves current user and customer profile.
- Returns all `CustomerCoupon` rows for that profile, newest first.
- Uses snapshot fields, so customer history remains stable even if the base coupon changes later.

## 12. POST `/customer/customer-coupons/{customerCouponId}/apply`

Attaches an optional order id to a customer-owned coupon.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `customerCouponId` | number | yes | Owned customer coupon id. |

Request body:

```json
{
  "orderId": "ORDER-123"
}
```

The request body is optional. If omitted or if `orderId` is missing, the service stores `null`.

Success `200` response:

```json
{
  "id": 1001,
  "couponId": 99,
  "businessId": 10,
  "status": "REDEEMED",
  "pointsSpent": 250,
  "currency": "EURO",
  "redeemedAt": "2026-05-15T12:00:00",
  "usedAt": null,
  "expiresAt": null,
  "orderId": "ORDER-123",
  "qrCode": "550e8400-e29b-41d4-a716-446655440000",
  "snapshotTitle": "Free Cappuccino",
  "snapshotDescription": "Get a free cappuccino",
  "snapshotImageUrl": "/uploads/coupon.png",
  "snapshotCouponType": "FREE_PRODUCT",
  "snapshotProductId": 11,
  "snapshotVariantId": 21,
  "snapshotDiscountPercentage": null,
  "snapshotDiscountAmount": null,
  "snapshotMinimumOrderAmount": null,
  "snapshotMaximumDiscountAmount": null,
  "createdAt": "2026-05-15T12:00:00"
}
```

Logic:

- Looks up the `CustomerCoupon` by id and current customer profile.
- Only coupons in status `REDEEMED` can be applied.
- Sets `orderId` and returns the updated snapshot.
- Does not mark the coupon used.

Possible errors:

| Status | Message |
| --- | --- |
| `404` | `Customer coupon not found: {customerCouponId}` |
| `422` | `Coupon cannot be applied - current status: USED` |

## 13. POST `/customer/customer-coupons/{customerCouponId}/use`

Marks a customer-owned coupon as used from the customer side.

Auth: `CUSTOMER`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `customerCouponId` | number | yes | Owned customer coupon id. |

Request body: none

Success `200` response:

```json
{
  "id": 1001,
  "couponId": 99,
  "businessId": 10,
  "status": "USED",
  "pointsSpent": 250,
  "currency": "EURO",
  "redeemedAt": "2026-05-15T12:00:00",
  "usedAt": "2026-05-15T12:10:00",
  "expiresAt": null,
  "orderId": "ORDER-123",
  "qrCode": "550e8400-e29b-41d4-a716-446655440000",
  "snapshotTitle": "Free Cappuccino",
  "snapshotDescription": "Get a free cappuccino",
  "snapshotImageUrl": "/uploads/coupon.png",
  "snapshotCouponType": "FREE_PRODUCT",
  "snapshotProductId": 11,
  "snapshotVariantId": 21,
  "snapshotDiscountPercentage": null,
  "snapshotDiscountAmount": null,
  "snapshotMinimumOrderAmount": null,
  "snapshotMaximumDiscountAmount": null,
  "createdAt": "2026-05-15T12:00:00"
}
```

Logic:

- Looks up the `CustomerCoupon` by id and current customer profile.
- Only coupons in status `REDEEMED` can be marked used.
- Sets status to `USED`.
- Sets `usedAt` to current timestamp.

Possible errors:

| Status | Message |
| --- | --- |
| `404` | `Customer coupon not found: {customerCouponId}` |
| `422` | `Coupon cannot be marked as used - current status: USED` |

## 14. POST `/business/{businessId}/coupons/scan`

Staff/business endpoint for scanning a customer coupon QR code and redeeming a free-product coupon.

Auth: `BUSINESS_ADMIN` or `STAFF` with access to `{businessId}`

Path params:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `businessId` | number | yes | Business where coupon is being redeemed. |

Request body:

```json
{
  "qrCode": "550e8400-e29b-41d4-a716-446655440000",
  "redemptionLocation": "Main counter"
}
```

Validation:

- `qrCode` is required and cannot be blank.
- `redemptionLocation` is optional.

Success `200` response:

```json
{
  "customerCouponId": 1001,
  "couponId": 99,
  "status": "USED",
  "couponType": "FREE_PRODUCT",
  "couponTitle": "Free Cappuccino",
  "snapshotProductId": 11,
  "snapshotVariantId": 21,
  "usedAt": "2026-05-15T12:10:00",
  "redemptionLocation": "Main counter"
}
```

Logic:

- Resolves staff user and verifies business member for the requested business.
- Loads `CustomerCoupon` by `qrCode` with a pessimistic write lock.
- Validates the customer coupon belongs to `{businessId}`.
- Only supports coupons where underlying coupon type is `FREE_PRODUCT`.
- Rejects already-used coupons.
- Requires customer coupon status `REDEEMED`.
- Requires underlying coupon status `ACTIVE`.
- Requires current time to be within coupon start and end dates.
- Marks customer coupon as:
  - status `USED`,
  - `usedAt = now`,
  - `redeemedByStaff = current staff member`,
  - `redemptionLocation = request.redemptionLocation`,
  - `redemptionChannel = STAFF_SCAN`.

Possible errors:

| Status | Message |
| --- | --- |
| `400` | Validation error for blank `qrCode` |
| `404` | `Invalid or unrecognized QR code` |
| `409` | `Coupon has already been used` |
| `422` | `This endpoint only handles FREE_PRODUCT coupons. Use the earn-points endpoint for discount coupons.` |
| `422` | `Customer coupon is not in a redeemable state: EXPIRED` |
| `422` | `Coupon is not active` |
| `422` | `Coupon is not yet valid - it hasn't reached its start date` |
| `422` | `Coupon has expired or is not within its validity period` |

## Coupon Logic Flow

## Customer browsing flow

1. Customer opens home with `GET /customer/home`.
2. Backend returns summary, active businesses, public/owned promotions, and recent transactions.
3. Customer opens a business with `GET /customer/businesses/{businessId}`.
4. Backend returns business details, loyalty state, active catalog, available/owned coupons, and recent business-specific transactions.
5. Customer opens one coupon with `GET /customer/coupons/{couponId}`.
6. Backend allows the detail only if the coupon is public-active or already owned by the customer.

## Customer redemption flow

1. Client can call `POST /customer/coupons/{couponId}/validate-redemption`.
2. If `canRedeem` is `true`, client calls `POST /customer/coupons/{couponId}/redeem`.
3. Backend locks the coupon and loyalty account.
4. Backend validates status, dates, total limit, per-customer limit, loyalty account existence, and point balance.
5. Backend deducts points, records a negative `COUPON_REDEMPTION` transaction, spends buckets FIFO, increments total coupon redemptions, and creates a customer coupon snapshot with QR.
6. Client stores/displays `customerCouponId` and `qrCode`.
7. Customer can view owned coupons with `GET /customer/my-coupons`.

## Discount coupon usage flow

1. Customer redeems the discount coupon with points.
2. Client can attach an order id with `POST /customer/customer-coupons/{customerCouponId}/apply`.
3. Actual discount usage should be coordinated with the purchase/earn-points flow. The staff scan endpoint intentionally rejects discount coupons.
4. `POST /customer/customer-coupons/{customerCouponId}/use` can mark the owned coupon used, but it does not calculate a bill discount by itself.

## Free-product staff scan flow

1. Customer redeems a `FREE_PRODUCT` coupon and receives a QR UUID.
2. Staff scans QR using `POST /business/{businessId}/coupons/scan`.
3. Backend locks the `CustomerCoupon`, validates ownership, coupon type, status, and date range.
4. Backend marks the owned coupon as `USED` and records staff/location/channel metadata.

## Implementation Notes and Current Caveats

- Available/public coupon queries require `visibility = PUBLIC`. Hidden coupons are not listed unless already owned and surfaced through owned-coupon queries.
- Per-customer redemption limit is counted by number of `CustomerCoupon` rows for the same underlying coupon and customer profile. It includes used and redeemed rows.
- `/customer/promotions` merges owned and public promotions by `couponId`, preferring the owned row.
- `/customer/businesses/{businessId}` also removes public coupons already owned by the customer before appending public coupons.
- Coupon detail `GET /customer/coupons/{couponId}` uses `findByCouponIdAndCustomerProfileId`, so if a customer has redeemed the same coupon multiple times, only one owned row can be returned by that repository method.
- Coupon redemption currently creates a QR UUID but does not render a QR image.
- Customer-side `/use` and staff-side `/scan` both mark coupons used, but staff scan is restricted to `FREE_PRODUCT`.
- There is no pagination on these customer list endpoints yet. Transaction queries are internally capped to 200 records.
