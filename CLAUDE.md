# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Click4Cuti is a multi-tenant SaaS web application for HR agencies and companies in Malaysia to manage employee leave digitally. It enforces Malaysian Employment Act 1955 (EA 1955) compliance automatically.

This repo (`click4cuti-api`) is the Rails 8 API. The React SPA is the sibling repo at `../click4cuti-frontend`.

## Commands

```bash
# First-time setup (installs gems, prepares DB, starts server)
bin/setup
bin/setup --reset           # drop & recreate DB
bin/setup --skip-server     # setup without booting Puma

# Dev server
bin/dev                     # Puma on :3000

# Tests (RSpec)
bundle exec rspec                                       # full suite
bundle exec rspec spec/services/leaves                  # one directory
bundle exec rspec spec/services/leaves/apply_service_spec.rb        # one file
bundle exec rspec spec/services/leaves/apply_service_spec.rb:42     # one example by line

# Lint / security (matches CI in .github/workflows/ci.yml)
bin/rubocop                 # rubocop-rails-omakase
bin/rubocop -A              # autocorrect
bin/brakeman --no-pager     # static security scan
bin/bundler-audit           # known gem CVEs
bin/ci                      # runs all of the above (see config/ci.rb)

# Background jobs
bundle exec sidekiq

# Console / DB
bin/rails console
bin/rails dbconsole
bin/rails db:migrate
bin/rails db:seed

# Deploy (Kamal → Linode @ 139.162.38.63, host api-click4cuti.far.my)
bin/kamal deploy
bin/kamal console           # alias → rails c on prod
bin/kamal logs              # alias → app logs -f
bin/kamal dbc               # alias → rails dbconsole on prod
```

CI runs `scan_ruby` (Brakeman + bundler-audit) and `lint` (RuboCop) on PRs and pushes to `main`. There is no automated test job in CI — RSpec is run locally.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 8.1 (API mode), Ruby 3.3+ |
| Frontend | React 19 + TypeScript + Vite 6 + Shadcn/ui + Tailwind CSS 4 |
| Database | PostgreSQL 16 (UUID PKs, native enums) |
| Cache/Queue | Redis 7 + Sidekiq 7 |
| Auth | Devise + devise-jwt (stateless JWT) |
| Authorization | Pundit (policy-based, tenant-scoped) |
| Audit | PaperTrail (model versioning, whodunnit) |
| Serializers | Blueprinter (view-based) |
| File Storage | Active Storage → S3 |
| Monitoring | Lograge + Sentry |
| Test | RSpec + FactoryBot + Faker + Shoulda Matchers + DatabaseCleaner |
| Deploy (API) | Kamal + Docker (Traefik reverse proxy, auto-SSL) |
| Deploy (FE) | Netlify (CDN, SPA fallback) |
| CI | GitHub Actions (Brakeman, bundler-audit, RuboCop) |

## Architecture

- **Decoupled**: Rails API + React SPA, communicating via versioned REST under `/api/v1/*`.
- **Multi-tenant**: Three-tier hierarchy — SuperAdmin → Agency (`HrAgency`) → Company. Tenant isolation is enforced at the controller and Pundit-policy level, not by row-level security.
- **Dual auth domains** (two Devise scopes, both JWT):
  - `User` — employees (roles: `admin`, `manager`, `employee`), authenticated at `/api/v1/auth/*`.
  - `AdminUser` — platform admins (scopes: `super_admin`, `agency`, `company`), authenticated at `/api/v1/admin/auth/*`.
  - `LeaveApplication.approver` is **polymorphic** — either a `User` (manager) or an `AdminUser` (CEO/agency). Note: only `User`s can be assigned via `UserLeaveApprover`; AdminUsers approve only through the `/api/v1/admin/*` namespace, never via `team_requests`.
- **JWT flow**: short-lived access token in memory (1hr) + refresh token in httpOnly cookie + Redis JTI denylist (`JwtDenylist`).

### Request lifecycle (`Api::V1::BaseController`)

Every API controller inherits from `Api::V1::BaseController`, which globally enforces:

```ruby
before_action :authenticate_user!
before_action :set_tenant_scope          # @current_company = current_user.company
after_action  :verify_authorized,    unless: -> { action_name == "index" }
after_action  :verify_policy_scoped, if:     -> { action_name == "index" }
```

This means **every non-index action MUST call `authorize @record`** and **every index action MUST use `policy_scope(...)`** — Pundit will raise if you forget. Admin endpoints (`/api/v1/admin/*`) have a separate base controller under `app/controllers/api/v1/admin/`.

`log_activity(action, entity)` is available in any controller to write to the `activity_logs` table.

## Key Architectural Decisions

