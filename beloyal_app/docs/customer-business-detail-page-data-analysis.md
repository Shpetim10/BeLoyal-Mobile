# Customer Business Detail Page Data Analysis

This document describes all customer-facing data currently displayed on the business detail page implemented in [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:15).

## Scope

- Page: `CustomerBusinessDetailPage`
- Main sources:
  - `GET /customer/home` via [customer_repository.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/repositories/customer_repository.dart:10)
  - `GET /customer/businesses/{businessId}` via [customer_repository.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/repositories/customer_repository.dart:15)
- Providers:
  - `customerDataProvider` loads home data and maps it into `CustomerDataSource` ([customer_providers.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/providers/customer_providers.dart:23))
  - `customerBusinessDetailProvider` loads per-business detail and maps it into `CustomerBusinessDetail` ([customer_providers.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/providers/customer_providers.dart:28))

## High-level Page Composition

The page is built from:

1. Hero app bar
2. Business identity block
3. Points card
4. Horizontal tab bar
5. Seven tab panels:
   - Overview
   - Menu
   - Coupons & Offers
   - Rewards
   - Transactions
   - Location
   - Info

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:44)

## Data Model Summary

The page renders data from these mapped UI models:

- `CustomerBusiness`: business header/basic info ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:21))
- `CustomerBusinessDetail`: business-specific detail payload ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:303))
- `CustomerCoupon`: coupons and offers ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:65))
- `CustomerReward`: rewards ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:121))
- `CustomerTransaction`: transactions ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:147))
- `CustomerMenuItem`, `CustomerMenuVariant`, `CustomerMenuCategory`: menu data ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:177), [customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:206), [customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:255))
- `CustomerBusinessLocation`: location data ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:220))

## Data Source and Fallback Rules

### Home vs business-detail payload usage

- The page always receives a `CustomerBusiness` object from home data.
- It also separately requests `CustomerBusinessDetail` for the selected business.
- Some tabs prefer detail data when available and fall back to home data otherwise:
  - Coupons tab: `detailData?.coupons ?? data.couponsForBusiness(_b.id)`
  - Transactions tab: `detailData?.transactions ?? data.transactionsForBusiness(_b.id)`
  - Location tab: `detailData?.location`
  - Info tab: `detailData?.loyaltyPolicy` and `detailData?.about`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:508)

### Important mapped/derived behavior

- Rewards are not fetched as a dedicated business reward payload on this page. They are derived from each `CustomerBusiness` using `points` and `nextRewardPoints` in `_mapRewardFromBusiness` ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:351)).
- Menu items from the detail endpoint are filtered to only `isAvailable == true` before display ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:43)).
- If coupon ownership is not explicitly included in `/customer/home`, every mapped coupon is normalized to `isOwned: true` ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:262)).
- Business distance is currently hardcoded to `Unavailable` in the mapper ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:336)).
- Opening hours are currently hardcoded to `Unavailable` in the mapper and also rendered as unavailable in the Location tab ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:343), [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2343)).
- Coupon `discountValue` is currently always mapped as `0`; the UI relies on `discountDisplay` instead ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:388)).
- Transaction `discountAmount` exists in the UI model but is not populated by the current mapper from `CustomerTransactionDto` ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:160), [customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:418)).

## Page Header and Summary Area

### Hero app bar

Displayed data:

- Back button
- Share icon
- Business logo emoji: `CustomerBusiness.logoEmoji`
- Open/closed badge: `CustomerBusiness.isOpen`
- Gradient visual theme: `CustomerBusiness.gradientColors`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:80)

Notes:

- Share button `onPressed` is empty.
- `logoEmoji` is derived from `categoryKey`, not from a backend image/logo URL ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:339), [customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:463)).

### Business info block

Displayed data:

- Business name: `CustomerBusiness.name`
- Rating: `CustomerBusiness.rating`
- Category chip label: `CustomerBusiness.category`
- Distance: `CustomerBusiness.distance`
- Description: `CustomerBusiness.description`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:233)

Notes:

- Rating falls back to `0.0` if absent in the home payload ([customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:338)).
- Distance is currently not API-backed and always shows `Unavailable` unless mapping logic changes.

### Points card

Displayed data:

- Label: `Your Points`
- Current points:
  - prefers `CustomerBusinessDetail.currentPoints`
  - falls back to `CustomerBusiness.points`
- Progress bar:
  - computed as `points / nextRewardPoints`
- Remaining points text:
  - computed as `nextRewardPoints - points`
- Rewards shortcut button

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:325)

Notes:

- The card prefers business-detail loyalty data when available.
- The “Rewards” button just switches the local tab selection to the Rewards tab.

## Tab-by-tab Analysis

### 1. Overview tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:542)

#### Quick actions

Displayed items:

- `Scan & Earn`
- `My Coupons`
- `Directions`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:562)

