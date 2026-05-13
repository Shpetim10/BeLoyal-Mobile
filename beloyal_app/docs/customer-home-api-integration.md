# Customer Home API — Frontend Integration Guide

Base URL prefix: `/api/besahub/customer`  
Authentication: `Authorization: Bearer <jwt>` (CUSTOMER role required)

---

## 1. Home Screen (single call)

```
GET /api/besahub/customer/home
```

Returns everything needed to render the full home screen in one request.

### Response

```json
{
  "summary": {
    "currentPoints": 420,
    "lifetimePoints": 1200,
    "spentPoints": 780,
    "businessesVisited": 3,
    "activeCoupons": 2,
    "activeRewards": 1,
    "memberSinceLabel": "January 2024",
    "memberCode": "ABC-12345"
  },
  "categories": [
    { "id": 0, "key": "RESTAURANT", "label": "Restaurant", "businessCount": 4, "sortOrder": 0 },
    { "id": 2, "key": "CAFE", "label": "Cafe", "businessCount": 2, "sortOrder": 2 }
  ],
  "businesses": [ ...see section 2... ],
  "promotions": [ ...see section 3... ],
  "transactions": [ ...see section 4... ]
}
```

### Field notes

| Field | Notes |
|---|---|
| `currentPoints` | Sum of available points across all loyalty accounts |
| `lifetimePoints` | Total points ever earned |
| `spentPoints` | Total points ever redeemed |
| `activeRewards` | Count of businesses where customer has enough points to redeem |
| `activeCoupons` | Count of coupons with status `REDEEMED` (ready to use) |
| `memberSinceLabel` | Formatted as "Month YYYY" |
| `memberCode` | Customer's loyalty card manual code for scanning |
| `categories` | Only categories that have at least one active business |

---

## 2. View All Businesses

```
GET /api/besahub/customer/businesses
```

Returns all active businesses with the customer's loyalty data merged in.

### Response (array of business objects)

```json
[
  {
    "id": 1,
    "name": "Cafe Korzo",
    "categoryId": 2,
    "categoryKey": "CAFE",
    "categoryLabel": "Cafe",
    "points": 150,
    "nextRewardPoints": 200,
    "isOpen": null,
    "rating": 4.5,
    "hasLogo": true,
    "logoUrl": "/uploads/logos/cafe-korzo.jpg",
    "brandColorHex": null,
    "gradientHex": null,
    "address": "Rruga Ismail Qemali 10",
    "phone": "+355 69 123 4567",
    "email": "info@cafekorzo.al",
    "description": "Specialty coffee in the heart of the city",
    "hasOffer": false,
    "offerLabel": null
  }
]
```

### Field notes

| Field | Notes |
|---|---|
| `points` | Customer's available points at this business; `0` if no account yet |
| `nextRewardPoints` | Points threshold to unlock a reward at this business |
| `isOpen` | Always `null` — no opening hours data yet (follow-up) |
| `brandColorHex` | Always `null` — derive color from `categoryKey` on the frontend |
| `gradientHex` | Always `null` — derive gradient from `categoryKey` on the frontend |
| `logoUrl` | Relative path served from `/uploads/**`; check `hasLogo` before rendering |

---

## 3. Business Detail

```
GET /api/besahub/customer/businesses/{businessId}
```

Returns the full business detail payload for a single active business. This endpoint requires a valid `CUSTOMER` JWT and is intended for the business detail screen.

### Path params

| Param | Type | Required | Notes |
|---|---|---|---|
| `businessId` | `number` | Yes | Active business id |

### Response

