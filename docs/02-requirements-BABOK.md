# L\*ease: Requirements Specification (BABOK® v3 aligned)

| Field | Value |
|---|---|
| Document ID | LEASE-DOC-02 |
| Status | Draft for stakeholder review |
| Version | 0.1 |
| Standard | IIBA® *A Guide to the Business Analysis Body of Knowledge®* (BABOK® Guide) v3 |
| Related | [01-ux-strategy.md](./01-ux-strategy.md), [03-high-level-architecture.md](./03-high-level-architecture.md), `backend/prisma/schema.prisma` |

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

**In scope (MVP, Phase 1–2):** user registration and authentication with role-based access; listing management for `SERVICE`, `RETAIL` and `ASSET` types; marketplace discovery; checkout with online payment; order lifecycle; reviews tied to orders; basic asset-sharing rules; admin moderation.

**Out of scope (MVP):** in-app real-time chat; native payouts and marketplace ledger (handled by the payment provider); dynamic pricing; multi-currency conversion (EUR only); logistics and delivery integration; the native mobile app (the future Flutter frontend consumes the same API).

### 1.4 Definitions

| Term | Definition |
|---|---|
| Customer | A `User` with `role = CUSTOMER` who buys, books or rents listings |
| Provider | A `User` with `role = PROVIDER` who publishes listings and fulfils orders |
| Admin | A `User` with `role = ADMIN`; internal platform operator |
| Listing | An offer published by a provider; `type` ∈ {`SERVICE`, `RETAIL`, `ASSET`} |
| Order | A customer's purchase, booking or rental of exactly one listing |
| Review | A rating and comment that a customer gives about a provider and listing for one order |
| PSP | Payment Service Provider (e.g. Stripe). `Order.paymentIntentId` references the PSP payment object. |
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
| BR-01 | The organization shall provide a single marketplace that supports three offer types: services, retail goods and shared assets. | M | BG-1 |
| BR-02 | The organization shall collect customer payments online at checkout so that providers are protected against non-payment and customers against non-delivery. | M | BG-2, BG-3 |
| BR-03 | The organization shall earn revenue as a commission on each completed order. | M | BG-2 |
| BR-04 | The organization shall build verifiable reputation by allowing reviews only for real, completed orders. | M | BG-3 |
| BR-05 | The organization shall be able to moderate content and users, and resolve disputes including refunds. | M | BG-3 |
| BR-06 | The organization shall comply with EU data-protection (GDPR) and consumer-protection obligations applicable to online marketplaces. | M | BG-3 |
| BR-07 | The solution shall be extensible to a native mobile client (Flutter) without re-implementing business logic. | S | BG-1 |

### 4.3 Business Objectives & Measures (SMART)

Targets are **[Assumption]** values and need product-owner sign-off.

| ID | Objective | Measure | Target | Trace |
|---|---|---|---|---|
| BO-1 | Supply liquidity | Active listings (`isActive = true`) in pilot city | ≥ 500 within 6 months of launch | BR-01 |
| BO-2 | Demand traction | Completed orders per month | ≥ 1,000 by month 9 | BR-01, BR-02 |
| BO-3 | Monetization | Net take rate on GMV | ≥ 10% by month 12 | BR-03 |
| BO-4 | Trust | Orders ending in `REFUNDED` after dispute | ≤ 2% of completed orders | BR-04, BR-05 |
| BO-5 | Quality | Average review rating | ≥ 4.5 / 5 | BR-04 |

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
| Payment Service Provider | Payment processing, compliance (PSD2/SCA) | Medium | I |
| Legal / Compliance (DPO) | GDPR, terms, consumer law | Medium | C |

### 5.2 Stakeholder Requirements

| ID | Stakeholder | Statement | Priority | Trace |
|---|---|---|---|---|
| SR-01 | Customer | I need to browse and search offers and see the full price without having to register. | M | BR-01 |
| SR-02 | Customer | I need to pay securely online and know that my money is protected if the order is not fulfilled. | M | BR-02, BR-05 |
| SR-03 | Customer | I need to track the status of my orders. | M | BR-02 |
| SR-04 | Customer | I need trustworthy reviews from people who actually completed an order. | M | BR-04 |
| SR-05 | Provider | I need to publish and manage services, goods and rentable assets from one account. | M | BR-01 |
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

