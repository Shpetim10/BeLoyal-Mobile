# Customer API Endpoint Documentation

Base URL prefix: `/api/besahub`

## Authentication and Authorization

- All endpoints below require `Authorization: Bearer <access_token>`.
- Most customer endpoints require role `CUSTOMER` (`@PreAuthorize("hasRole('CUSTOMER')")`).
- User-profile endpoints use `isAuthenticated` and are available to any authenticated user.

## Field Naming Notes

- `GET /user-profile/me` returns both `imagePath` and `profileImageUrl` (same value, both present for compatibility).
- `GET /user-profile/me` returns `acceptedTerms` (boolean, derived from whether user has accepted a T&C version).
- Customer profile date field is `birthDate` in `/customer/me` and `PATCH /customer/me`.
- Registration/create-profile DTO uses `birthdate` (lowercase `d`) in request payload.

---

## 1) Customer Profile and User Profile

### GET `/customer/me/details`

Returns unified profile header with all editable fields plus summary stats. Preferred endpoint for profile tab — no need to merge multiple endpoints.

- Auth: `CUSTOMER`
- Query params: none

Response shape:
```json
{
  "profile": {
    "firstName": "string",
    "lastName": "string",
    "fullName": "string",
    "username": "string",
    "email": "string",
    "phoneNumber": "string|null",
    "profileImageUrl": "string|null",
    "avatarInitials": "string",
    "status": "ENABLED|DISABLED|LOCKED|PENDING_VERIFICATION|BLOCKED|REJECTED|INVITED",
    "memberSince": "string",
    "memberCode": "string",
    "birthDate": "YYYY-MM-DD|null",
    "gender": "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY|null",
    "city": "string|null",
    "country": "string|null",
    "referralCode": "string",
    "referredBy": "string|null",
    "notificationEnabled": true,
    "acceptedTerms": true
  },
  "stats": {
    "currentPoints": 0,
    "lifetimePoints": 0,
    "spentPoints": 0,
    "businessesVisited": 0,
    "activeCoupons": 0,
    "activeRewards": 0,
    "memberSinceLabel": "string",
    "memberCode": "string"
  }
}
```

### GET `/user-profile/me`

Returns authenticated user profile.

- Auth: authenticated user
- Query params: none

Response shape:
```json
{
  "firstName": "string",
  "lastName": "string",
  "email": "string",
  "username": "string",
  "phoneNumber": "string|null",
  "imagePath": "string|null",
  "profileImageUrl": "string|null",
  "acceptedTerms": true,
  "roles": ["CUSTOMER"]
}
```

Notes:
- `imagePath` and `profileImageUrl` are the same value; both are included for backward compatibility.
- `acceptedTerms` is `true` when the user has accepted at least one T&C version.

### GET `/customer/me`

Returns customer profile as a safe DTO (entity is not exposed directly).

- Auth: `CUSTOMER`
- Query params: none

Response shape:
```json
{
  "id": 0,
  "user": {
    "id": 0,
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "username": "string",
    "phoneNumber": "string|null",
    "profileImageUrl": "string|null"
  },
  "referralCode": "string",
  "referredBy": "string|null",
  "birthDate": "YYYY-MM-DD|null",
  "gender": "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY|null",
  "city": "string|null",
  "country": "string|null",
  "notificationEnabled": true,
  "createdAt": "ISO-8601 datetime",
  "updatedAt": "ISO-8601 datetime"
}
```

### PATCH `/user-profile/me`

Updates authenticated user profile fields (partial updates via JsonNullable semantics).

- Auth: authenticated user
- Query params: none

Request body:
```json
{
  "firstName": "string|null",
  "lastName": "string|null",
  "username": "string|null",
  "phoneNumber": "string|null",
  "imagePath": "string|null",
  "imageKey": "string|null"
}
```

Notes:
- `firstName`, `lastName`, `username` are treated as required when present.
- If sending image update/clear, `imagePath` and `imageKey` must be sent together.

Success response:
```json
{ "message": "User updated successfully" }
```

### PATCH `/customer/me`

Updates customer-specific profile fields (partial update).

- Auth: `CUSTOMER`
- Query params: none

Request body:
```json
{
  "city": "string|null",
  "country": "string|null",
  "gender": "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY|null",
  "birthDate": "YYYY-MM-DD|null",
  "notificationEnabled": true
}
```

