# L\*ease: Requirements Specification (BABOK® v3 aligned)

| Field | Value |
|---|---|
| Document ID | LEASE-DOC-02 |
| Status | Draft for stakeholder review |
| Version | 0.2 |
| Standard | IIBA® *A Guide to the Business Analysis Body of Knowledge®* (BABOK® Guide) v3 |
| Related | [00-product-decisions.md](./00-product-decisions.md), [01-ux-strategy.md](./01-ux-strategy.md), [03-high-level-architecture.md](./03-high-level-architecture.md), `backend/prisma/schema.prisma` |

---

## 1. Introduction

### 1.1 Purpose

This document records the requirements for the L\*ease two-sided marketplace. It follows the BABOK® Guide v3 **requirements classification schema** (§2.3, Key Terms):

| BABOK class | Definition (BABOK v3) | Section |
|---|---|---|
| **Business requirements** | Statements of goals, objectives and outcomes that describe why a change has been initiated. | §4 |
| **Stakeholder requirements** | The needs of stakeholders that must be met to achieve the business requirements. | §5 |
| **Solution requirements** | The capabilities and qualities of a solution that meets the stakeholder requirements. Split into **functional** and **non-functional** requirements. | §6–§8 |
| **Transition requirements** | The capabilities the solution must have, and the conditions it must meet, to move from the current state to the future state. They are no longer needed once the change is complete. | §9 |

### 1.2 BABOK Knowledge Areas Applied

| Knowledge Area | How it is applied in this document |
|---|---|
| Business Analysis Planning & Monitoring | Requirement attributes, prioritization scheme and change approach (§2) |
| Elicitation & Collaboration | Sources: the product owner brief, the UX strategy (personas, JTBD) and the data model. Open questions are tracked in §11. |
| Requirements Life Cycle Management | Unique IDs, status, traceability matrix (§10), change control (§2.4) |
| Strategy Analysis | Business need, current and future state, goals, risks (§3, §4, §11) |
| Requirements Analysis & Design Definition (RADD) | Specified and modelled requirements: state model, data mapping, acceptance criteria (§6–§8) |
| Solution Evaluation | KPIs and measures linked to business objectives (§4.3) |

### 1.3 Scope

**In scope (MVP / pilot):** user registration and authentication with multi-role access (D-01); listing management for `SERVICE` and `ASSET` types (D-02); marketplace discovery; time-based bookings (D-06); checkout with online payment through a licensed payment partner (D-04); order lifecycle with a confirmation deadline (D-07); reviews tied to orders; basic asset-sharing rules; admin moderation.

**Pilot context:** Kragujevac, Serbia; prices in RSD; Serbian legal entity (D-03, D-08). Decisions are recorded in [00-product-decisions.md](./00-product-decisions.md).

**Out of scope (MVP):** `RETAIL` listings (Phase 2, D-02); in-app real-time chat; native payouts and marketplace ledger (handled by the payment partner); dynamic pricing; multi-currency conversion (RSD only); logistics and delivery integration; the native mobile app (the future Flutter frontend consumes the same API).

### 1.4 Definitions

| Term | Definition |
|---|---|
| Customer | A `User` whose `roles` contain `CUSTOMER` (every user) who books or rents listings |
| Provider | A `User` whose `roles` contain `PROVIDER` who publishes listings and fulfils orders |
| Admin | A `User` whose `roles` contain `ADMIN`; internal platform operator |
| Listing | An offer published by a provider; `type` ∈ {`SERVICE`, `RETAIL`, `ASSET`} |
| Order | A customer's purchase, booking or rental of exactly one listing |
| Booking | The time window (`startAt`, `endAt`) of an order, plus deposit and handover data for assets (D-06) |
| Confirmation deadline | `confirmBy = min(createdAt + 24h, startAt − 2h)` (D-07) |
| Platform fee | The L\*ease commission on an order: 10% of `amount`, 0% during the first 3 pilot months (D-05) |
| Review | A rating and comment that a customer gives about a provider and listing for one order |
| PSP / payment partner | Licensed Serbian payment or e-money institution with marketplace split payments (candidates: PaySpot, Monri; D-04). `Order.paymentIntentId` references the partner's payment object. |
| GMV | Gross Merchandise Value: the sum of `Order.amount` for `COMPLETED` orders |

---

## 2. Requirements Management Approach

### 2.1 Requirement Attributes

Every requirement has: **ID**, **Statement**, **Priority**, **Source**, **Status** (`Proposed` → `Approved` → `Implemented` → `Verified`), **Acceptance criteria** (Given / When / Then), and **Trace** (parent requirement IDs).

### 2.2 ID Convention