**Entities:** `User` (`id`, `email` [unique], `password` [hash], `firstName`, `lastName`, `role` [`CUSTOMER` | `PROVIDER` | `ADMIN`, default `CUSTOMER`], `createdAt`, `updatedAt`).
**NestJS modules:** `AuthModule`, `UsersModule`.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M1-01 | The system shall allow a visitor to register with email, password, first name and last name, choosing role `CUSTOMER` or `PROVIDER`. | M | SR-01, SR-05 |
| FR-M1-02 | The system shall reject registration if the email is already in use (case-insensitive). | M | SR-12 |
| FR-M1-03 | The system shall store passwords only as a salted, adaptive hash (argon2id or bcrypt); plaintext passwords shall never be persisted or logged. | M | SR-12 |
| FR-M1-04 | The system shall authenticate users by email and password and issue a short-lived access token (JWT) and a rotating refresh token. | M | SR-13 |
| FR-M1-05 | The system shall allow an authenticated user to log out, revoking the refresh token. | M | SR-12 |
| FR-M1-06 | The system shall allow an authenticated user to view and update their profile (`firstName`, `lastName`). Changing `email` or `password` requires the current password. | M | SR-12 |
| FR-M1-07 | The system shall enforce role-based access control (RBAC) on every protected endpoint using `User.role`. | M | SR-10 |
| FR-M1-08 | The system shall not allow self-registration with role `ADMIN`; admins are created only by an existing admin or a seed script. | M | SR-10 |
| FR-M1-09 | The system shall provide a public provider profile showing name, member-since date, active listings and aggregate rating, and no email or other private data. | M | SR-08 |
| FR-M1-10 | The system shall support password reset through a single-use, time-limited token sent by email. | S | SR-12 |
| FR-M1-11 | The system shall support email verification before a provider can publish a listing. | S | BR-05 |
| FR-M1-12 | The system shall allow a user to export their personal data (JSON) and request account deletion (GDPR Art. 15, 17, 20). | M | SR-12 |
| FR-M1-13 | Admins shall be able to list, search and suspend users. | M | SR-10 |

**Acceptance criteria (examples):**

- **AC-M1-01-a:** *Given* no user exists with `mila@example.com`, *when* a visitor registers with valid data and role `CUSTOMER`, *then* a `User` is created with `role = CUSTOMER`, the response contains no password field, and HTTP 201 is returned.
- **AC-M1-02-a:** *Given* a user with `Mila@Example.com` exists, *when* a visitor registers with `mila@example.com`, *then* HTTP 409 is returned and no user is created.
- **AC-M1-07-a:** *Given* an authenticated `CUSTOMER`, *when* they call a `PROVIDER`-only endpoint (e.g. create listing), *then* HTTP 403 is returned.
- **AC-M1-08-a:** *Given* a registration request with `role = ADMIN`, *then* HTTP 400 is returned.

> **Open issue OI-01:** The data model holds **one** `role` per user. If a person must be both customer and provider (see UX §8, Q4), the model needs a change, for example a `roles Role[]` field or a provider-profile relation. Decision needed before Module 2 starts.

### Module 2: Listings & Marketplace

**Entities:** `Listing` (`id`, `title`, `description`, `price` [Decimal(10,2)], `type` [`SERVICE` | `RETAIL` | `ASSET`], `metadata` [JSON], `isActive` [default true], `providerId` → `User`, timestamps). Indexes on `type` and `providerId`.
**NestJS module:** `ListingsModule`.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M2-01 | The system shall allow a `PROVIDER` to create a listing with title, description, price (> 0, max 2 decimals, max 99,999,999.99), type and optional type-specific metadata. | M | SR-05 |
| FR-M2-02 | The system shall validate `metadata` against a per-type schema (see UX §5.4) and reject unknown or invalid keys. | S | SR-05 |
| FR-M2-03 | The system shall allow a provider to update or deactivate (`isActive = false`) **only their own** listings. | M | SR-05 |
| FR-M2-04 | The system shall prevent hard deletion of listings that have orders; deletion becomes deactivation. | M | SR-11 |
| FR-M2-05 | The system shall provide a public, paginated catalogue of active listings (`isActive = true`), filterable by `type`, price range and keyword (title/description), and sortable by newest, price and rating. | M | SR-01 |
| FR-M2-06 | The system shall provide a public listing detail view with provider summary, aggregate rating, review count and recent reviews. | M | SR-01, SR-04 |
| FR-M2-07 | The system shall provide a provider "My listings" view including inactive listings. | M | SR-05 |
| FR-M2-08 | The system shall allow an admin to deactivate any listing and record the reason. | M | SR-10 |
| FR-M2-09 | Inactive listings shall not be orderable and shall not appear in public search. | M | SR-01 |
| FR-M2-10 | The system shall support listing images (upload to object storage; URLs referenced in `metadata` or a future `ListingImage` model). | S | SR-01 |
| FR-M2-11 | The system shall support location-based search (distance from customer). | C | SR-01 |

**Acceptance criteria (examples):**