Notes:
- All fields are optional. Only fields present in the payload are applied.
- `birthDate: null` clears a previously set birth date.
- `notificationEnabled` cannot be set to `null` (required when present).

Success response:
```json
{ "message": "Customer profile updated successfully!" }
```

### POST `/user-profile/change-password`

Changes password for authenticated user, invalidates all existing tokens, and returns fresh tokens.

- Auth: authenticated user
- Query params: none

Request body:
```json
{
  "currentPassword": "string",
  "newPassword": "string"
}
```

Notes:
- All existing access and refresh tokens are invalidated immediately upon success.
- Returned tokens are valid immediately; rotate both in the client session.

Success response:
```json
{
  "message": "Password updated successfully",
  "accessToken": "string",
  "refreshToken": "string"
}
```

---

## 2) Customer Onboarding

### POST `/customer/me/create-profile`

Creates customer profile for current authenticated customer and loyalty card.

- Auth: `CUSTOMER`

Request body:
```json
{
  "birthdate": "YYYY-MM-DD|null",
  "gender": "MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY|null",
  "city": "string|null",
  "country": "string|null",
  "referredBy": "string|null",
  "profileImageUrl": "string|null",
  "profileImageKey": "string|null",
  "notificationEnabled": true
}
```

Success response:
```json
{
  "firstName": "string",
  "lastName": "string",
  "qrToken": "string",
  "manualCode": "string"
}
```

---

## 3) Home, Businesses, Promotions, Transactions

### GET `/customer/home`

Returns aggregated home payload.

- Auth: `CUSTOMER`

Response shape:
```json
{
  "summary": { "...": "CustomerSummaryDto" },
  "categories": [{ "id": 0, "key": "string", "label": "string", "businessCount": 0, "sortOrder": 0 }],
  "businesses": [{ "...": "CustomerBusinessDto" }],
  "promotions": [{ "...": "CustomerPromotionDto" }],
  "transactions": [{ "...": "CustomerTransactionDto" }]
}
```

### GET `/customer/businesses`

Returns customer-visible businesses list.

- Auth: `CUSTOMER`

Response item (`CustomerBusinessDto`):
```json
{
  "id": 0,
  "name": "string",
  "categoryId": 0,
  "categoryKey": "string",
  "categoryLabel": "string",
  "points": 0,
  "nextRewardPoints": 0,
  "isOpen": true,
  "rating": 0,
  "hasLogo": true,
  "logoUrl": "string|null",
  "brandColorHex": "string|null",
  "gradientHex": ["#HEX"],
  "address": "string|null",
  "phone": "string|null",
  "email": "string|null",
  "description": "string|null",
  "hasOffer": false,
  "offerLabel": "string|null"
}
```

### GET `/customer/businesses/{businessId}`

Returns full business details for a customer.

- Auth: `CUSTOMER`
- Path params: `businessId` (Long)

Response shape:
```json
{
  "business": {
    "id": 0,
    "name": "string",
    "categoryId": 0,
    "categoryKey": "string",
    "categoryLabel": "string",
    "rating": 0,
    "hasLogo": true,
    "logoUrl": "string|null",
    "description": "string|null",
    "address": "string|null",
    "phone": "string|null",
    "email": "string|null",
    "websiteUrl": "string|null",
    "location": {
      "addressLine1": "string|null",
      "addressLine2": "string|null",
      "city": "string|null",
      "country": "string|null",
      "postalCode": "string|null",
      "latitude": 0,
      "longitude": 0,
      "mapLabel": "string|null"
    }
  },
  "loyalty": {
    "currentPoints": 0,
    "nextRewardPoints": 0,
    "pointsToNextReward": 0,
    "memberCode": "string",
    "loyaltyPolicy": "string|null",
    "loyaltySettings": {
      "minPointsToRedeem": 0,
      "maxPointsToRedeem": 0,
      "pointsPerUnitDiscount": 0,
      "maxPointsPerTransaction": 0,
      "expiryType": "string|null",
      "monthsToExpire": 0,
      "enabled": true,
      "configured": true
    },
    "earningSettings": {
      "pointsPer": 0,
      "amountPer": 0,
      "enabled": true,
      "configured": true
    },
    "lifetimeEarned": 0,
    "lifetimeRedeemed": 0,
    "lifetimeExpired": 0,
    "lastActivityAt": "ISO-8601 datetime|null"
  },
  "catalog": {
    "categories": [{ "id": 0, "name": "string", "description": "string|null", "sortOrder": 0 }],
    "items": [{ "id": 0, "categoryId": 0, "name": "string", "description": "string|null", "imageUrl": "string|null", "isAvailable": true, "sortOrder": 0, "pointsLabel": "string|null", "basePrice": 0, "currency": "string|null", "unit": "string|null" }],
    "variants": [{ "id": 0, "itemId": 0, "name": "string", "description": "string|null", "price": 0, "currency": "string|null", "isDefault": false, "isAvailable": true, "earnedPoints": 0 }]
  },
  "coupons": [{ "...": "CustomerBusinessCouponDto" }],
  "transactions": [{ "...": "CustomerBusinessTransactionDto" }],
  "details": {
    "about": "string|null",
    "phone": "string|null",
    "email": "string|null",
    "categoryLabel": "string|null",
    "websiteUrl": "string|null",
    "customerNotes": "string|null",
    "termsSummary": "string|null"
  }
}
```