| Prefix | Class |
|---|---|
| `BR-nn` | Business requirement |
| `SR-nn` | Stakeholder requirement |
| `FR-Mx-nn` | Functional requirement in Module *x* |
| `NFR-<cat>-nn` | Non-functional requirement |
| `TR-nn` | Transition requirement |

### 2.3 Prioritization (MoSCoW)

**M**ust: MVP release blocker. **S**hould: high value, MVP if capacity allows. **C**ould: nice to have. **W**on't (this release): explicitly deferred.

### 2.4 Change Control

Changes go through a pull request that edits this document. Each PR states the affected IDs and impact. The product owner approves. IDs are never reused. Removed requirements are kept with status `Withdrawn`.

### 2.5 Spec-Driven Delivery

Each module (§6) is a self-contained increment. One module maps to one NestJS feature module, one set of Prisma models, one API surface and one test suite. A module is **Done** when all its `Must` FRs have passing automated tests that map 1:1 to the acceptance criteria.

---

## 3. Business Context (Strategy Analysis)

### 3.1 Business Need

Local consumers and small providers have no single trusted channel for transacting services, goods and temporary access to assets. Existing alternatives are split across verticals, lack payment protection and have weak or unverifiable reputation signals. This leads to lost transactions, fraud and idle assets.

### 3.2 Current State

Transactions happen through classifieds, social-media groups and single-vertical platforms. Payment is often cash or a direct transfer, with no escrow. Reviews are optional and not tied to a completed transaction.

### 3.3 Future State

One platform where any verified provider can list services, goods or assets. Customers pay online at checkout, and orders follow a controlled lifecycle. Reputation comes only from completed orders, and admins can resolve disputes and issue refunds.

---

## 4. Business Requirements

### 4.1 Business Goals

| ID | Goal |
|---|---|
| BG-1 | Establish a liquid two-sided marketplace in a pilot city. |
| BG-2 | Generate sustainable revenue through commission on completed orders. |
| BG-3 | Become the most trusted local marketplace, measured by dispute and fraud rates. |

### 4.2 Business Requirements

| ID | Statement | Priority | Trace |
|---|---|---|---|
| BR-01 | The organization shall provide a single marketplace that supports three offer types: services, retail goods and shared assets. The pilot supports services and shared assets; retail goods follow in Phase 2 (D-02). | M | BG-1 |
| BR-02 | The organization shall secure customer payments online at checkout, through a licensed payment partner, so that providers are protected against non-payment and customers against non-delivery. L\*ease shall not hold customer funds (D-04). | M | BG-2, BG-3 |
| BR-03 | The organization shall earn revenue as a commission on each completed order, paid by the provider (D-05). | M | BG-2 |
| BR-04 | The organization shall build verifiable reputation by allowing reviews only for real, completed orders. | M | BG-3 |
| BR-05 | The organization shall be able to moderate content and users, and resolve disputes including refunds. | M | BG-3 |
| BR-06 | The organization shall comply with Serbian data-protection law (ZZPL, modelled on GDPR), consumer-protection law and payment-services law applicable to online marketplaces. | M | BG-3 |
| BR-07 | The solution shall be extensible to a native mobile client (Flutter) without re-implementing business logic. | S | BG-1 |

### 4.3 Business Objectives & Measures (SMART)

Targets were approved by the product owner for the 6-month Kragujevac pilot (D-09). They are estimates and are revalidated after month 3.

| ID | Objective | Measure | Target | Trace |
|---|---|---|---|---|
| BO-1 | Supply liquidity | Active listings (`isActive = true`) and active providers in Kragujevac | ≥ 80 listings and ≥ 40 providers by end of month 6 | BR-01 |
| BO-2 | Demand traction | Completed orders (cumulative) | ≥ 250 by end of month 6 | BR-01, BR-02 |
| BO-3 | Monetization | Commission rate on GMV | 10% from month 4 (0% in months 1–3) | BR-03 |
| BO-4 | Trust | Orders ending in `REFUNDED` after dispute | ≤ 2% of completed orders | BR-04, BR-05 |
| BO-5 | Quality | Average review rating | ≥ 4.5 / 5 | BR-04 |
| BO-6 | Reliability | Orders confirmed before the confirmation deadline | ≥ 85% | BR-02 |
| BO-7 | Retention (demand) | Customers with ≥ 2 completed orders / customers with ≥ 1 | ≥ 25% | BR-01 |
| BO-8 | Retention (supply) | Providers active in month 3 still active in month 6 (after commission starts) | ≥ 70% | BR-03 |

---

## 5. Stakeholder Requirements

### 5.1 Stakeholder Register