- **AC-M2-03-a:** *Given* provider A owns listing L, *when* provider B tries to update L, *then* HTTP 403 (or 404 to avoid revealing existence) is returned and L is unchanged.
- **AC-M2-05-a:** *Given* 30 active and 5 inactive `ASSET` listings, *when* a guest requests `type=ASSET&page=1&pageSize=20`, *then* 20 active listings are returned with `total = 30`.
- **AC-M2-01-a:** *Given* a provider submits `price = -5`, *then* HTTP 400 is returned with a field-level validation error.

### Module 3: Orders & Checkout

**Entities:** `Order` (`id`, `amount` [Decimal(10,2)], `currency` [default `EUR`], `status` [`OrderStatus`], `paymentIntentId` [unique, nullable], `customerId`, `providerId`, `listingId`, timestamps). Indexes on `customerId`, `providerId`, `status`.
**NestJS modules:** `OrdersModule`, `PaymentsModule`.

**Order state model (normative):**

| From → To | Actor | Precondition |
|---|---|---|
| (new) → `PENDING` | Customer | Listing active; payment intent created; customer ≠ provider |
| `PENDING` → `CONFIRMED` | Provider (owner) | Payment authorized or captured (PSP webhook) |
| `PENDING` → `CANCELLED` | Customer, Provider, System (timeout) | No fulfilment started |
| `CONFIRMED` → `IN_PROGRESS` | Provider | n/a |
| `CONFIRMED` → `CANCELLED` | Customer, Provider, Admin | Cancellation policy applies |
| `IN_PROGRESS` → `COMPLETED` | Provider (customer may confirm, see FR-M3-08) | n/a |
| `CANCELLED` → `REFUNDED` | System / Admin | Captured funds returned through PSP |
| `COMPLETED` → `REFUNDED` | Admin | Dispute upheld |

Any other transition shall be rejected.

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M3-01 | The system shall allow an authenticated `CUSTOMER` to create an order for one active listing. `amount` is computed **server-side** from the listing price (and quantity or rental days where applicable), never taken from the client. | M | SR-02 |
| FR-M3-02 | The system shall set `Order.providerId` from `Listing.providerId` and reject orders where the customer is the listing's provider. | M | SR-02 |
| FR-M3-03 | The system shall create a PSP payment intent for `amount` / `currency` and store its id in `paymentIntentId`. | M | SR-02, SR-06 |
| FR-M3-04 | The system shall process PSP webhooks idempotently, verifying the webhook signature, and update order/payment state accordingly. | M | SR-02 |
| FR-M3-05 | The system shall enforce the order state model above and reject invalid transitions with HTTP 409. | M | SR-03, SR-07 |
| FR-M3-06 | The system shall record an audit entry (actor, from, to, timestamp, reason) for every status change. | M | SR-11 |
| FR-M3-07 | The system shall allow customers to list and view their orders (`ordersAsCustomer`) and providers theirs (`ordersAsProvider`), filterable by status. | M | SR-03, SR-07 |
| FR-M3-08 | The system shall automatically cancel `PENDING` orders not confirmed within a configurable SLA (default 24 hours) and trigger a refund. | S | SR-02, SR-06 |
| FR-M3-09 | The system shall allow an admin to refund an order (full refund in MVP), moving it to `REFUNDED` through the PSP. | M | SR-11 |
| FR-M3-10 | The system shall notify the counterpart by email on each status change. | S | SR-03 |
| FR-M3-11 | The system shall provide providers with an earnings summary (sum of `COMPLETED` amounts minus commission) for a date range. | S | SR-07, BR-03 |
| FR-M3-12 | The system shall support partial refunds. | W | n/a |

**Acceptance criteria (examples):**

- **AC-M3-01-a:** *Given* a listing priced 49.90 EUR, *when* the customer submits an order with a tampered `amount = 1.00`, *then* the order is created with `amount = 49.90` (client amount ignored).
- **AC-M3-04-a:** *Given* a `payment_intent.succeeded` webhook is delivered twice, *then* the order state changes only once and both deliveries return HTTP 2xx.
- **AC-M3-05-a:** *Given* an order in `COMPLETED`, *when* a provider requests a transition to `IN_PROGRESS`, *then* HTTP 409 is returned.

### Module 4: Reviews & Asset Sharing

**Entities:** `Review` (`id`, `rating` [Int, default 5], `comment`, `authorId`, `targetId`, `listingId`, `orderId` [unique], timestamps). Index on `listingId`. Asset sharing uses `Listing` with `type = ASSET` and `metadata`, plus the proposed extensions in FR-M4-08 to FR-M4-12.
**NestJS modules:** `ReviewsModule`, `RentalsModule` (asset sharing).

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

**4b: Asset Sharing (`ListingType.ASSET`)**

