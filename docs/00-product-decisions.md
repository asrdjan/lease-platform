# L\*ease: Product Decision Log

| Field | Value |
|---|---|
| Document ID | LEASE-DOC-00 |
| Status | Approved by Product Owner |
| Version | 1.0 |
| Decision date | 2026-11-08 |
| Decision owner | Product Owner / Founder |
| Related | [01-ux-strategy.md](./01-ux-strategy.md), [02-requirements-BABOK.md](./02-requirements-BABOK.md), [03-high-level-architecture.md](./03-high-level-architecture.md) |

This log records the product decisions taken in the pilot-definition workshop. The other documents refer to them by ID (`D-nn`). A decision changes only through a pull request that edits this file. Superseded decisions are kept with status `Superseded`.

---

## 1. Summary

| ID | Topic | Decision | Resolves |
|---|---|---|---|
| D-01 | User roles | One account can hold several roles: `roles Role[]` (e.g. `CUSTOMER` + `PROVIDER`). Every user is a customer; "Become a provider" adds `PROVIDER`. | OI-01 |
| D-02 | Pilot offer types | `ASSET` + `SERVICE` in the pilot. `RETAIL` moves to Phase 2. | UX Q1 |
| D-03 | Market and currency | Pilot in **Serbia**, prices in **RSD**, operated by a Serbian legal entity. | A-2 |
| D-04 | Payment model | **Licensed payment partner with marketplace split payments.** Money goes to the provider through the partner, and the partner deducts the L\*ease commission. L\*ease never holds customer funds. The card is authorized (held) at checkout and captured when the provider confirms. | OI-04 (model) |
| D-05 | Commission | **10% paid by the provider**, no customer fee. **0% for the first 3 months** of the pilot. | OI-03 |
| D-06 | Time-based orders | One shared **`Booking`** model (1:1 with `Order`) with `startAt` / `endAt` for both `SERVICE` and `ASSET`, plus deposit and handover data for `ASSET`. The database prevents overlapping bookings. | OI-02 |
| D-07 | Confirmation deadline | The provider must confirm within **24 hours, and no later than 2 hours before the booking starts**, whichever comes first. Otherwise the order is cancelled automatically and the card authorization is released. | UX Q2 |
| D-08 | Pilot city | **Kragujevac**, whole city as one zone. | UX Q-pilot |
| D-09 | Pilot length and targets | **6-month pilot** (3 months at 0% commission, 3 months at 10%) with the targets in §3. | BO-1…BO-5 |

---

## 2. Decision Details

### D-01: Multi-role accounts

- **Context:** the Phase 1 schema has `User.role Role` (one value). In a local marketplace the same person often rents out a tool and also books a service.
- **Decision:** `User.roles Role[]` with default `[CUSTOMER]`. `ADMIN` is never self-assignable.
- **Consequences:** a schema migration from `role` to `roles` (existing values are copied into the array); JWT claim `roles` instead of `role`; `RolesGuard` checks membership; the client shows a customer/provider mode switch for users who hold both roles.
- **Alternatives considered:** a separate `ProviderProfile` relation (may still be added later for business data such as PIB and payout details); separate accounts per role.

### D-02: Pilot scope ASSET + SERVICE

- **Context:** a marketplace needs dense supply and demand in one place. Three offer types at once dilute supply.
- **Decision:** the pilot launches with `SERVICE` and `ASSET`. `RETAIL` stays in the `ListingType` enum but is disabled (rejected by the API) until Phase 2.
- **Consequences:** no stock, shipping or delivery logic in the pilot. Rental and booking logic (D-06) is in MVP scope.

### D-03: Serbia, RSD, Serbian legal entity

- **Context:** payment options depend on where the company is registered. Stripe does not support companies registered in Serbia.
- **Decision:** the pilot runs in Serbia, all prices are in RSD, and the operator is a Serbian company.
- **Consequences:** `Order.currency` default changes from `"EUR"` to `"RSD"`. Single currency in MVP (no conversion). `Decimal(10,2)` stays. Personal data falls under the Serbian Law on Personal Data Protection (ZZPL), which follows GDPR.

### D-04: Licensed payment partner with marketplace split

- **Context:** if L\*ease collects customer money and later forwards it to providers, this is likely a payment service that needs a National Bank of Serbia (NBS) licence. This must be checked by a lawyer; it is not settled here.
- **Decision:** use a licensed payment or e-money institution that supports marketplace split payments. Candidates to evaluate: **PaySpot** and **Monri** (both mention marketplace solutions). Other local processors (AllSecure, ChipCard, NestPay/Payten) are fallbacks.
- **Money flow:** checkout → card **authorization (hold)** → provider confirms → **capture** with split (provider share + L\*ease commission) → payout to the provider by the partner. Cancellation before capture → **void** (no refund needed).
- **To confirm in the partner contract (OI-05):** split settlement, authorization hold and its validity period, provider onboarding/KYC by the partner, refunds and partial refunds, payout timing, deposit holds for `ASSET`, fees, IPS QR support, sandbox and webhooks.
- **Consequences:** `PaymentsModule` hides the partner behind a `PaymentGateway` interface (authorize, capture, void, refund, provider onboarding). Provider onboarding with the partner is required before a provider's first listing is published.

