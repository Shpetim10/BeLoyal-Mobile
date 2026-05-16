# SuperAdmin and Customer Account Endpoints Documentation

## Overview
This document details all the new superadmin and customer account management endpoints added to the BeLoyal API. These endpoints allow platform administrators to manage businesses, monitor platform usage, and allow customers to manage their accounts.

---

## Superadmin Endpoints

### 1. Platform User Overview

**Endpoint:** `GET /api/besahub/admin/platform/users`

**Description:** Retrieves a comprehensive list of all platform users with their roles, business memberships, last login times, and loyalty metrics.

**Authentication:** Requires authentication

**Request:**
```http
GET /api/besahub/admin/platform/users
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "username": "johndoe",
    "email": "john@example.com",
    "phoneNumber": "+1234567890",
    "roles": ["SUPER_ADMIN", "CUSTOMER"],
    "status": "ACTIVE",
    "emailVerified": true,
    "lastLoginAt": "2026-05-15T10:30:00",
    "createdAt": "2026-01-01T08:00:00",
    "businessMemberships": [
      {
        "businessId": 1,
        "businessName": "ABC Retail",
        "role": "BUSINESS_ADMIN",
        "memberStatus": "ACTIVE"
      },
      {
        "businessId": 2,
        "businessName": "XYZ Services",
        "role": "STAFF",
        "memberStatus": "ACTIVE"
      }
    ],
    "loyaltySummary": {
      "totalEarned": 5000,
      "totalSpent": 2000,
      "totalExpired": 500,
      "availablePoints": 2500,
      "businessCount": 3
    }
  }
]
```

**Response Fields:**
- `id` - User's unique identifier
- `firstName`, `lastName`, `username`, `email`, `phoneNumber` - User contact information
- `roles` - Set of user roles (SUPER_ADMIN, CUSTOMER, BUSINESS_ADMIN, STAFF)
- `status` - User account status (ACTIVE, INACTIVE, DISABLED, LOCKED)
- `emailVerified` - Whether email is verified
- `lastLoginAt` - Last login timestamp
- `createdAt` - Account creation timestamp
- `businessMemberships` - List of BUSINESS_ADMIN and STAFF roles only (CUSTOMER memberships excluded)
- `loyaltySummary` - Loyalty metrics (only present for CUSTOMER role users)
  - `totalEarned` - Total points earned across all loyalty accounts
  - `totalSpent` - Total points redeemed across all loyalty accounts
  - `totalExpired` - Total expired points across all loyalty accounts
  - `availablePoints` - Current available points across all loyalty accounts
  - `businessCount` - Number of businesses the customer is enrolled in

---

## Business Lifecycle Management

### 2. Suspend Business

**Endpoint:** `PATCH /api/besahub/admin/businesses/{id}/suspend`

**Description:** Suspends a business, preventing it from being visible and operating transactions. Sends informative email to all business admins and staff.

**Authentication:** Requires SUPER_ADMIN role

**Request:**
```http
PATCH /api/besahub/admin/businesses/123/suspend
Content-Type: application/json

{
  "reason": "Violation of platform policies"
}
```

**Response (200 OK):** Empty body

**Status Transition:** Any status → INACTIVE

**Side Effects:**
- Business status changed to INACTIVE
- Email notification sent to all business admins and staff
- Email contains reason for suspension

---

### 3. Ban Business

**Endpoint:** `PATCH /api/besahub/admin/businesses/{id}/ban`

**Description:** Permanently bans a business. Sends ban notification email to all business admins and staff.

**Authentication:** Requires SUPER_ADMIN role

**Request:**
```http
PATCH /api/besahub/admin/businesses/123/ban
Content-Type: application/json

{
  "reason": "Repeated policy violations"
}
```

**Response (200 OK):** Empty body

**Status Transition:** Any status → BANNED

**Side Effects:**
- Business status changed to BANNED
- Email notification sent to all business admins and staff
- Email indicates permanent ban with reason

---

### 4. Reactivate Business

**Endpoint:** `PATCH /api/besahub/admin/businesses/{id}/reactivate`

**Description:** Reactivates a suspended or banned business. Sends reactivation notification to all business members.

**Authentication:** Requires SUPER_ADMIN role

**Request:**
```http
PATCH /api/besahub/admin/businesses/123/reactivate
```

**Response (200 OK):** Empty body

**Status Transition:** INACTIVE or BANNED → ACTIVE

**Side Effects:**
- Business status changed to ACTIVE
- Email notification sent to all business admins and staff
- Email includes link to business portal

---

### 5. Hard Delete Business

**Endpoint:** `DELETE /api/besahub/admin/businesses/{id}`

**Description:** Permanently deletes a business and all associated data. Respects foreign key constraints and user role preservation.

**Authentication:** Requires SUPER_ADMIN role

**Request:**
```http
DELETE /api/besahub/admin/businesses/123
```

**Response (204 No Content):** Empty body

**Deletion Order (respects FK constraints):**
1. Points bucket consumption records
2. Points transactions and buckets
3. Bill transactions
4. Customer coupons (all redemptions)
5. Coupon discount and free product details
6. Loyalty coupons
7. Loyalty cards
8. Loyalty accounts
9. Loyalty and earning settings
10. Catalog item variants, items, and categories
11. Staff invite tokens for the business
12. Business members and associated users (with conditions)

**User Deletion Logic:**
- If a user has multiple business memberships, only the membership is deleted
- If a user only has BUSINESS_ADMIN/STAFF role (no CUSTOMER role), the user record is deleted
- If a user has CUSTOMER role, the user record is preserved (loyalty customers cannot be deleted via business deletion)

