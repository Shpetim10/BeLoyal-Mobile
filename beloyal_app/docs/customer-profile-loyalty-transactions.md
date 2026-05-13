# Customer Profile, Points Calculation, Rewards & Transaction Details

## Summary of Changes

| Task | Area | Change |
|------|------|--------|
| 1 | Customer Profile | New `GET /api/besahub/customer/me/details` endpoint |
| 2 | Points Calculation | Centralized via `PointsCalculatorService`; added `enabled`/`configured` guards |
| 3 | Next Reward | Filters out coupons where customer has exhausted per-customer quota |
| 4 | Transaction Details | `CustomerTransactionDto` expanded to match `CustomerBusinessTransactionDto` |

---

## Task 1 — Customer Profile Details Endpoint

### Endpoint

```
GET /api/besahub/customer/me/details
Authorization: Bearer <jwt>   (CUSTOMER role required)
```

No request parameters or body.

### Response

```json
{
  "profile": {
    "firstName": "John",
    "lastName": "Doe",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phoneNumber": "+355691234567",
    "profileImageUrl": null,
    "avatarInitials": "JD",
    "status": "Not available",
    "memberSince": "January 2024",
    "memberCode": "BL-123456"
  },
  "stats": {
    "currentPoints": 250,
    "lifetimePoints": 1000,
    "spentPoints": 750,
    "businessesVisited": 3,
    "activeCoupons": 2,
    "activeRewards": 1,
    "memberSinceLabel": "January 2024",
    "memberCode": "BL-123456"
  }
}
```

### Field Descriptions

**profile**

| Field | Source | Notes |
|-------|--------|-------|
| `firstName` | `User.firstName` | |
| `lastName` | `User.lastName` | |
| `fullName` | Concatenated | `firstName + " " + lastName` |
| `email` | `User.email` | |
| `phoneNumber` | `User.phoneNumber` | May be null |
| `profileImageUrl` | `User.profileImage` | Null if no image uploaded |
| `avatarInitials` | Derived | First letter of first + last name, uppercased |
| `status` | Hardcoded | Always `"Not available"` — no availability field exists yet |
| `memberSince` | `CustomerProfile.createdAt` | Formatted as `"Month YYYY"` |
| `memberCode` | `LoyaltyCard.manualCode` | The customer's scannable card code |

**stats** — reuses `CustomerSummaryDto`

| Field | Source | Notes |
|-------|--------|-------|
| `currentPoints` | Sum of `LoyaltyAccount.availablePoints` across all businesses | |
| `lifetimePoints` | Sum of `LoyaltyAccount.lifetimeEarned` | Total ever earned |
| `spentPoints` | Sum of `LoyaltyAccount.lifetimeRedeemed` | Total ever redeemed |
| `businessesVisited` | Count of loyalty accounts with activity | |
| `activeCoupons` | Count of `CustomerCoupon` records in `REDEEMED` status | |
| `activeRewards` | Count of businesses where `availablePoints >= minPointsToRedeem` | |
| `memberSinceLabel` | Same as `profile.memberSince` | Duplicated for backward compatibility |
| `memberCode` | Same as `profile.memberCode` | Duplicated for backward compatibility |

### Error Responses

| HTTP | Condition |
|------|-----------|
| 401 | Missing or invalid JWT |
| 403 | Authenticated user does not have CUSTOMER role |
| 404 | Customer profile or loyalty card not found |

### Flutter Integration Notes

- Use `profile.profileImageUrl` if non-null to render an image avatar; otherwise render `profile.avatarInitials` as a text avatar.
- `stats.activeRewards` is a count of businesses where the customer can already redeem points (they have enough for at least one reward). Use it for the "Active Rewards" chip.
- `stats.activeCoupons` counts owned coupons in `REDEEMED` (ready-to-use) status — not yet used or expired.
- `profile.status` is always `"Not available"` until an availability/presence feature is added to the backend.

---

## Task 2 — Points Calculation

### Entities Used

| Entity | Field | Role |
|--------|-------|------|
| `EarningSettings` | `pointsPer` | Points awarded per unit |
| `EarningSettings` | `amountPer` | Currency amount per unit (denominator) |
| `EarningSettings` | `enabled` | Guard: no points if disabled |
| `EarningSettings` | `configured` | Guard: no points if not yet configured |
| `LoyaltySettings` | `maxPointsPerTransactions` | Cap applied after base calculation |