| Stakeholder | Role / Interest | Influence | Involvement (RACI on requirements) |
|---|---|---|---|
| Product Owner / Founder | Vision, prioritization, sign-off | High | A |
| Customers | Find, pay and receive with confidence | High | C (research) |
| Providers | Earn reliably, low admin | High | C (research) |
| Admin / Trust & Safety | Moderation, disputes, refunds | Medium | C |
| Engineering (backend / frontend) | Build and operate the solution | High | R |
| UX / Design | Usable, consistent experience | Medium | R |
| Payment partner (licensed, Serbia) | Payment processing, split settlement, provider KYC and payouts; 3-D Secure | High | C |
| Legal / Compliance (DPO) | ZZPL/GDPR, terms, consumer law, payment-services law (NBS) | Medium | C |

### 5.2 Stakeholder Requirements

| ID | Stakeholder | Statement | Priority | Trace |
|---|---|---|---|---|
| SR-01 | Customer | I need to browse and search offers and see the full price without having to register. | M | BR-01 |
| SR-02 | Customer | I need to pay securely online and know that my money is protected if the order is not fulfilled. | M | BR-02, BR-05 |
| SR-03 | Customer | I need to track the status of my orders. | M | BR-02 |
| SR-04 | Customer | I need trustworthy reviews from people who actually completed an order. | M | BR-04 |
| SR-05 | Provider | I need to publish and manage services and rentable assets (goods in Phase 2) from the same account I use as a customer. | M | BR-01 |
| SR-06 | Provider | I need orders to be paid before I commit time or hand over items. | M | BR-02 |
| SR-07 | Provider | I need to accept, progress and complete orders, and see my earnings. | M | BR-02, BR-03 |
| SR-08 | Provider | I need my reputation (rating, reviews) to be visible on my profile and listings. | M | BR-04 |
| SR-09 | Provider | I need rules for rentals (rental period, deposit, return condition) that protect my assets. | S | BR-01, BR-05 |
| SR-10 | Admin | I need to view, suspend and moderate users, listings and reviews. | M | BR-05 |
| SR-11 | Admin | I need to cancel and refund orders and see an audit trail of status changes. | M | BR-05 |
| SR-12 | Legal / DPO | Personal data must be minimized and protected, and users must be able to export and delete it. | M | BR-06 |
| SR-13 | Engineering | Business logic must be exposed through a versioned API that any client (web, Flutter) can consume. | S | BR-07 |

---

## 6. Solution Requirements: Functional (Modular)

Each module lists its **data entities** (from `schema.prisma`), **functional requirements** and **acceptance criteria**. Acceptance criteria are the basis for automated tests.

### Module 1: Auth & Users

**Entities:** `User` (`id`, `email` [unique], `password` [hash], `firstName`, `lastName`, `roles` [`Role[]`, default `[CUSTOMER]`; replaces Phase 1 `role`, D-01], `createdAt`, `updatedAt`).
**NestJS modules:** `AuthModule`, `UsersModule`.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M1-01 | The system shall allow a visitor to register with email, password, first name and last name. The new account gets `roles = [CUSTOMER]`. | M | SR-01, SR-05 |
| FR-M1-02 | The system shall reject registration if the email is already in use (case-insensitive). | M | SR-12 |
| FR-M1-03 | The system shall store passwords only as a salted, adaptive hash (argon2id or bcrypt); plaintext passwords shall never be persisted or logged. | M | SR-12 |
| FR-M1-04 | The system shall authenticate users by email and password and issue a short-lived access token (JWT) and a rotating refresh token. | M | SR-13 |
| FR-M1-05 | The system shall allow an authenticated user to log out, revoking the refresh token. | M | SR-12 |
| FR-M1-06 | The system shall allow an authenticated user to view and update their profile (`firstName`, `lastName`). Changing `email` or `password` requires the current password. | M | SR-12 |
| FR-M1-07 | The system shall enforce role-based access control (RBAC) on every protected endpoint; access is granted when `User.roles` contains a required role. | M | SR-10 |
| FR-M1-08 | The system shall not allow self-registration with role `ADMIN`; admins are created only by an existing admin or a seed script. | M | SR-10 |
| FR-M1-09 | The system shall provide a public provider profile showing name, member-since date, active listings and aggregate rating, and no email or other private data. | M | SR-08 |
| FR-M1-10 | The system shall support password reset through a single-use, time-limited token sent by email. | S | SR-12 |
| FR-M1-11 | The system shall support email verification before a provider can publish a listing. | S | BR-05 |
| FR-M1-12 | The system shall allow a user to export their personal data (JSON) and request account deletion (GDPR Art. 15, 17, 20). | M | SR-12 |
| FR-M1-13 | Admins shall be able to list, search and suspend users. | M | SR-10 |
| FR-M1-14 | The system shall allow an authenticated user to become a provider by accepting the Provider Agreement, which adds `PROVIDER` to `User.roles` on the same account. | M | SR-05 |
| FR-M1-15 | The system shall not publish a provider's first listing until the provider has completed onboarding (KYC and payout account) with the payment partner. | M | SR-06, BR-02 |