Notes:

- All three buttons currently have empty `onTap` handlers.

#### Active Coupons subsection

Data source:

- `data.couponsForBusiness(business.id)`
- filtered to statuses `active` or `expiring`
- limited to first 3 items

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:549)

Displayed per coupon row:

- Coupon icon area:
  - `discountDisplay` if short enough
  - otherwise `🎁` for `FREE_PRODUCT`
  - otherwise `%`
- Title: `CustomerCoupon.title`
- Point cost: `CustomerCoupon.pointCost`
- Status chip:
  - `Expiring` when status is `expiring`
  - `Active` otherwise

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:704)

#### Current Offers subsection

Data source:

- `data.offersForBusiness(business.id)`
- this is based on `CustomerCoupon.isHot == true`

Reference: [customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:232)

Displayed per offer row:

- Leading badge text:
  - `multiplierLabel` if present
  - otherwise `discountDisplay`
- Title: `CustomerCoupon.title`
- Description: `CustomerCoupon.description`
- `HOT` chip when `CustomerCoupon.isHot == true`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:797)

#### Available Rewards subsection

Data source:

- `data.rewardsForBusiness(business.id).take(3)`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:555)

Displayed per reward row:

- Reward title: `CustomerReward.title`
- Required points: `CustomerReward.pointCost`
- If redeemable:
  - `Redeem` pill
- If not redeemable:
  - `{pointCost - currentPoints} pts away`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:884)

#### Empty state

Shown when:

- no active coupons
- no offers
- no rewards

Displayed text:

- `Nothing active right now. Check back soon for offers!`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:607)

### 2. Menu tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:996)

Data source:

- `CustomerBusinessDetail.menuCategories`
- `CustomerBusinessDetail.menuItems`

Mapping reference:

- categories/variants/items are mapped from `CustomerBusinessDetailDto.catalog` in [customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:28)

#### Category filter row

Displayed data:

- fixed chip: `All`
- one chip per `CustomerMenuCategory.name`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1078)

Notes:

- Category filtering is local in memory using `itemsForCategory(categoryId)`.

#### Empty/loading/error states

Displayed text:

- Loading: skeleton placeholders
- Error: `Could not load menu. Pull to refresh.`
- Empty: `No menu available yet.`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1013)

#### Menu item cards

Displayed per menu item:

- Emoji: `CustomerMenuItem.emoji`
- Name: `CustomerMenuItem.name`
- `Popular` badge when `CustomerMenuItem.isPopular == true`
- Description: `CustomerMenuItem.description`
- Availability opacity:
  - full opacity when available
  - reduced opacity when unavailable
- Pricing/options area based on variants

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1213)

Single-variant display:

- Variant formatted price: `CustomerMenuVariant.formattedPrice`
- Earn label:
  - `+{earnedPoints} pts` when variant has `earnedPoints`
  - otherwise uses `CustomerMenuItem.pointsLabel` when present

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1355)

Multi-variant display:

- One pill per variant with:
  - `CustomerMenuVariant.name`
  - `CustomerMenuVariant.formattedPrice`
  - optional `+{earnedPoints} pts`
- Default variant gets highlighted styling
- If no variant exposes earned points, a bottom `pointsLabel` badge is shown when `CustomerMenuItem.pointsLabel` exists

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1401)

#### Menu item detail sheet

Opened on card tap via `CustomerMenuItemDetailSheet.show(...)`.

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1060), [customer_menu_item_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_menu_item_detail_sheet.dart:6)

Displayed in the sheet:

- Emoji hero: `item.emoji`
- Item name: `item.name`
- `Popular` badge when applicable
- Menu category: `item.menuCategory`
- Availability chip: `Available` or `Unavailable`
- Description section when `item.description` is not empty
- `Options & Pricing` section with one row per variant:
  - `Default` tag when `variant.isDefault == true`
  - variant name
  - optional `+{earnedPoints} pts`
  - formatted price
- Bottom points banner when `item.pointsLabel` exists and no variant has earned points

Reference: [customer_menu_item_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_menu_item_detail_sheet.dart:71)

### 3. Coupons & Offers tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1495)

Data source:

- prefers `CustomerBusinessDetail.coupons`
- falls back to `CustomerDataSource.couponsForBusiness(businessId)`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:516)

#### Empty state

Displayed text:

- `No coupons for this business yet.`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1501)

#### Coupon card fields

Displayed per coupon:

- Discount panel:
  - `CustomerCoupon.discountDisplay`
  - type icon based on `CustomerCoupon.type`
- Title: `CustomerCoupon.title`
- Optional `Featured` badge when `CustomerCoupon.isFeatured == true`
- Status chip:
  - `Active`
  - `Expiring`
  - `Used`
  - `Expired`