### Formula

```
points = floor(billAmount / amountPer) × pointsPer
points = min(points, maxPointsPerTransactions)   -- if cap is set
```

### Guards (short-circuit to 0)

- `earningSettings` is null
- `earningSettings.enabled == false`
- `earningSettings.configured == false`
- `billAmount` is null
- `amountPer` is null or zero

### Rounding

`RoundingMode.DOWN` (floor) is applied on the division step. Partial units never earn points.

### Centralization

The single source of truth is `PointsCalculatorService.calculatePoints()` implemented in `PointsCalculatorServiceImpl`. Before this fix, `CustomerBusinessDetailServiceImpl` had a private duplicate of the same formula. It now delegates to the service, ensuring catalog item point previews and actual earn transactions always use the same logic.

### Catalog Display Logic

For catalog variants, `calculateEarnedPoints(price, earningSettings)` returns:
- `null` — earning is disabled/unconfigured, or price is null (Flutter hides the points label)
- `Integer` — the preview points for that variant's price

### Example Calculations

| billAmount | amountPer | pointsPer | maxCap | Result |
|-----------|-----------|-----------|--------|--------|
| 50.00 | 10.00 | 5 | — | 25 |
| 55.00 | 10.00 | 5 | — | 25 (floor) |
| 100.00 | 10.00 | 5 | 30 | 30 (capped) |
| 8.00 | 10.00 | 5 | — | 0 (below amountPer) |
| 50.00 | 10.00 | 5 | — | 0 if disabled |

---

## Task 3 — Next Reward Calculation

### Overview

`nextRewardPoints` is the minimum `pointsCost` among coupons the customer can realistically redeem next. It appears in `CustomerLoyaltyDto` inside `GET /api/besahub/customer/businesses/{businessId}`.

### Eligibility Rules (applied in order)

A coupon is considered for next reward **only if all of the following are true**:

| Rule | How enforced |
|------|-------------|
| Not deleted | `deletedAt IS NULL` |
| Status is ACTIVE | `status = 'ACTIVE'` |
| Publicly visible | `visibility = 'PUBLIC'` |
| Within date range | `startDate <= now AND endDate >= now` |
| Overall quota not exhausted | `totalRedemptionLimit IS NULL OR totalRedemptions < totalRedemptionLimit` |
| Per-customer quota not exhausted | `countByCouponIdAndCustomerProfileId(couponId, profileId) < perCustomerRedemptionLimit` (when limit is set) |

The first five filters are applied in `CouponRepository.findAvailableForBusiness()` (SQL). The per-customer quota is applied in-memory in `CustomerBusinessDetailServiceImpl.buildLoyalty()`.

### Fallback Behavior

If no valid redeemable coupon exists after all filters:

- If `LoyaltySettings` is configured: `nextRewardPoints = max(1, minPointsToRedeem)`
- Otherwise: `nextRewardPoints = 1`

### pointsToNextReward

```
pointsToNextReward = max(0, nextRewardPoints - currentPoints)
```

This is always ≥ 0. When the customer already has enough points it returns 0.

### Example Response — Valid Next Reward

```json
{
  "loyalty": {
    "currentPoints": 80,
    "nextRewardPoints": 100,
    "pointsToNextReward": 20
  }
}
```

### Example Response — No Valid Reward

When all coupons are expired/inactive/out of quota and `minPointsToRedeem = 50`:

```json
{
  "loyalty": {
    "currentPoints": 80,
    "nextRewardPoints": 50,
    "pointsToNextReward": 0
  }
}
```

---

## Task 4 — Transaction Details Alignment

### Problem

`GET /api/besahub/customer/transactions` returned `CustomerTransactionDto`, which was missing the following fields present in `CustomerBusinessTransactionDto` (used by the Business Details page):

| Missing Field | Source |
|---------------|--------|
| `reason` | `PointsTransaction.reason` |
| `scanMethod` | `PointsTransaction.scanMethod.name()` |
| `moneyAmount` | `PointsTransaction.moneyAmount` |
| `ruleAmountPer` | `PointsTransaction.ruleAmountPer` |
| `rulePointsPer` | `PointsTransaction.rulePointsPer` |
| `note` | `BillTransaction.note` |