| ID | Requirement | Priority | Trace |
|---|---|---|---|
| FR-M4-08 | The system shall allow an `ASSET` listing to define pricing unit (day/week), minimum rental period, deposit amount and pickup location in `metadata`. | S | SR-09 |
| FR-M4-09 | The system shall require a customer ordering an `ASSET` to choose a rental start and end date, and compute `amount` = unit price × units (+ deposit, held separately). | S | SR-09 |
| FR-M4-10 | The system shall prevent overlapping rentals of the same asset for `CONFIRMED` / `IN_PROGRESS` orders. | S | SR-09 |
| FR-M4-11 | The system shall support check-out and check-in condition records (notes and photos) at handover and return. | C | SR-09, SR-11 |
| FR-M4-12 | The system shall release or capture the deposit based on the check-in outcome, with admin override in a dispute. | C | SR-09, SR-11 |

> **Open issue OI-02 (schema gap):** FR-M4-09 to FR-M4-12 need data the current schema lacks: rental `startDate`/`endDate`, deposit tracking and condition records. The proposal is a `Rental` model (1:1 with `Order`) in a later migration, rather than overloading `metadata`. This keeps availability queries indexable.

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
| NFR-PRI-01 | Privacy | Personal data processing shall comply with GDPR: lawful basis, data minimization, retention policy, DPA with processors. | M |
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
| NFR-I18N-01 | Localization | API returns machine-readable error codes. Currency formatting is client-side. MVP currency is EUR. | S |
| NFR-PORT-01 | Portability | All services run in Docker; local dev through `docker compose`. | M |

---

## 8. Data Requirements (Data Dictionary Summary)

| Entity | Attribute | Type | Rules |
|---|---|---|---|
| User | email | String, unique | Valid email, normalized lowercase |
| User | password | String | Hash only (FR-M1-03) |
| User | role | Enum Role | `CUSTOMER` default; `ADMIN` not self-assignable |
| Listing | price | Decimal(10,2) | > 0 |
| Listing | type | Enum ListingType | Required, immutable after first order **[Proposed]** |
| Listing | metadata | JSON | Validated per type (FR-M2-02) |
| Order | amount | Decimal(10,2) | Server-computed (FR-M3-01) |
| Order | currency | String | ISO 4217; `EUR` in MVP |
| Order | paymentIntentId | String, unique, nullable | Set by `PaymentsModule` |
| Review | rating | Int | 1..5, required in API |
| Review | orderId | String, unique | Order must be `COMPLETED` |

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

---

## 10. Traceability Matrix (summary)

| Business req. | Stakeholder req. | Functional req. |
|---|---|---|
| BR-01 | SR-01, SR-05, SR-09 | FR-M2-01…11, FR-M4-08…12 |
| BR-02 | SR-02, SR-03, SR-06, SR-07 | FR-M3-01…10 |
| BR-03 | SR-07 | FR-M3-11 |
| BR-04 | SR-04, SR-08 | FR-M1-09, FR-M4-01…07 |
| BR-05 | SR-10, SR-11 | FR-M1-07, FR-M1-08, FR-M1-13, FR-M2-08, FR-M3-06, FR-M3-09, FR-M4-06 |
| BR-06 | SR-12 | FR-M1-02, FR-M1-03, FR-M1-05, FR-M1-06, FR-M1-10, FR-M1-12, NFR-PRI-* |
| BR-07 | SR-13 | FR-M1-04, NFR-INT-01 |

---

## 11. Assumptions, Constraints, Risks & Open Issues

### 11.1 Assumptions

- A-1: A PSP with marketplace support (e.g. Stripe Connect) will handle payment capture, refunds and provider payouts.
- A-2: MVP operates in a single EU country, in EUR.
- A-3: Providers fulfil orders offline (in person); the platform does not handle logistics.

### 11.2 Constraints

- C-1: Technology baseline: NestJS (TypeScript, ESM), PostgreSQL, Prisma ORM 6.x, Docker.
- C-2: Data model baseline is `backend/prisma/schema.prisma` (Phase 1). Changes require migrations.

### 11.3 Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Chicken-and-egg liquidity problem | High | High | Single pilot city; supply-first onboarding (TR-04) |
| R-2 | Payment fraud / chargebacks | Medium | High | PSP risk tools, SCA, payment-before-confirm |
| R-3 | Damage disputes in asset rentals | Medium | Medium | Deposits, condition records (FR-M4-11/12) |
| R-4 | Regulatory (platform-work, consumer law) | Medium | High | Legal review before go-live (TR-03) |
| R-5 | Single-role model limits users | Medium | Medium | Resolve OI-01 early |

### 11.4 Open Issues

| ID | Issue | Owner | Needed by |
|---|---|---|---|
| OI-01 | Single vs multiple roles per user | Product Owner | Before Module 2 |
| OI-02 | `Rental` model for asset sharing | Architect | Before Module 4b |
| OI-03 | Commission rates per `ListingType` | Product Owner | Before Module 3 |
| OI-04 | PSP selection and payout model | Product Owner / Architect | Before Module 3 |