```json
{
  "business": {
    "id": 1,
    "name": "Cafe Korzo",
    "categoryId": 2,
    "categoryKey": "CAFE",
    "categoryLabel": "Cafe",
    "rating": 4.5,
    "hasLogo": true,
    "logoUrl": "/uploads/logos/cafe-korzo.jpg",
    "description": "Specialty coffee in the heart of the city",
    "address": "Rruga Ismail Qemali 10",
    "phone": "+355 69 123 4567",
    "email": "info@cafekorzo.al",
    "location": {
      "addressLine1": "Rruga Ismail Qemali 10",
      "addressLine2": "",
      "city": "Tirane",
      "country": "Albania",
      "postalCode": "",
      "latitude": null,
      "longitude": null,
      "mapLabel": "Cafe Korzo, Rruga Ismail Qemali 10, Tirane, Albania"
    }
  },
  "loyalty": {
    "currentPoints": 150,
    "nextRewardPoints": 200,
    "pointsToNextReward": 50,
    "memberCode": "ABC-12345",
    "loyaltyPolicy": "Earn 1 points for every 100 spent. Redeem from 200 points for a discount.",
    "loyaltySettings": {
      "minPointsToRedeem": 200,
      "maxPointsToRedeem": 1000,
      "pointsPerUnitDiscount": 10,
      "maxPointsPerTransaction": 500,
      "expiryType": "EXPIRE_AFTER_X_MONTHS",
      "monthsToExpire": 12,
      "enabled": true,
      "configured": true
    },
    "earningSettings": {
      "pointsPer": 1,
      "amountPer": 100.00,
      "enabled": true,
      "configured": true
    }
  },
  "catalog": {
    "categories": [
      {
        "id": 10,
        "name": "Coffee",
        "description": "Hot and cold coffee drinks",
        "sortOrder": 0
      }
    ],
    "items": [
      {
        "id": 100,
        "categoryId": 10,
        "name": "Espresso",
        "description": "Single shot espresso",
        "imageUrl": "/uploads/catalog/espresso.jpg",
        "emoji": null,
        "isPopular": false,
        "isAvailable": true,
        "sortOrder": 0,
        "pointsLabel": "+1 pts"
      }
    ],
    "variants": [
      {
        "id": 1000,
        "itemId": 100,
        "name": "Regular",
        "sku": null,
        "price": 120.00,
        "currency": "ALL",
        "isDefault": true,
        "isAvailable": true
      }
    ]
  },
  "coupons": [
    {
      "id": 42,
      "businessId": 1,
      "businessName": "Cafe Korzo",
      "title": "Free Espresso",
      "description": "Enjoy a complimentary espresso",
      "promotionType": "FREE_PRODUCT",
      "status": "ACTIVE",
      "discountDisplay": "Free Product",
      "discountValue": null,
      "pointCost": 100,
      "isUsed": false,
      "isOwned": false,
      "usageCount": 0,
      "usageLimit": 1,
      "expiresAt": "2025-06-01T23:59:59",
      "termsAndConditions": "One per visit. Not combinable."
    }
  ],
  "transactions": [
    {
      "id": 101,
      "businessId": 1,
      "businessName": "Cafe Korzo",
      "type": "EARN",
      "points": 15,
      "date": "2025-05-08T14:30:00",
      "description": "Earned from bill",
      "netAmount": 850.00,
      "billAmount": 1000.00,
      "discountAmount": 150.00,
      "referenceId": "INV-2025-0042"
    }
  ],
  "details": {
    "about": "Specialty coffee in the heart of the city",
    "phone": "+355 69 123 4567",
    "email": "info@cafekorzo.al",
    "categoryLabel": "Cafe",
    "customerNotes": "",
    "termsSummary": ""
  }
}
```

### Field notes

| Field | Notes |
|---|---|
| `business` | Core business header data for the detail page |
| `business.location` | Currently built from business profile fields; `latitude` and `longitude` are always `null` for now |
| `loyalty.currentPoints` | Customer's available points at this business; `0` if no loyalty account exists yet |
| `loyalty.nextRewardPoints` | Minimum points threshold to unlock a reward; falls back to `1` if loyalty settings are missing |
| `loyalty.pointsToNextReward` | `max(0, nextRewardPoints - currentPoints)` |
| `loyalty.memberCode` | Customer's loyalty card manual code |
| `loyalty.loyaltyPolicy` | Human-readable policy text derived from earning and loyalty settings |
| `loyalty.loyaltySettings` | `null` if loyalty settings do not exist for the business |
| `loyalty.earningSettings` | `null` if earning settings do not exist for the business |
| `catalog.categories` | Active catalog categories ordered by `sortOrder` |
| `catalog.items` | Active catalog items only |
| `catalog.items[].pointsLabel` | Formatted like `"+1 pts"` when earning settings are enabled/configured; otherwise `null` |
| `catalog.variants` | Active variants for the returned items; `isDefault` marks the first variant per item |
| `coupons` | Combined list of owned coupons first, then currently available public coupons not yet owned by the customer |
| `coupons[].id` | Owned coupons use the `customerCoupon.id`; public coupons use the base `coupon.id` |
| `coupons[].isOwned` | `true` for already redeemed customer coupons, `false` for currently available public offers |
| `coupons[].usageCount` | `1` only when an owned coupon is already used; otherwise `0` |
| `transactions` | Up to 200 most recent points transactions for this customer at this business |
| `details.customerNotes` | Currently always empty string |
| `details.termsSummary` | Currently always empty string |

### Common status values

#### `transactions[].type`

| Value | Meaning |
|---|---|
| `EARN` | Points earned from a purchase |
| `REDEEM` | Points used for a discount |
| `COUPON_PURCHASE` | Points spent to redeem a coupon |
| `EXPIRED` | Points that expired |
| `ADJUSTMENT` | Manual adjustment by business staff |

#### `coupons[].promotionType`