- Optional description preview: `CustomerCoupon.description`
- Expiry text:
  - `Expires in {hours}h`
  - `Expires in {days}d`
  - `Expired {days}d ago`
- `Use Now` CTA when status is active/expiring
- Point cost row when `pointCost > 0`
- Usage text when `usageLimit != null`
- Redemption text when `totalRedemptionLimit != null`
- Terms preview footer when `termsAndConditions` is not empty

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1519)

Notes:

- Used/expired coupons are dimmed.
- Offer-style entries are still rendered through the same `CustomerCoupon` model.

#### Coupon detail sheet

Opened on tap via `CustomerCouponDetailSheet.show(context, coupon)`.

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1517), [customer_coupon_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart:7)

Displayed in the sheet:

- Hero discount card:
  - `discountDisplay`
  - human-readable type label
  - type icon
- Title: `coupon.title`
- Status chip
- Optional `Featured` badge
- Business name: `coupon.businessName`
- Full description when present
- Details box:
  - `Expires`
  - `Type`
  - `Point Cost` when `pointCost > 0`
  - `Usage` when `usageLimit != null`
  - `Total Redemptions` when `totalRedemptionLimit != null`
- `Terms & Conditions` section when present
- Bottom `Use Now` CTA when coupon is active or expiring

Reference: [customer_coupon_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart:104)

### 4. Rewards tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1829)

Data source:

- `data.rewardsForBusiness(_b.id)`
- these rewards are generated from the home business payload, not a dedicated rewards list

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:519), [customer_data_source.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_data_source.dart:351)

#### Empty state

- `No reward threshold available for this business yet.`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1835)

#### Reward card fields

Displayed per reward:

- Gift icon
- Reward title: `CustomerReward.title`
- Optional `Redeem!` badge when `currentPoints >= pointCost`
- Description: `CustomerReward.description`
- Progress bar:
  - `currentPoints / pointCost`
- Progress text:
  - redeemable: `{pointCost} pts — Ready to redeem!`
  - otherwise: `{remaining} pts to go · {pointCost} pts total`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1850)

Notes:

- Reward title and description are derived strings:
  - `Reward unlocked`
  - `Next reward at {business.name}`

### 5. Transactions tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1972)

Data source:

- prefers `CustomerBusinessDetail.transactions`
- falls back to `CustomerDataSource.transactionsForBusiness(businessId)`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:520)

#### Empty state

- `No transactions at this business yet.`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1978)

#### Transaction list card fields

Displayed per transaction:

- Type-colored circular icon:
  - `EARN`
  - `REFUND`
  - `ADJUSTMENT`
  - `EXPIRED`
  - other values use the fallback/downward icon path
- Description: `CustomerTransaction.description`
- Date/time formatted as `MMM d – h:mm a`
- Point value: `CustomerTransaction.points`
- Static `pts` label

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:1993)

Notes:

- The list card does not display bill or net amounts directly.

#### Transaction detail sheet

Opened on tap via `CustomerTransactionDetailSheet.show(context, tx)`.

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2013), [customer_transaction_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart:7)

Displayed in the sheet:

- Business emoji: `tx.logoEmoji`
- Business name: `tx.businessName`
- Full timestamp formatted as `EEEE, MMM d yyyy • h:mm a`
- Large points total
- Type pill with label:
  - `Earned`
  - `Redeemed`
  - `Refunded`
  - `Expired`
  - `Adjustment`
  - `Coupon Purchase`
- Detail rows:
  - Description
  - Bill Amount when `billAmount > 0`
  - Net Amount when `netAmount > 0`
  - Discount when `discountAmount != null && > 0`
  - Reference when present
  - Transaction ID

Reference: [customer_transaction_detail_sheet.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/widgets/customer_transaction_detail_sheet.dart:72)

Important caveat:

- `discountAmount` is never mapped from `CustomerTransactionDto`, so the discount row is currently effectively unreachable unless another code path populates it.

### 6. Location tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2089)

Data source:

- `CustomerBusinessDetail.location` when detail data is available
- business fallback values:
  - `business.address`
  - `business.name`

#### Decorative hero

Displayed data:

- Business name: `business.name`
- Map label:
  - prefers `location.mapLabel`
  - falls back to `business.address`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2149)

#### Address card

Displayed data:

- Section label: `Address`
- Address line 1:
  - prefers `location.addressLine1`
  - falls back to `business.address`
- Secondary line assembled from:
  - `city`
  - `postalCode`
  - `country`
- `Copy` action that copies the assembled full address

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2217)

#### Opening hours card

Displayed data:

- Label: `Opening Hours`
- Value: `Unavailable`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2343)

#### Directions CTA

Displayed data:

- `Get Directions`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2393)

Notes:

- The directions button currently has an empty tap handler.
- Latitude/longitude exists in the DTO/model but is not rendered or used for map launching here ([customer_ui_models.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/domain/models/customer_ui_models.dart:228), [customer_home_dto.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/models/customer_home_dto.dart:372)).