**Acceptance criteria (examples):**

- **AC-M1-01-a:** *Given* no user exists with `mila@example.com`, *when* a visitor registers with valid data, *then* a `User` is created with `roles = [CUSTOMER]`, the response contains no password field, and HTTP 201 is returned.
- **AC-M1-02-a:** *Given* a user with `Mila@Example.com` exists, *when* a visitor registers with `mila@example.com`, *then* HTTP 409 is returned and no user is created.
- **AC-M1-07-a:** *Given* an authenticated user with `roles = [CUSTOMER]`, *when* they call a `PROVIDER`-only endpoint (e.g. create listing), *then* HTTP 403 is returned.
- **AC-M1-14-a:** *Given* a user with `roles = [CUSTOMER]`, *when* they accept the Provider Agreement, *then* `roles = [CUSTOMER, PROVIDER]` and they can still place orders as a customer.
- **AC-M1-08-a:** *Given* a registration request with `role = ADMIN`, *then* HTTP 400 is returned.

> **Decision D-01 (resolves OI-01):** one account can hold several roles. The Phase 1 `role` column is migrated to `roles Role[]`, copying existing values.

### Module 2: Listings & Marketplace

**Entities:** `Listing` (`id`, `title`, `description`, `price` [Decimal(10,2)], `type` [`SERVICE` | `RETAIL` | `ASSET`], `metadata` [JSON], `isActive` [default true], `providerId` → `User`, timestamps). Indexes on `type` and `providerId`.
**NestJS module:** `ListingsModule`.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M2-01 | The system shall allow a `PROVIDER` to create a listing with title, description, price in RSD (> 0, max 2 decimals, max 99,999,999.99), type and optional type-specific metadata. | M | SR-05 |
| FR-M2-02 | The system shall validate `metadata` against a per-type schema (see UX §5.4) and reject unknown or invalid keys. | S | SR-05 |
| FR-M2-03 | The system shall allow a provider to update or deactivate (`isActive = false`) **only their own** listings. | M | SR-05 |
| FR-M2-04 | The system shall prevent hard deletion of listings that have orders; deletion becomes deactivation. | M | SR-11 |
| FR-M2-05 | The system shall provide a public, paginated catalogue of active listings (`isActive = true`), filterable by `type`, price range and keyword (title/description), and sortable by newest, price and rating. | M | SR-01 |
| FR-M2-06 | The system shall provide a public listing detail view with provider summary, aggregate rating, review count and recent reviews. | M | SR-01, SR-04 |
| FR-M2-07 | The system shall provide a provider "My listings" view including inactive listings. | M | SR-05 |
| FR-M2-08 | The system shall allow an admin to deactivate any listing and record the reason. | M | SR-10 |
| FR-M2-09 | Inactive listings shall not be orderable and shall not appear in public search. | M | SR-01 |
| FR-M2-10 | The system shall support listing images (upload to object storage; URLs referenced in `metadata` or a future `ListingImage` model). | S | SR-01 |
| FR-M2-11 | The system shall support location-based search (distance from customer). Not needed in the single-zone pilot (D-08). | C | SR-01 |
| FR-M2-12 | While `RETAIL` is disabled (pilot), the system shall reject creating `RETAIL` listings with HTTP 400 and hide the type from the catalogue. The switch is configuration (D-02). | M | BR-01 |
| FR-M2-13 | The system shall let a provider choose a cancellation policy per listing (`FLEXIBLE`, `MODERATE` default, `STRICT`) and copy it to each order at creation (D-10). | M | SR-02, SR-06 |

**Acceptance criteria (examples):**

- **AC-M2-03-a:** *Given* provider A owns listing L, *when* provider B tries to update L, *then* HTTP 403 (or 404 to avoid revealing existence) is returned and L is unchanged.
- **AC-M2-05-a:** *Given* 30 active and 5 inactive `ASSET` listings, *when* a guest requests `type=ASSET&page=1&pageSize=20`, *then* 20 active listings are returned with `total = 30`.
- **AC-M2-01-a:** *Given* a provider submits `price = -5`, *then* HTTP 400 is returned with a field-level validation error.

### Module 3: Orders & Checkout

**Entities:** `Order` (`id`, `amount` [Decimal(10,2)], `currency` [default `RSD`; Phase 1 default `EUR` to be migrated, D-03], `status` [`OrderStatus`], `paymentIntentId` [unique, nullable], `platformFeeAmount` [Decimal(10,2), proposed, D-05], `customerId`, `providerId`, `listingId`, timestamps). Every pilot order has one `Booking` (D-06). Indexes on `customerId`, `providerId`, `status`.
**NestJS modules:** `OrdersModule`, `PaymentsModule`.