| Value | Meaning |
|---|---|
| `FREE_PRODUCT` | A free item |
| `PERCENTAGE_DISCOUNT` | Percentage off; see `discountDisplay` |
| `FIXED_AMOUNT_DISCOUNT` | Fixed amount off; see `discountDisplay` |

### Errors

#### `404 Not Found`

Returned when the `businessId` does not exist or the business is not active.

```json
{
  "timestamp": "2026-05-10T08:15:30Z",
  "status": 404,
  "message": "Business profile was not found!",
  "path": "/api/besahub/customer/businesses/999"
}
```

#### `401 Unauthorized`

Returned when the request is missing a valid bearer token.

#### `403 Forbidden`

Returned when the authenticated user does not have the `CUSTOMER` role.

---

## 4. View All Promotions (Coupons)

```
GET /api/besahub/customer/promotions
GET /api/besahub/customer/promotions?status=ACTIVE
GET /api/besahub/customer/promotions?status=EXPIRING
GET /api/besahub/customer/promotions?status=USED
GET /api/besahub/customer/promotions?status=EXPIRED
```

Returns the customer's redeemed coupons, optionally filtered by status.

### Status values

| Value | Meaning |
|---|---|
| `ACTIVE` | Coupon is ready to use (not near expiry) |
| `EXPIRING` | Coupon expires within 3 days |
| `USED` | Coupon has been used |
| `EXPIRED` | Coupon has expired or been cancelled |

### Response (array of promotion objects)

```json
[
  {
    "id": 42,
    "businessId": 1,
    "businessName": "Cafe Korzo",
    "title": "Free Espresso",
    "description": "Enjoy a complimentary espresso",
    "promotionType": "FREE_PRODUCT",
    "status": "ACTIVE",
    "discountDisplay": "Free Product",
    "pointCost": 100,
    "expiresAt": "2025-06-01T23:59:59",
    "gradientHex": null,
    "isHot": true,
    "isUsed": false,
    "usageCount": 0,
    "usageLimit": 1,
    "termsAndConditions": "One per visit. Not combinable."
  }
]
```

### `promotionType` values

| Value | Meaning |
|---|---|
| `FREE_PRODUCT` | A free item |
| `PERCENTAGE_DISCOUNT` | Percentage off; see `discountDisplay` e.g. `"15% Off"` |
| `FIXED_AMOUNT_DISCOUNT` | Fixed amount off; see `discountDisplay` e.g. `"5 EURO Off"` |

### `discountDisplay` examples

| Type | Example |
|---|---|
| `FREE_PRODUCT` | `"Free Product"` |
| `PERCENTAGE_DISCOUNT` | `"15% Off"` |
| `FIXED_AMOUNT_DISCOUNT` | `"5 EURO Off"` |

---

## 5. View All Transactions

```
GET /api/besahub/customer/transactions
GET /api/besahub/customer/transactions?type=EARN
GET /api/besahub/customer/transactions?type=REDEEM
GET /api/besahub/customer/transactions?type=COUPON_PURCHASE
GET /api/besahub/customer/transactions?type=EXPIRED
GET /api/besahub/customer/transactions?type=ADJUSTMENT
```

Returns the customer's last 200 points transactions, optionally filtered by type.

### Type values

| Value | Meaning |
|---|---|
| `EARN` | Points earned from a purchase |
| `REDEEM` | Points used for a discount |
| `COUPON_PURCHASE` | Points spent to redeem a coupon |
| `EXPIRED` | Points that expired |
| `ADJUSTMENT` | Manual adjustment by business staff |

### Response (array of transaction objects)

```json
[
  {
    "id": 101,
    "businessId": 1,
    "businessName": "Cafe Korzo",
    "type": "EARN",
    "points": 15,
    "date": "2025-05-08T14:30:00",
    "description": "Earned from bill",
    "netAmount": 850.00,
    "billAmount": 1000.00,
    "referenceId": "INV-2025-0042"
  }
]
```

### Field notes

| Field | Notes |
|---|---|
| `points` | Positive = earned/adjusted up; negative = spent/expired/adjusted down |
| `netAmount` | Bill amount after discount; `null` for non-bill transactions |
| `billAmount` | Original bill amount; `null` for non-bill transactions |
| `referenceId` | Invoice reference number; `null` for non-bill transactions |

---

## Error Responses

| Status | Meaning |
|---|---|
| `401` | Missing or invalid JWT |
| `403` | Authenticated but does not have CUSTOMER role |
| `404` | Customer profile not found |
| `500` | Server error |

---

## Known Gaps (follow-ups)

| Field | Gap | Resolution |
|---|---|---|
| `isOpen` | No opening hours schema | Add `opening_hours` table |
| `distanceLabel` | No geolocation on Business | Add lat/long columns + Haversine query |
| `brandColorHex` / `gradientHex` | Not stored | Frontend derives from `categoryKey` |