**Constraints:**
- Cannot delete users with CUSTOMER role
- Preserves user records for staff-only members to maintain referential integrity for other business memberships

---

## Customer Account Management

### 6. Create Customer Profile

**Endpoint:** `POST /api/besahub/customer/profile`

**Description:** Allows authenticated business members without a customer profile to create one. Enables them to participate in loyalty programs.

**Authentication:** Requires authentication (any authenticated user)

**Request:**
```http
POST /api/besahub/customer/profile
Content-Type: application/json

{
  "birthdate": "1990-05-15",
  "gender": "MALE",
  "city": "San Francisco",
  "country": "United States",
  "referredBy": "referral_code_123",
  "profileImageUrl": "https://cdn.example.com/profile.jpg",
  "profileImageKey": "profile/user123.jpg",
  "notificationEnabled": true
}
```

**Request Fields:**
- `birthdate` - Date of birth (ISO format, must be in the past)
- `gender` - Gender (MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY)
- `city` - City of residence (max 100 characters)
- `country` - Country of residence (max 100 characters)
- `referredBy` - Referral code if customer was referred (optional)
- `profileImageUrl` - URL to profile image (optional)
- `profileImageKey` - S3/storage key for profile image (optional)
- `notificationEnabled` - Whether to receive notifications (default: true)

**Response (201 Created):**
```json
{
  "id": 456,
  "user": {
    "id": 123,
    "email": "user@example.com"
  },
  "referralCode": "CUST_ABC123XYZ",
  "referredBy": "referral_code_123",
  "birthDate": "1990-05-15",
  "gender": "MALE",
  "city": "San Francisco",
  "country": "United States",
  "notificationEnabled": true,
  "createdAt": "2026-05-16T10:30:00",
  "updatedAt": "2026-05-16T10:30:00"
}
```

**Side Effects:**
- Creates CustomerProfile entity
- Generates unique referral code for the customer
- Adds CUSTOMER role to user if not already present
- Updates user profile image if provided

**Error Responses:**
- `400 Bad Request` - Invalid input or birthdate validation failed
- `404 Not Found` - User not found
- `409 Conflict` - Customer profile already exists for this user

---

### 7. Delete Customer Account

**Endpoint:** `DELETE /api/besahub/customer/account`

**Description:** Allows customers to delete their account and all associated customer data. Does NOT affect business membership data or staff roles.

**Authentication:** Requires CUSTOMER role

**Request:**
```http
DELETE /api/besahub/customer/account
```

**Response (204 No Content):** Empty body

**Deletion Scope (Customer Data Only):**
1. Points bucket consumption records
2. Points transactions and buckets
3. Customer coupons (redemptions)
4. Loyalty cards
5. Loyalty accounts
6. Customer profile

**Preservation (Business Data):**
- User record is retained to preserve business membership history
- Business admin and staff roles are NOT affected
- Business member records remain intact
- Bill transactions and business history are preserved

**Constraints:**
- Only callable by authenticated users with CUSTOMER role
- Customer profile must exist
- All customer loyalty data is permanently deleted

**Important Notes:**
- This operation is irreversible
- User can re-register as a customer later
- Business membership data and staff roles are preserved
- Recommended: Implement confirmation/warning UI on client side

---

## Error Handling

### Common HTTP Status Codes

- `200 OK` - Successful GET or update operation
- `201 Created` - Resource successfully created
- `204 No Content` - Successful DELETE operation
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions (wrong role)
- `404 Not Found` - Resource not found
- `409 Conflict` - Business logic conflict (e.g., profile already exists)
- `500 Internal Server Error` - Server error

### Error Response Format

```json
{
  "timestamp": "2026-05-16T10:30:00",
  "status": 400,
  "error": "Bad Request",
  "message": "Customer profile already exists for this user",
  "path": "/api/besahub/customer/profile"
}
```

---

## Security & Authorization

### Role Requirements

| Endpoint | Required Role | Description |
|----------|---------------|-------------|
| GET /api/besahub/admin/platform/users | SUPER_ADMIN | View all platform users |
| PATCH /api/besahub/admin/businesses/{id}/suspend | SUPER_ADMIN | Suspend business operations |
| PATCH /api/besahub/admin/businesses/{id}/ban | SUPER_ADMIN | Ban business permanently |
| PATCH /api/besahub/admin/businesses/{id}/reactivate | SUPER_ADMIN | Reactivate business |
| DELETE /api/besahub/admin/businesses/{id} | SUPER_ADMIN | Delete business and data |
| POST /api/besahub/customer/profile | Authenticated | Create own customer profile |
| DELETE /api/besahub/customer/account | CUSTOMER | Delete own customer account |

### Data Isolation

- Superadmin endpoints operate at platform level (unrestricted)
- Customer endpoints are restricted to the authenticated user's own data
- Business deletion respects user role hierarchy (CUSTOMER users are preserved)
- No cross-business data leakage

---

## Email Notifications

### Business Suspension Email
- **Recipient:** All business admins and staff, plus business email
- **Subject:** ⚠️ Your business has been suspended
- **Content:** Reason for suspension, support contact

### Business Ban Email
- **Recipient:** All business admins and staff, plus business email
- **Subject:** 🔒 Your business has been banned
- **Content:** Permanent ban notification, reason, support contact

### Business Reactivation Email
- **Recipient:** All business admins and staff, plus business email
- **Subject:** ✅ Your business is now active
- **Content:** Reactivation confirmation, link to business portal

---

## Related Documentation

- Business Management: See `Business.java` and `BusinessStatus` enum
- User Management: See `User.java` and `UserRepository`
- Loyalty System: See `LoyaltyAccount`, `LoyaltyCard`, `PointsBucket` entities
- Customer Profiles: See `CustomerProfile.java`
