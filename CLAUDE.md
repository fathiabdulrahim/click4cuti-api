# Click4Cuti — HR Leave Management Platform

## Project Overview

Click4Cuti is a multi-tenant SaaS web application for HR agencies and companies in Malaysia to manage employee leave digitally. It enforces Malaysian Employment Act 1955 (EA 1955) compliance automatically.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 8 (API mode), Ruby 3.3+ |
| Frontend | React 19 + TypeScript + Vite 6 + Shadcn/ui + Tailwind CSS 4 |
| Database | PostgreSQL 16 (UUID PKs, native enums) |
| Cache/Queue | Redis 7 + Sidekiq 7 |
| Auth | Devise + devise-jwt (stateless JWT) |
| Authorization | Pundit (policy-based, tenant-scoped) |
| Audit | PaperTrail (model versioning, whodunnit) |
| File Storage | Active Storage → S3 |
| Server State | TanStack Query 5 |
| Client State | Zustand 5 |
| Routing | React Router 7 |
| HTTP Client | Axios (JWT interceptors) |
| Forms | React Hook Form + Zod validation |
| Deploy (API) | Kamal + Docker (Traefik reverse proxy, auto-SSL) |
| Deploy (FE) | Netlify (CDN, SPA fallback) |
| CI/CD | GitHub Actions |

## Architecture

- **Decoupled**: Rails API backend + React SPA frontend, communicating via versioned REST (`/api/v1/*`)
- **Multi-tenant**: Three-tier hierarchy — SuperAdmin → Agency → Company
- **Dual auth domains**: `ADMIN_USERS` (platform admins with scope) + `USERS` (employees with role)
- **JWT flow**: Short-lived access token (1hr) in memory + refresh token in httpOnly cookie + Redis JTI denylist

## Key Architectural Decisions

- JWT stored in memory only (never localStorage)
- All queries scoped to `current_user.company_id` — tenant isolation is enforced at model/controller level
- Pundit policies enforced globally via `after_action :verify_authorized`
- PaperTrail tracks all state-changing operations with `company_id` metadata
- Emergency Leave shares Annual Leave balance pool (`shared_balance_with` FK)
- Leave entitlements use three tiers based on years of service per EA 1955
- `LEAVE_DAY_DETAILS` stores per-day granularity (Full Day, Half Day AM/PM)
- Junction tables (`USER_LEAVE_POLICIES`, `USER_WORK_SCHEDULES`) use effective date ranges

## Project Structure

```
click4cuti-api/          # Rails API
├── app/controllers/api/v1/   # Versioned API controllers
├── app/models/               # ActiveRecord models
├── app/services/             # Business logic (Leaves::ApplyService, etc.)
├── app/policies/             # Pundit authorization policies
├── app/jobs/                 # Sidekiq async jobs
├── app/mailers/              # Action Mailer
├── app/serializers/          # Blueprinter JSON serializers
├── config/deploy.yml         # Kamal config
└── spec/                     # RSpec tests

click4cuti-web/          # React SPA
├── src/api/                  # Axios instance + endpoint functions
├── src/components/           # ui/ (Shadcn), layout/, forms/, tables/, shared/
├── src/hooks/                # useAuth, useLeaves, useAdmin
├── src/stores/               # Zustand stores (auth, sidebar, notifications, filters)
├── src/pages/                # auth/, dashboard/, leaves/, profile/, admin/
├── src/router/               # Routes + guards (AuthGuard, RoleGuard, ScopeGuard)
└── src/lib/                  # utils, types
```

## Conventions

- **API versioning**: All endpoints under `/api/v1/`
- **Service objects**: Complex business logic in `app/services/` (e.g., `Leaves::ApplyService`, `Leaves::ApprovalService`)
- **Serializer views**: Default (list), Detail (show), Admin (extended with audit data)
- **Query keys**: Namespaced — `['leaves', 'list']`, `['admin', 'users', 'list']`, `['dashboard']`
- **Zustand stores**: Auth, sidebar UI, notifications, leave form, table filters
- **Git workflow**: `main` → production, `develop` → staging, feature branches → PR to develop

## Reference Docs

Detailed documentation lives in `docs/`:

- `docs/PRD.md` — Full Product Requirements Document (functional requirements, leave rules, user roles, notifications)
- `docs/TECHNICAL_ARCHITECTURE.md` — Detailed technical architecture (auth flow, Pundit policies, API routes, deployment, security)
- `docs/ERD.md` — Complete Entity Relationship Diagram (19 entities, all fields/types/relationships)
- `docs/LEAVE_POLICY.md` — Malaysian Employment Act 1955 leave policy reference (in Malay + English)

## Critical Business Rules

1. **Leave entitlement tiers** (EA 1955): AL: 8/12/16 days, SL: 14/18/22 days based on <2yr / 2-5yr / >5yr service
2. **Emergency Leave** shares Annual Leave balance pool
3. **Maternity**: 60 consecutive days, limited to first 5 living children, requires 60-day advance notice
4. **Paternity**: 7 consecutive days, limited to 5 times total, requires 12 months service
5. **Warning letters**: Auto-generated when Emergency Leave exceeds 3 times/year
6. **Public Holidays**: 11 paid PH/year — 5 mandatory + 6 employer's choice
7. **Sick Leave**: Must notify employer within 48 hours; non-compliance = unauthorised absence
8. **Max consecutive days**: Default 3 for AL; exceeding requires extended reason + CEO approval
9. **Document upload**: Mandatory for Medical Leave, optional for others
10. **Hospitalisation**: Total SL + hospitalisation capped at 60 days/year