### D-05: 10% provider commission, 0% for the first 3 months

- **Context:** supply is the bottleneck in a pilot. Personas say "opaque fees" (provider) and "hidden costs at checkout" (customer) are deal-breakers.
- **Decision:** a platform fee of 10% of the order amount, deducted from the provider's share. The customer pays exactly the listed price. A promotional rate of 0% applies for the first 3 months of the pilot.
- **Consequences:** the commission rate and promotion window are configuration, not code. Each order stores its platform fee as a snapshot (`Order.platformFeeAmount`) so later rate changes do not alter history. Card processing fees (estimated at about 1.5–3%, to be confirmed) come out of the commission.
- **Revisit:** after the pilot, with data on support cost per `ListingType`.

### D-06: Shared `Booking` model

- **Context:** both pilot offer types are time-based: an asset is rented from–to, and a service is booked for a time slot. The Phase 1 `Order` has no time fields.
- **Decision:** a `Booking` model, 1:1 with `Order`, holding `startAt` and `endAt` for every pilot order. For `ASSET` it also holds deposit and handover/return data. Overlaps for the same listing are blocked by a PostgreSQL exclusion constraint.
- **Proposed schema (not yet migrated):**

```prisma
enum DepositStatus {
  NONE
  HELD
  RELEASED
  CAPTURED
}

model Booking {
  id            String         @id @default(uuid())
  orderId       String         @unique
  listingId     String
  startAt       DateTime
  endAt         DateTime
  isBlocking    Boolean        @default(true) // false once the order is CANCELLED or REFUNDED
  depositAmount Decimal?       @db.Decimal(10, 2)
  depositStatus DepositStatus  @default(NONE)
  handoverNotes String?        @db.Text
  returnNotes   String?        @db.Text
  createdAt     DateTime       @default(now())
  updatedAt     DateTime       @updatedAt

  order         Order          @relation(fields: [orderId], references: [id], onDelete: Cascade)
  listing       Listing        @relation(fields: [listingId], references: [id])

  @@index([listingId, startAt])
}
```

```sql
-- Added by hand to the Prisma migration (Prisma has no syntax for exclusion constraints)
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE "Booking"
  ADD CONSTRAINT "Booking_no_overlap"
  EXCLUDE USING gist ("listingId" WITH =, tsrange("startAt", "endAt", '[)') WITH &&)
  WHERE ("isBlocking");
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_valid_range" CHECK ("endAt" > "startAt");
```

- **Consequences:** `RentalsModule` in earlier drafts becomes `BookingsModule`. A `PENDING` order already blocks its slot, so two customers cannot both be waiting for the same slot.

### D-07: Confirmation deadline

- **Decision:** `confirmBy = min(order.createdAt + 24h, booking.startAt − 2h)`. If the provider has not confirmed by `confirmBy`, the system cancels the order and voids the card authorization.
- **Consequences:** a scheduled job checks for expired `PENDING` orders. A minimum booking lead time is needed so that `confirmBy` is in the future; proposed default: `startAt ≥ now + 3h` (configurable, gives the provider at least 1 hour). The authorization hold must stay valid for at least 24 hours (confirm with the partner).

### D-08: Pilot city Kragujevac

- **Decision:** Kragujevac, the whole city as one service zone.
- **Rationale:** compact city, so supply is dense enough for rentals; local communities are reachable at low marketing cost; the playbook can then be copied to other Serbian cities.
- **Consequences:** no location search needed in the pilot (FR-M2-11 stays `Could`). Listings record a pickup area or service area within the city.

### D-09: 6-month pilot and targets

- **Decision:** 6 months: months 1–3 at 0% commission, months 4–6 at 10%. Targets are estimates for a city of Kragujevac's size and are revalidated after month 3.

## 3. Pilot Targets (end of month 6)

| Metric | Target | Source of measure |
|---|---|---|
| Active listings | ≥ 80 | `Listing.isActive = true`, type `SERVICE` or `ASSET` |
| Active providers | ≥ 40 | Users with `PROVIDER` role and ≥ 1 active listing |
| Completed orders (cumulative) | ≥ 250 | `Order.status = COMPLETED` |
| Orders confirmed within deadline | ≥ 85% | Confirmed before `confirmBy` / all orders that reached the provider |
| Average rating | ≥ 4.5 / 5 | `Review.rating` |
| Repeat customers | ≥ 25% | Customers with ≥ 2 completed orders / customers with ≥ 1 |
| Provider retention after commission starts | ≥ 70% | Providers active in month 3 who are still active in month 6 |

## 4. Still Open

| ID | Topic | Owner | Needed by |
|---|---|---|---|
| OI-05 | Choose the payment partner and confirm contract terms (see D-04) | Product Owner | Before Module 3 |
| OI-06 | Legal review of the money flow under the Serbian Law on Payment Services | Product Owner / Legal | Before go-live |
| OI-07 | Deposit handling for `ASSET`: second authorization hold or captured amount; depends on partner | Product Owner / Architect | Before Module 4b |
| OI-08 | Customer cancellation policy (free cancellation window, fees, refund rules) | Product Owner | Before Module 3 |
| OI-09 | App language(s) for the pilot (e.g. Serbian Latin, Cyrillic, English) | Product Owner | Before client UI work |