**Order state model (normative):**

| From → To | Actor | Precondition |
|---|---|---|
| (new) → `PENDING` | Customer | Listing active; booking slot free; card payment authorized (held); customer ≠ provider |
| `PENDING` → `CONFIRMED` | Provider (owner) | Before `confirmBy` (D-07); payment captured with split on confirmation (D-04) |
| `PENDING` → `CANCELLED` | Customer, Provider, System (`confirmBy` passed) | Card authorization voided; booking slot released |
| `CONFIRMED` → `IN_PROGRESS` | Provider | n/a |
| `CONFIRMED` → `CANCELLED` | Customer, Provider, Admin | Refund per the order's cancellation policy (D-10); booking slot released |
| `IN_PROGRESS` → `COMPLETED` | Provider (customer may confirm, see FR-M3-08) | n/a |
| `CANCELLED` → `REFUNDED` | System / Admin | Captured funds returned through PSP |
| `COMPLETED` → `REFUNDED` | Admin | Dispute upheld |

Any other transition shall be rejected.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M3-01 | The system shall allow an authenticated `CUSTOMER` to create an order for one active listing. `amount` is computed **server-side** from the listing price (and quantity or rental days where applicable), never taken from the client. | M | SR-02 |
| FR-M3-02 | The system shall set `Order.providerId` from `Listing.providerId` and reject orders where the customer is the listing's provider. | M | SR-02 |
| FR-M3-03 | The system shall create a card **authorization (hold)** with the payment partner for `amount` / `currency`, including the split instruction (provider's partner account and platform fee), and store the partner's payment id in `paymentIntentId`. | M | SR-02, SR-06 |
| FR-M3-04 | The system shall process PSP webhooks idempotently, verifying the webhook signature, and update order/payment state accordingly. | M | SR-02 |
| FR-M3-05 | The system shall enforce the order state model above and reject invalid transitions with HTTP 409. | M | SR-03, SR-07 |
| FR-M3-06 | The system shall record an audit entry (actor, from, to, timestamp, reason) for every status change. | M | SR-11 |
| FR-M3-07 | The system shall allow customers to list and view their orders (`ordersAsCustomer`) and providers theirs (`ordersAsProvider`), filterable by status. | M | SR-03, SR-07 |
| FR-M3-08 | The system shall compute `confirmBy = min(createdAt + 24h, booking.startAt − 2h)` (both values configurable) and automatically cancel `PENDING` orders not confirmed by then, voiding the card authorization (D-07). | M | SR-02, SR-06 |
| FR-M3-09 | The system shall allow an admin to refund an order (full refund in MVP), moving it to `REFUNDED` through the PSP. | M | SR-11 |
| FR-M3-10 | The system shall notify the counterpart by email on each status change. | S | SR-03 |
| FR-M3-11 | The system shall provide providers with an earnings summary (sum of `COMPLETED` amounts minus `platformFeeAmount`) for a date range. | S | SR-07, BR-03 |
| FR-M3-12 | The system shall support partial refunds through the payment partner. | M | SR-02, D-10 |
| FR-M3-13 | The system shall capture the authorized payment when the provider confirms the order, with the split executed by the payment partner. | M | SR-02, SR-06, BR-02 |
| FR-M3-14 | The system shall compute the platform fee server-side from a configured commission rate (default 10%) and promotional window (0% for the first 3 pilot months), and store it on the order as `platformFeeAmount` at creation (D-05). | M | BR-03 |
| FR-M3-15 | The system shall reject orders whose booking starts earlier than a configurable minimum lead time (default 3 hours) so that `confirmBy` is in the future **[Proposed]**. | M | SR-06 |
| FR-M3-16 | When a confirmed order is cancelled, the system shall compute the refund server-side from the order's `cancellationPolicy` snapshot and the time left before `booking.startAt`: full refund if the provider cancels; per-policy full, 50% or no refund if the customer cancels (D-10). The platform fee is recalculated on the amount the provider keeps. | M | SR-02, SR-06 |

**Acceptance criteria (examples):**

- **AC-M3-01-a:** *Given* a listing priced 2,500.00 RSD, *when* the customer submits an order with a tampered `amount = 1.00`, *then* the order is created with `amount = 2500.00` and `currency = RSD` (client amount ignored).
- **AC-M3-04-a:** *Given* the partner's "payment authorized" webhook is delivered twice, *then* the order state changes only once and both deliveries return HTTP 2xx.
- **AC-M3-05-a:** *Given* an order in `COMPLETED`, *when* a provider requests a transition to `IN_PROGRESS`, *then* HTTP 409 is returned.
- **AC-M3-08-a:** *Given* an order created at 10:00 for a booking starting at 18:00 the same day, *then* `confirmBy = 16:00`; *when* the provider has not confirmed by 16:00, *then* the order becomes `CANCELLED` and the authorization is voided.
- **AC-M3-16-a:** *Given* a confirmed order with policy `MODERATE` and `startAt` in 10 hours, *when* the customer cancels, *then* 50% of `amount` is refunded and the order becomes `CANCELLED`; with policy `STRICT` nothing is refunded.
- **AC-M3-14-a:** *Given* an order of 2,500.00 RSD placed in pilot month 4, *then* `platformFeeAmount = 250.00`; in pilot month 2 it is `0.00`.

### Module 4: Reviews & Asset Sharing

**Entities:** `Review` (`id`, `rating` [Int, default 5], `comment`, `authorId`, `targetId`, `listingId`, `orderId` [unique], timestamps). Index on `listingId`. Bookings use the proposed `Booking` model (1:1 with `Order`, D-06) for both `SERVICE` and `ASSET`; asset-specific data (deposit, handover) is in the same model.
**NestJS modules:** `ReviewsModule`, `BookingsModule` (bookings and asset sharing).

**4a: Reviews**

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M4-01 | The system shall allow the customer of an order to submit one review only when the order status is `COMPLETED`. | M | SR-04 |
| FR-M4-02 | The system shall enforce at most one review per order (`orderId` unique). | M | SR-04 |
| FR-M4-03 | The system shall set `authorId` = order customer, `targetId` = order provider and `listingId` = order listing server-side. | M | SR-04 |
| FR-M4-04 | The system shall validate `rating` as an integer from 1 to 5 and `comment` as at most 2,000 characters. | M | SR-04 |
| FR-M4-05 | The system shall compute and expose aggregate rating and review count per listing and per provider. | M | SR-08 |
| FR-M4-06 | The system shall allow an admin to hide or remove reviews that violate content policy, with a recorded reason. | M | SR-10 |
| FR-M4-07 | The system shall allow a provider to post a public reply to a review. | C | SR-08 |

> **Data note:** `Review.rating` defaults to 5 in the schema. The API shall **require** `rating` explicitly so that reviews are not silently inflated (FR-M4-04).

**4b: Bookings & Asset Sharing (`SERVICE` and `ASSET`)**

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M4-08 | The system shall allow an `ASSET` listing to define pricing unit (day/week), minimum rental period, deposit amount and pickup location in `metadata`. | S | SR-09 |
| FR-M4-09 | The system shall create a `Booking` for every order. For `ASSET` the customer chooses start and end dates and `amount` = unit price × units (deposit held separately). For `SERVICE` the customer chooses a start time and `endAt = startAt + durationMinutes`. | M | SR-09 |
| FR-M4-10 | The system shall prevent overlapping bookings of the same listing while the order is `PENDING`, `CONFIRMED` or `IN_PROGRESS`, enforced by a database exclusion constraint (D-06). | M | SR-09 |
| FR-M4-11 | The system shall support check-out and check-in condition records (notes and photos) at handover and return. | C | SR-09, SR-11 |
| FR-M4-12 | The system shall release or capture the deposit based on the check-in outcome, with admin override in a dispute. Mechanism depends on the payment partner (OI-07). | S | SR-09, SR-11 |

> **Decision D-06 (resolves OI-02):** a shared `Booking` model (1:1 with `Order`) with `startAt`, `endAt`, deposit and handover fields, plus a PostgreSQL exclusion constraint against overlaps. The proposed schema is in [00-product-decisions.md](./00-product-decisions.md#d-06-shared-booking-model).

---

## 7. Solution Requirements: Non-Functional

| ID | Category | Requirement | Priority |
|---|---|---|---|
| NFR-SEC-01 | Security | All traffic shall use TLS 1.2+; HSTS enabled in production. | M |
| NFR-SEC-02 | Security | Authentication shall use signed JWT access tokens (≤ 15 min) and rotating refresh tokens (≤ 30 days) stored hashed. | M |
| NFR-SEC-03 | Security | The API shall be protected against the OWASP Top 10 / OWASP API Security Top 10. This includes object-level authorization on every resource access (BOLA). | M |
| NFR-SEC-04 | Security | Auth endpoints shall be rate-limited (e.g. 5 failed logins / 15 min / account+IP). | M |
| NFR-SEC-05 | Security | Secrets shall be supplied through environment or secret manager, never committed; `.env` is git-ignored. | M |
| NFR-SEC-06 | Security | Card data shall never touch L\*ease servers (PSP-hosted fields / SDK), keeping PCI-DSS scope at SAQ-A. | M |
| NFR-PRI-01 | Privacy | Personal data processing shall comply with the Serbian Law on Personal Data Protection (ZZPL, modelled on GDPR): lawful basis, data minimization, retention policy, DPA with processors. | M |
| NFR-PRI-02 | Privacy | Logs shall not contain passwords, tokens or full payment identifiers. | M |
| NFR-PERF-01 | Performance | p95 API latency ≤ 300 ms for read endpoints and ≤ 800 ms for write endpoints at 50 req/s (excluding PSP round-trip). | S |
| NFR-PERF-02 | Performance | Catalogue queries shall use indexed columns (`type`, `providerId`, `status`) and be paginated (max page size 100). | M |
| NFR-SCAL-01 | Scalability | The backend shall be stateless so that it scales horizontally behind a load balancer. | M |
| NFR-AVL-01 | Availability | Production availability ≥ 99.5% monthly (MVP). | S |
| NFR-REL-01 | Reliability | Order creation and status transitions shall be transactional. Monetary values use `Decimal(10,2)`, never floating point. | M |
| NFR-REL-02 | Reliability | Automated daily database backups, kept for ≥ 7 days, with a tested restore (RPO ≤ 24 h, RTO ≤ 4 h). | M |
| NFR-MAINT-01 | Maintainability | Code shall be organized as NestJS feature modules matching §6. Schema changes only through Prisma migrations. | M |
| NFR-MAINT-02 | Maintainability | Unit and e2e tests run in CI on every PR. Each `Must` FR has at least one automated test. | M |
| NFR-OBS-01 | Observability | Structured JSON logs with request ID, health endpoint (`/health`), and error tracking. | S |
| NFR-INT-01 | Interoperability | REST API, versioned (`/api/v1`), documented with OpenAPI 3 (`@nestjs/swagger`). | M |
| NFR-USA-01 | Usability | Client UIs shall meet WCAG 2.1 AA. | S |
| NFR-I18N-01 | Localization | Clients, emails and notifications shall be available in Serbian (Latin, `sr-Latn`) and English (`en`) from launch (D-11). API returns machine-readable error codes that clients translate. Email language follows `User.locale`. Currency formatting is client-side. MVP currency is RSD (D-03). | M |
| NFR-PORT-01 | Portability | All services run in Docker; local dev through `docker compose`. | M |

---

## 8. Data Requirements (Data Dictionary Summary)

| Entity | Attribute | Type | Rules |
|---|---|---|---|
| User | email | String, unique | Valid email, normalized lowercase |
| User | password | String | Hash only (FR-M1-03) |
| User | roles | Enum Role[] | `[CUSTOMER]` default; `PROVIDER` added by onboarding; `ADMIN` not self-assignable |
| Listing | price | Decimal(10,2) | > 0 |
| Listing | type | Enum ListingType | Required, immutable after first order **[Proposed]** |
| Listing | metadata | JSON | Validated per type (FR-M2-02) |
| Listing | cancellationPolicy **[Proposed]** | Enum | `FLEXIBLE` / `MODERATE` (default) / `STRICT` (FR-M2-13) |
| Order | cancellationPolicy **[Proposed]** | Enum | Snapshot of the listing policy at order creation |
| User | locale **[Proposed]** | String | `sr-Latn` (default) or `en` (D-11) |
| Order | amount | Decimal(10,2) | Server-computed (FR-M3-01) |
| Order | currency | String | ISO 4217; `RSD` in MVP |
| Order | platformFeeAmount | Decimal(10,2) **[Proposed]** | Server-computed snapshot (FR-M3-14) |
| Order | paymentIntentId | String, unique, nullable | Set by `PaymentsModule` |
| Review | rating | Int | 1..5, required in API |
| Review | orderId | String, unique | Order must be `COMPLETED` |
| Booking **[Proposed]** | startAt / endAt | DateTime | `endAt > startAt`; no overlap per listing while blocking (FR-M4-10) |
| Booking **[Proposed]** | depositAmount / depositStatus | Decimal(10,2) / Enum | `ASSET` only; `NONE` → `HELD` → `RELEASED` or `CAPTURED` |

Referential rules from the schema: deleting a `User` cascades to their `Listing`s. Deleting an `Order` cascades to its `Review`. Other relations are restrictive by default. User deletion (FR-M1-12) shall therefore be done as **anonymization** when the user has orders, so that financial records are kept.

---

## 9. Transition Requirements

| ID | Requirement | Priority |
|---|---|---|
| TR-01 | An initial admin account shall be created through a seed script with credentials supplied by environment variables. | M |
| TR-02 | Database schema shall be deployed through `prisma migrate deploy` as part of the release pipeline. | M |
| TR-03 | Terms of Service, Privacy Policy and Provider Agreement shall be published and accepted at sign-up before go-live. | M |
| TR-04 | Pilot providers shall be onboarded with assisted listing creation (bulk import from CSV is optional). | S |
| TR-05 | Support and dispute runbooks shall be written and admins trained before go-live. | S |
| TR-06 | A contract with a licensed payment partner shall confirm split settlement, authorization holds (≥ 24 h validity), provider KYC, refunds and payout timing before Module 3 goes live (OI-05). | M |
| TR-07 | A legal review shall confirm that the money flow complies with the Serbian Law on Payment Services before go-live (OI-06). | M |
| TR-08 | Existing `User.role` values and `Order.currency` defaults shall be migrated (`role` → `roles`, `EUR` → `RSD`) in one Prisma migration. | M |
| TR-09 | Pilot providers in Kragujevac shall be onboarded with assisted listing creation before public launch. | S |

---

## 10. Traceability Matrix (summary)

| Business req. | Stakeholder req. | Functional req. |
|---|---|---|
| BR-01 | SR-01, SR-05, SR-09 | FR-M1-14, FR-M2-01…12, FR-M4-08…12 |
| BR-02 | SR-02, SR-03, SR-06, SR-07 | FR-M1-15, FR-M3-01…10, FR-M3-13, FR-M3-15 |
| BR-03 | SR-07 | FR-M3-11, FR-M3-14 |
| BR-04 | SR-04, SR-08 | FR-M1-09, FR-M4-01…07 |
| BR-05 | SR-10, SR-11 | FR-M1-07, FR-M1-08, FR-M1-13, FR-M2-08, FR-M3-06, FR-M3-09, FR-M4-06 |
| BR-06 | SR-12 | FR-M1-02, FR-M1-03, FR-M1-05, FR-M1-06, FR-M1-10, FR-M1-12, NFR-PRI-* |
| BR-07 | SR-13 | FR-M1-04, NFR-INT-01 |

---

## 11. Assumptions, Constraints, Risks & Open Issues

### 11.1 Assumptions

- A-1: A licensed Serbian payment partner with marketplace split support (PaySpot or Monri to be evaluated) will handle authorization, capture, refunds, provider KYC and payouts (D-04).
- A-2: MVP operates in Serbia, in RSD, through a Serbian legal entity (D-03); the pilot city is Kragujevac (D-08).
- A-3: Providers fulfil orders offline (in person); the platform does not handle logistics.

### 11.2 Constraints

- C-1: Technology baseline: NestJS (TypeScript, ESM), PostgreSQL, Prisma ORM 6.x, Docker.
- C-2: Data model baseline is `backend/prisma/schema.prisma` (Phase 1). Changes require migrations.

### 11.3 Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Chicken-and-egg liquidity problem | High | High | Single pilot city (Kragujevac); two offer types; 0% commission for 3 months; supply-first onboarding (TR-04, TR-09) |
| R-2 | Payment fraud / chargebacks | Medium | High | Partner risk tools, 3-D Secure, card authorization before confirmation |
| R-3 | Damage disputes in asset rentals | Medium | Medium | Deposits, condition records (FR-M4-11/12) |
| R-4 | Regulatory (platform-work, consumer law) | Medium | High | Legal review before go-live (TR-03) |
| R-5 | No local partner supports split payments, authorization holds or deposits as needed | Medium | High | Evaluate PaySpot and Monri early (OI-05); keep `PaymentGateway` interface partner-agnostic |
| R-6 | Money flow is classified as an unlicensed payment service | Low–Medium | High | Funds flow only through the licensed partner (D-04); legal review (TR-07) |

### 11.4 Open Issues

| ID | Issue | Owner | Needed by | Status |
|---|---|---|---|---|
| OI-01 | Single vs multiple roles per user | Product Owner | Before Module 2 | Resolved: D-01 |
| OI-02 | Data model for rentals and bookings | Architect | Before Module 4b | Resolved: D-06 |
| OI-03 | Commission rates per `ListingType` | Product Owner | Before Module 3 | Resolved: D-05 |
| OI-04 | PSP selection and payout model | Product Owner / Architect | Before Module 3 | Model resolved: D-04; partner choice is OI-05 |
| OI-05 | Choose payment partner and confirm contract terms | Product Owner | Before Module 3 | Open |
| OI-06 | Legal review of the money flow (Law on Payment Services) | Product Owner / Legal | Before go-live | Open |
| OI-07 | Deposit handling for `ASSET` (hold vs capture) | Product Owner / Architect | Before Module 4b | Open |
| OI-08 | Customer cancellation policy and refund rules | Product Owner | Before Module 3 | Resolved: D-10 |
| OI-09 | App language(s) for the pilot | Product Owner | Before client UI work | Resolved: D-11 |