### Fix

`CustomerTransactionDto` was expanded to include all six missing fields. `CustomerTransactionViewServiceImpl.toDto()` now populates them.

### Updated Endpoint

```
GET /api/besahub/customer/transactions
Authorization: Bearer <jwt>   (CUSTOMER role required)

Query params:
  ?type=EARN|REDEEM|COUPON_PURCHASE|EXPIRED|ADJUSTMENT   (optional)
```

### Full Response Example

```json
[
  {
    "id": 42,
    "businessId": 7,
    "businessName": "Coffee Corner",
    "type": "EARN",
    "points": 25,
    "date": "2024-03-15T14:30:00",
    "description": "You earned points at Coffee Corner on 15/03/2024 14:30 for a bill of value 50.00 you paid.",
    "netAmount": 50.00,
    "billAmount": 50.00,
    "discountAmount": 0.00,
    "referenceId": "INV-001",
    "reason": "You earned points at Coffee Corner on 15/03/2024 14:30",
    "scanMethod": "QR_CODE",
    "moneyAmount": 50.00,
    "ruleAmountPer": 10.00,
    "rulePointsPer": 5,
    "note": null
  }
]
```

### Field Descriptions (new fields)

| Field | Notes |
|-------|-------|
| `reason` | Short human-readable reason for the transaction |
| `scanMethod` | How the customer was scanned: `QR_CODE`, `MANUAL_CODE`, etc. Null for non-bill transactions |
| `moneyAmount` | The bill amount associated with this points transaction. May differ from `billAmount` for split bills |
| `ruleAmountPer` | The earning rule's denominator at time of transaction (for display: "per X currency") |
| `rulePointsPer` | The earning rule's numerator at time of transaction (for display: "earn N points") |
| `note` | Staff note on the bill, if provided |

### Flutter Integration Notes

- The Transactions page list and the Business Details transaction list now return the same set of fields, allowing a single transaction detail sheet component to be used in both contexts.
- `scanMethod` and `ruleAmountPer`/`rulePointsPer` are null for non-EARN transactions (redemptions, expirations, adjustments).
- For the full transaction detail view (including customer identity and balance snapshot), call `GET /api/besahub/transactions/{id}` which returns `PointTransactionViewDto` with additional fields: `customerFullName`, `availablePoints`, `lifetimeEarnedPoints`, `lifetimeExpired`, `lastActivityAt`, `businessMemberFullName`.

---

## Assumptions Made

1. **Status field**: There is no "availability" or "presence" status on the `User` entity. The value `"Not available"` is hardcoded. If a future feature adds an availability field, update `CustomerProfileDetailsServiceImpl.buildHeader()`.
2. **Points calculation guards in earn flow**: Adding `enabled`/`configured` checks to `PointsCalculatorService` is safe because `EarningSettingsService.getEarningSettings()` throws before reaching the calculator if settings don't exist. The guards are defence-in-depth.
3. **Per-customer quota check is in-memory**: The check iterates over available public coupons (already filtered to a small set by the SQL query) and issues one count query per coupon. For businesses with many coupons this is acceptable; a JOIN query can optimize this later if needed.
4. **`activeCoupons` definition**: Counts `CustomerCoupon` records in `REDEEMED` status (i.e., owned but not yet used/expired). Used status and expired status are excluded.

## Edge Cases Handled

- No loyalty accounts: `currentPoints`, `lifetimePoints`, `spentPoints` all return 0.
- No profile image: `profileImageUrl` is null; Flutter falls back to initials avatar.
- Earning disabled or not configured: `calculatePoints()` returns 0; catalog variant `earnedPoints` returns null (label hidden).
- All coupons exhausted per customer: `nextRewardPoints` falls back to loyalty settings minimum.
- No loyalty settings configured: `nextRewardPoints` falls back to 1.
- `pointsToNextReward` is always ≥ 0: customer already at or past threshold returns 0 not negative.
- Split-bill transactions: `moneyAmount` reflects the customer's share; `billAmount` on the bill record is the full bill.