### GET `/customer/promotions`

Returns customer promotions feed.

- Auth: `CUSTOMER`
- Query params:
  - `status` (optional string)

Response item (`CustomerPromotionDto`):
```json
{
  "id": 0,
  "businessId": 0,
  "couponId": 0,
  "businessName": "string",
  "title": "string",
  "description": "string|null",
  "promotionType": "string",
  "status": "string",
  "discountDisplay": "string|null",
  "pointCost": 0,
  "expiresAt": "ISO-8601 datetime|null",
  "gradientHex": ["#HEX"],
  "isHot": false,
  "isUsed": false,
  "usageCount": 0,
  "usageLimit": 0,
  "termsAndConditions": "string|null",
  "isOwned": false
}
```

### GET `/customer/transactions`

Returns customer transactions list.

- Auth: `CUSTOMER`
- Query params:
  - `type` (optional string)

Response item (`CustomerTransactionDto`):
```json
{
  "id": 0,
  "businessId": 0,
  "businessName": "string",
  "type": "string",
  "points": 0,
  "date": "ISO-8601 datetime",
  "description": "string|null",
  "netAmount": 0,
  "billAmount": 0,
  "discountAmount": 0,
  "referenceId": "string|null",
  "reason": "string|null",
  "scanMethod": "string|null",
  "moneyAmount": 0,
  "ruleAmountPer": 0,
  "rulePointsPer": 0,
  "note": "string|null"
}
```

---

## 4) Coupons and Redemption

### POST `/customer/coupons/{couponId}/redeem`

Redeems a coupon with customer points.

- Auth: `CUSTOMER`
- Path params: `couponId` (Long)

Success: `201 Created`

Response shape (`CouponRedeemResponse`):
```json
{
  "customerCouponId": 0,
  "couponId": 0,
  "status": "REDEEMED|USED|EXPIRED|CANCELLED",
  "pointsSpent": 0,
  "remainingBalance": 0,
  "currency": "LEK|DOLLAR|EURO",
  "redeemedAt": "ISO-8601 datetime",
  "expiresAt": "ISO-8601 datetime|null",
  "snapshotTitle": "string",
  "snapshotDescription": "string|null",
  "snapshotImageUrl": "string|null",
  "snapshotCouponType": "FREE_PRODUCT|PERCENTAGE_DISCOUNT|FIXED_AMOUNT_DISCOUNT"
}
```

### GET `/customer/my-coupons`

Returns coupons owned by customer.

- Auth: `CUSTOMER`

Response: array of `CustomerCouponDetailResponse`.

### POST `/customer/customer-coupons/{customerCouponId}/apply`

Applies an owned coupon to an order context.

- Auth: `CUSTOMER`
- Path params: `customerCouponId` (Long)
- Request body (optional):
```json
{ "orderId": "string" }
```

Response: `CustomerCouponDetailResponse`.

### POST `/customer/customer-coupons/{customerCouponId}/use`

Marks an applied/redeemed coupon as used.

- Auth: `CUSTOMER`
- Path params: `customerCouponId` (Long)

Response: `CustomerCouponDetailResponse`.

### GET `/customer/businesses/{businessId}/available-coupons`