### 7. Info tab

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2461)

Displayed data:

- About:
  - prefers `CustomerBusinessDetail.about`
  - falls back to `CustomerBusiness.description`
- Phone: `CustomerBusiness.phone`
- Email: `CustomerBusiness.email`
- Category: `CustomerBusiness.category`
- Loyalty Policy:
  - prefers `CustomerBusinessDetail.loyaltyPolicy`
  - falls back to `Earn points on every purchase. Redeem rewards at any time.`

Reference: [customer_business_detail_page.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/presentation/pages/customer_business_detail_page.dart:2468)

Notes:

- Empty values for About/Phone/Email/Category are hidden by `_InfoRow` returning an empty widget when `value.isEmpty`.

## Backend Field Inventory by UI Section

### `/customer/home` fields used by this page

Business payload fields consumed from `CustomerBusinessDto`:

- `id`
- `name`
- `categoryId`
- `categoryKey`
- `categoryLabel`
- `points`
- `nextRewardPoints`
- `hasLogo`
- `hasOffer`
- `rating`
- `isOpen`
- `address`
- `phone`
- `email`
- `description`
- `offerLabel`

Reference: [customer_home_dto.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/models/customer_home_dto.dart:133)

Promotion fields consumed from `CustomerPromotionDto`:

- `id`
- `businessId`
- `businessName`
- `title`
- `description`
- `promotionType`
- `status`
- `discountDisplay`
- `pointCost`
- `isHot`
- `isUsed`
- `isOwned`
- ownership aliases for normalization
- `usageCount`
- `isFeatured`
- `totalRedemptions`
- `usageLimit`
- `expiresAt`
- `termsAndConditions`
- `imageUrl`
- `currency`
- `totalRedemptionLimit`
- `startDate`

Reference: [customer_home_dto.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/models/customer_home_dto.dart:195)

Transaction fields consumed from `CustomerTransactionDto`:

- `id`
- `businessId`
- `businessName`
- `type`
- `points`
- `date`
- `description`
- `netAmount`
- `billAmount`
- `referenceId`

Reference: [customer_home_dto.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/models/customer_home_dto.dart:287)

### `/customer/businesses/{businessId}` fields used by this page

Business detail fields consumed:

- `business.id`
- `business.name`
- `business.categoryId`
- `business.categoryKey`
- `business.categoryLabel`
- `business.hasLogo`
- `business.location.*`
- `business.rating`
- `business.logoUrl`
- `business.description`
- `business.address`
- `business.phone`
- `business.email`
- `loyalty.currentPoints`
- `loyalty.nextRewardPoints`
- `loyalty.pointsToNextReward`
- `loyalty.memberCode`
- `loyalty.loyaltyPolicy`
- `catalog.categories[*]`
- `catalog.items[*]`
- `catalog.variants[*]`
- `coupons[*]`
- `transactions[*]`
- `details.about`

Detail DTO reference: [customer_home_dto.dart](/Users/shpetimshabanaj/Development/BesaHub/BeLoyal-Mobile/beloyal_app/lib/features/customer_ui/data/models/customer_home_dto.dart:654)

## Gaps and Implementation Notes

- Share action is visible but not implemented.
- Overview quick actions are visible but not implemented.
- Directions CTA is visible but not implemented.
- Opening hours UI is present, but the value is not backed by API data.
- Distance UI is present, but the value is currently hardcoded to `Unavailable`.
- The UI model includes coupon `imageUrl`, business `hasLogo/logoUrl`, menu item `imageUrl`, and location coordinates, but this page does not currently render those assets.
- Rewards are synthesized from business point thresholds, so there is no reward catalog detail beyond the generated title/description.
- `CustomerBusinessDetail.memberCode` and `pointsToNextReward` are fetched and mapped, but this page does not display them directly.
- `CustomerBusinessDetailsInfoDto.phone`, `email`, `categoryLabel`, `customerNotes`, and `termsSummary` are parsed but not used by this page; phone/email/category instead come from the home `CustomerBusiness` object.

## Recommended QA Checklist

- Verify every business card passed into this page has non-empty `name`, `category`, and reasonable `rating`/`description`.
- Confirm the detail endpoint returns `currentPoints`, `nextRewardPoints`, menu data, coupons, transactions, and location for the selected business.
- Confirm coupon statuses arrive in values expected by the UI: `active`, `expiring`, `used`, `expired`.
- Confirm transaction types arrive in values expected by the UI: `EARN`, `REDEEM`, `REFUND`, `ADJUSTMENT`, `EXPIRED`, `COUPON_PURCHASE`.
- Confirm businesses with no menu/coupons/rewards/transactions show the expected empty states.
- Decide whether distance, opening hours, directions, and share should remain placeholders or be wired to live behavior.