- JWT stored in memory only on the frontend (never localStorage).
- All queries scoped to `current_user.company_id` — tenant isolation enforced at model scopes (`for_company`) and policy scopes.
- Pundit `verify_authorized` / `verify_policy_scoped` enforced globally in `BaseController` (see above).
- PaperTrail tracks all state-changing operations with `company_id` metadata via `has_paper_trail meta: { company_id: ... }`.
- **Emergency Leave shares Annual Leave balance pool** (`leave_types.shared_balance_with` FK → see `Leaves::ApplyService#validate_balance!`).
- Leave entitlements use three tiers based on years of service per EA 1955 (see `User#leave_entitlement_tier`).
- `LeaveDayDetail` stores per-day granularity (Full Day, Half Day AM/PM) — read by `Leaves::DurationCalculator`.
- Junction tables (`UserLeavePolicy`, `UserWorkSchedule`, `UserLeaveApprover`) model effective-date-ranged or many-to-many relationships.

## Project Structure

```
click4cuti-api/                    # this repo
├── app/controllers/api/v1/        # versioned API controllers
│   ├── base_controller.rb         # employee-facing base (auth + tenant + Pundit enforcement)
│   ├── admin/                     # admin-facing controllers (mounted at /api/v1/admin/*)
│   └── auth/                      # Devise sessions/passwords/registrations
├── app/models/                    # ActiveRecord models (User, AdminUser, LeaveApplication, ...)
├── app/services/                  # Business logic; see Services section below
├── app/policies/                  # Pundit policies (mirrors controllers/admin split)
├── app/jobs/                      # Sidekiq jobs (LeaveNotificationJob, AnnualBalanceResetJob, ...)
├── app/serializers/               # Blueprinter serializers; views = Default / Detail / Admin
├── config/deploy.yml              # Kamal config
├── config/routes.rb               # see for the canonical API surface
└── spec/                          # RSpec — services/, requests/api/v1/, support/auth_helpers.rb

../click4cuti-frontend/            # sibling repo — React SPA (Vite, TanStack Query, Zustand)
```

## Services (where business logic lives)

Complex flows are extracted into `app/services/` — controllers stay thin.

- `Leaves::ApplyService` — validates leave type & balance, builds the application + day details, increments pending balance, enqueues notification, runs `WarningChecker`.
- `Leaves::ApprovalService` — approves/rejects, moves balance from pending → used.
- `Leaves::BalanceCalculator` — computes entitlement & remaining days (respecting `shared_balance_with`).
- `Leaves::DurationCalculator` — computes working days from a date range + `LeaveDayDetail` half-day flags + work schedule + public holidays.
- `Leaves::WarningChecker` — auto-creates warning letters when Emergency Leave > 3/year.
- `Users::OnboardService` / `Companies::OnboardService` — creation flows for new tenants/employees.
- `Dashboard::StatsService` / `Dashboard::AdminStatsService` — aggregates for the dashboard endpoint.

When adding new business logic, prefer a new service over fattening a controller or model.

## Conventions

- **API versioning**: all endpoints under `/api/v1/`. Admin endpoints under `/api/v1/admin/`.
- **Serializer views**: `:default` (list), `:detail` (show), `:admin` (extended with audit data).
- **Query keys (frontend)**: namespaced — `['leaves', 'list']`, `['admin', 'users', 'list']`, `['dashboard']`.
- **Git workflow**: `main` → production, `develop` → staging, feature branches → PR to `develop`.
- **Tests**:
  - Use `auth_headers_for_user(user)` / `auth_headers_for_admin(admin)` from `spec/support/auth_helpers.rb` for authenticated request specs.
  - `DatabaseCleaner` runs `:transaction` per example; `:truncation` once before the suite.
  - Service specs live in `spec/services/<namespace>/`; request specs in `spec/requests/api/v1/`.

## Reference Docs

Detailed documentation lives at the repo root (not under `docs/`):

- `PRD.md` — full Product Requirements Document (functional requirements, leave rules, user roles, notifications).
- `TECHNICAL_ARCHITECTURE.md` — detailed technical architecture (auth flow, Pundit policies, API routes, deployment, security).
- `ERD.md` — complete Entity Relationship Diagram (all entities, fields, types, relationships).
- `LEAVE_POLICY.md` — Malaysian Employment Act 1955 leave policy reference (Malay + English).

## Critical Business Rules

1. **Leave entitlement tiers** (EA 1955): AL: 8/12/16 days, SL: 14/18/22 days based on <2yr / 2–5yr / >5yr service.
2. **Emergency Leave** shares the Annual Leave balance pool.
3. **Maternity**: 60 consecutive days, limited to first 5 living children, requires 60-day advance notice.
4. **Paternity**: 7 consecutive days, limited to 5 times total, requires 12 months service.
5. **Warning letters**: auto-generated when Emergency Leave exceeds 3 times/year (`Leaves::WarningChecker`).
6. **Public Holidays**: 11 paid PH/year — 5 mandatory + 6 employer's choice.
7. **Sick Leave**: must notify employer within 48 hours; non-compliance = unauthorised absence.
8. **Max consecutive days**: default 3 for AL; exceeding requires `extended_reason` + CEO approval (enforced in `LeaveApplication` validation + `Leaves::ApplyService`).
9. **Document upload**: mandatory for Medical Leave, optional for others.
10. **Hospitalisation**: total SL + hospitalisation capped at 60 days/year.