Returns coupons available for redemption in business context.

- Auth: `CUSTOMER`
- Path params: `businessId` (Long)

Response shape (`AvailableCouponsResponse`):
```json
{
  "customerPointBalance": 0,
  "businessCurrency": "LEK|DOLLAR|EURO",
  "coupons": [
    {
      "couponId": 0,
      "type": "FREE_PRODUCT|PERCENTAGE_DISCOUNT|FIXED_AMOUNT_DISCOUNT",
      "title": "string",
      "description": "string|null",
      "imageUrl": "string|null",
      "pointsCost": 0,
      "currency": "LEK|DOLLAR|EURO",
      "startDate": "ISO-8601 datetime|null",
      "endDate": "ISO-8601 datetime|null",
      "totalRedemptionLimit": 0,
      "totalRedemptions": 0,
      "perCustomerRedemptionLimit": 0,
      "termsAndConditions": "string|null",
      "isFeatured": false,
      "canRedeem": true,
      "cannotRedeemReason": "string|null"
    }
  ]
}
```

### POST `/customer/coupons/{couponId}/validate-redemption`

Pre-checks whether current customer can redeem a coupon.

- Auth: `CUSTOMER`
- Path params: `couponId` (Long)

Response:
```json
{
  "canRedeem": true,
  "reason": "string|null",
  "pointsRequired": 0,
  "customerBalance": 0
}
```

---

## 5) Points History and Loyalty Card

### GET `/customer/points-transactions`

Returns all customer points transactions.

- Auth: `CUSTOMER`

Response item (`PointTransactionCustomerAllListViewDto`):
```json
{
  "id": 0,
  "businessName": "string",
  "businessLocation": "string|null",
  "businessLogoPath": "string|null",
  "billTransactionReferenceId": "string|null",
  "type": "string",
  "points": 0,
  "netAmount": 0,
  "discountAmount": 0,
  "billAmount": 0,
  "createdAt": "ISO-8601 datetime"
}
```

### GET `/customer/points-transactions/business/{businessId}`

Returns points transactions filtered by business.

- Auth: `CUSTOMER`
- Path params: `businessId` (Long)

Response item (`PointTransactionCustomerBusinessListViewDto`):
```json
{
  "id": 0,
  "billTransactionReferenceId": "string|null",
  "type": "string",
  "points": 0,
  "netAmount": 0,
  "discountAmount": 0,
  "billAmount": 0,
  "createdAt": "ISO-8601 datetime"
}
```

### GET `/customer/me/loyalty-card`

Returns loyalty card details for current customer.

- Auth: `CUSTOMER`

Response:
```json
{
  "firstName": "string",
  "lastName": "string",
  "qrToken": "string",
  "manualCode": "string"
}
```

---

## Common Error Expectations

Exact error JSON depends on global exception handlers, but typical cases:

- `400 Bad Request`: validation errors, malformed payloads, business rules violated.
- `401 Unauthorized`: missing/invalid JWT.
- `403 Forbidden`: authenticated but lacks required role.
- `404 Not Found`: resource (business/coupon/customer-coupon) not found.

---

## Integration Checklist for Frontend

- Use `GET /customer/me/details` as the primary source for all profile tab display and edits — it now includes all editable fields.
- `profileImageUrl` is available on both `/user-profile/me` and `/customer/me/details.profile`. `imagePath` on `/user-profile/me` is the same value, kept for backward compatibility.
- `acceptedTerms` is now returned by both `/user-profile/me` and `/customer/me/details.profile`.
- `POST /user-profile/change-password` returns `{ message, accessToken, refreshToken }` — rotate both tokens in the client session immediately on success.
- `PATCH /customer/me` with `birthDate` now persists correctly. Use `null` to clear.
- Keep enums strict:
  - `gender`: `MALE|FEMALE|OTHER|PREFER_NOT_TO_SAY`
  - `status`: `ENABLED|DISABLED|LOCKED|PENDING_VERIFICATION|BLOCKED|REJECTED|INVITED`
  - `currency`: `LEK|DOLLAR|EURO`
  - `coupon type`: `FREE_PRODUCT|PERCENTAGE_DISCOUNT|FIXED_AMOUNT_DISCOUNT`
  - `customer coupon status`: `REDEEMED|USED|EXPIRED|CANCELLED`
