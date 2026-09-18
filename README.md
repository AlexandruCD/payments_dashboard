# Payments Dashboard

A small Rails app for managing merchants and their payment transactions:
admins manage merchants from a web UI, merchants submit transactions
(authorize / capture / refund / void) through a JWT-authenticated API, and
everyone with access can see the resulting transaction history.

Built as a take-home exercise, so the README doubles as a guide to what's
here and why, not just a run book.

## Stack

- Rails 8.1, Postgres, Slim + Bootstrap for views
- Devise for the admin/merchant login, a separate hand-rolled JWT layer for
  the API (see "Merchant and User are two different things" below — these
  are deliberately not the same thing)
- Solid Queue for background jobs, RSpec/FactoryBot/Capybara/Shoulda
  Matchers for tests, Rubocop + Brakeman for linting/security

## Running it

### Docker (easiest)

```
docker compose up
```

Builds the app image, starts Postgres, waits for it to be healthy, migrates
and seeds the database, and boots the server at http://localhost:3000.
Source is bind-mounted, so code changes reload like normal.

### Natively

Needs Ruby 4.0.2 and a local Postgres.

```
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

## Trying it out

Seeded UI accounts use the password `password123`:

- Admin: `admin@payments-dashboard.test`
- Merchants (UI logins): `acme@payments-dashboard.test`,
  `globex@payments-dashboard.test` (both active), `initech@payments-dashboard.test` (inactive)

Sign in at `/users/sign_in`. Admins land on `/admin/merchants` (create, edit,
delete) and everyone lands on `/transactions`, scoped to their own merchant
unless they're an admin.

### The API

Sign in as an admin, open **Merchants**, select a merchant, and click
**Generate API token**. Copy the token from the result page; its expiry is
shown there. Tokens expire after 24 hours and are not saved for later
retrieval. Generating a token does not revoke previously issued tokens.

Token generation is admin-only and uses a CSRF-protected POST. The former
`POST /api/v1/tokens` password endpoint has been removed. An admin can issue
a token for an inactive merchant, but its transaction requests receive 403
until the merchant is active.

Use the generated token to submit transactions:

```
curl -X POST localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer eyJ..." \
  -d "type=authorize" -d "amount=100" \
  -d "customer_email=buyer@example.com" \
  -d "notification_url=https://example.com/webhook"
```

`type` is one of `authorize` / `capture` / `refund` / `void`; capture/refund/void
also take a `referenced_transaction_uuid` pointing at the transaction they act
on. Both JSON and XML bodies work; XML in gets an XML response back unless
you ask for JSON explicitly.

## Tests

```
bundle exec rspec        # models, services, jobs, requests, and Capybara feature specs
bundle exec rubocop
bin/brakeman
```

## Why it's built this way

A few decisions worth explaining rather than leaving implicit:

**Transactions are one table, four classes.** `Transaction` is a normal STI
setup — `AuthorizeTransaction`, `CaptureTransaction`, `RefundTransaction`,
`VoidTransaction` — because they share almost everything (status, amount,
the merchant they belong to, the transaction they reference) and differ only
in validation rules and what happens on success. The shared "does this
reference a transaction in the right state, and is the amount within what's
left" logic lives in one concern (`ReferenceableTransaction`) instead of
being copy-pasted three times.

**Business logic lives in services, not models or controllers.** Creating a
transaction has real rules (an invalid capture/refund/void still gets
persisted with `status: error` rather than rejected outright; a successful
one flips the status of whatever it references). That's product logic, not
validation, so it's in `app/services/transactions/*`, and controllers just
call into it. The stateless `Transactions::CreateAuthorizeService`,
`CreateCaptureService`, `CreateRefundService`, and `CreateVoidService` share
`ApplicationService.call(merchant:, params:)` and return a `ServiceResult`
with `success?`, `failure?`, `entity`, and `errors`. Each error includes an
attribute, a symbolic code, and a full message. A saved error transaction is
a failure result, but still receives HTTP 201; an invalid authorization is
unsaved and receives HTTP 422. Unexpected infrastructure errors propagate.
`Transactions::CreateTransactionService` dispatches the allowlisted type to
its creation service. `Api::V1::TransactionPresenter` builds the response
fields for JSON/XML, while the controller chooses the HTTP status. UI and
API presenters share initialization through `ApplicationPresenter`; UI
formatting stays separate from the API payload.

**Merchant and User are two different things on purpose.** `User` (Devise)
is who can sign in to the web UI and owns the login password. `Merchant` is
the business identity that owns transactions and is identified by the JWT's
`merchant_id`; it has no password of its own. Admins issue API tokens from
the merchant page through `Merchants::IssueApiTokenService`. The token is
rendered only in the generation response, with HTTP and Turbo caching
disabled.

**Background jobs are real, but the queue backend differs by environment.**
`TransactionProcessingJob` delegates settlement to
`Transactions::ProcessAuthorizationService`, which updates a pending
authorization and enqueues `NotificationJob`. That job delegates the webhook
form POST to `Notifications::SendTransactionNotificationService`; retry
configuration stays in the job, and network exceptions propagate from the
service. These services return `ServiceResult`: processing returns the
transaction, and notification sending returns the HTTP response. Notification
success currently means the request completed, not that the endpoint returned
2xx; response-status handling is unchanged.
Production runs these on Solid Queue (it already has the multi-database
setup for it); development just uses Rails' in-process `:async` adapter,
since setting up a second local database for job storage isn't worth it for
running the app locally. There's also a recurring job
(`StaleAuthorizationSweeperJob`, see `config/recurring.yml`) that marks
authorizations still pending after an hour as errored — a normal request
settles almost instantly, so anything stuck that long means a job actually
failed somewhere. The sweeper job delegates to
`Transactions::SweepStaleAuthorizationsService`, which owns the one-hour
threshold and returns a successful result without an entity when the sweep
completes.

**Every status change is audited, generically.** `AuditLog` belongs to
either a `Merchant` or a `Transaction` polymorphically, and a shared
`Auditable` concern hooks `after_update` on both, so any status transition
gets logged automatically no matter which code path caused it.

## What's not here

- The audit log is backend-only right now — there's no UI for browsing it.
  Given it's already attached to both merchants and transactions, the
  natural next step is a small "Activity" list on their show pages.
- CI (`.github/workflows/ci.yml`) runs Brakeman, bundler-audit, importmap
  audit, and Rubocop, but doesn't run the test suite yet — that's the
  obvious next addition.
- There's no scripted way to run the test suite inside Docker (e.g. a
  `docker compose run` variant with a test database); right now tests are
  expected to run against a native Ruby/Postgres setup.
