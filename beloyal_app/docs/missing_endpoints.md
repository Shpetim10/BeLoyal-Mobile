# Missing / Needed Backend Endpoints

This file documents API endpoints that are required by the Flutter app but are
not yet confirmed to exist on the backend. If an endpoint already exists with a
different path or schema, update this file accordingly.

---

## 1. Update Customer Profile

**Used by:** `CustomerProfileEditPage` (profile tab pen-icon edit flow)

| Field | Value |
|-------|-------|
| Method | `PUT` |
| Path | `/customer/me` |
| Auth | Bearer token (customer role) |

### Request body (JSON)

```json
{
  "firstName": "string",
  "lastName": "string",
  "phoneNumber": "string (optional)"
}
```

### Expected response

```json
{
  "success": true
}
```

Or a `204 No Content` response is acceptable — the app refreshes
`GET /customer/me/details` immediately after a successful `PUT`.

### Notes

- `email` is intentionally excluded from the update body; email changes
  require a separate verification flow.
- `status`, `memberCode`, and `memberSince` are read-only from the client.
- If the endpoint path differs (e.g. `PATCH /customer/profile`), update
  `CustomerRepository.updateProfile()` in
  `lib/features/customer_ui/data/repositories/customer_repository.dart`.

---

## 2. Full Transaction Detail Endpoint (Nice-to-have)

**Context:** The `GET /customer/home` response returns transactions with a
minimal field set (id, businessId, businessName, type, points, date,
description). The `GET /customer/businesses/{id}` response returns the same
transactions enriched with:

- `billAmount`
- `netAmount`
- `discountAmount`
- `moneyAmount`
- `referenceId`
- `invoiceReference`
- `note`
- `reason`
- `scanMethod`
- `ruleAmountPer`
- `rulePointsPer`

As a result, the transaction detail sheet opened from the **Orders tab** may
show fewer rows than the same sheet opened from the **Business Detail** page.

**Current workaround:** The orders tab attempts to look up the matching
transaction from the `customerBusinessDetailProvider` Riverpod cache. If the
user has already visited that business's detail page in the current session,
the richer data is used automatically. On a fresh session, only home-endpoint
data is available.

### Recommended fix options (pick one)

**Option A — Enrich `/customer/home` transactions**

Return the full transaction field set in the `transactions` array of the home
response. No new endpoint needed; just more data in the existing response.

**Option B — New transactions endpoint**

| Field | Value |
|-------|-------|
| Method | `GET` |
| Path | `/customer/transactions` |
| Auth | Bearer token (customer role) |
| Query params | `page`, `limit`, `businessId` (optional filter) |

Returns a paginated list of fully-enriched transactions (same schema as
`/customer/businesses/{id}` transactions).

---

*Last updated: 2026-05-13*
