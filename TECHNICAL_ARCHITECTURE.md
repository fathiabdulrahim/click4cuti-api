# Click4Cuti — Technical Architecture Document

**Version:** 1.0 | **Date:** April 2026 | **Status:** Draft

---

## 1. System Architecture

### 1.1 High-Level Architecture

Decoupled architecture: Rails API backend + React SPA frontend via versioned REST over HTTPS.

| Component | Responsibility | Hosted on |
|-----------|---------------|-----------|
| React SPA | UI rendering, client routing, form validation, role-based views | Netlify CDN |
| Rails API | Business logic, auth, validation, leave calculations, file uploads | Docker via Kamal |
| PostgreSQL | Persistent data, UUID PKs, tenant isolation | Managed DB or same host |
| Redis | Sidekiq queue, JWT denylist, Rails cache | Same host or managed |
| Sidekiq | Async email, warning letters, balance recalculation | Same container / sidecar |
| S3 / Minio | Leave document storage via Active Storage | AWS S3 or compatible |

### 1.2 Request Flow

1. User opens browser → Netlify serves React SPA (static via CDN)
2. React makes API calls to `api.click4cuti.com/api/v1/*` with JWT in Authorization header
3. Rails authenticates via Devise-JWT, resolves tenant scope, processes request
4. JSON response → React updates via TanStack Query cache + Zustand stores
5. Background jobs (emails, warnings) dispatched to Sidekiq via Redis
6. File uploads → Rails API → Active Storage → S3

### 1.3 Environment URLs

| Environment | Frontend | API |
|-------------|----------|-----|
| Development | http://localhost:5173 | http://localhost:3000 |
| Staging | https://staging.click4cuti.com | https://api-staging.click4cuti.com |
| Production | https://app.click4cuti.com | https://api.click4cuti.com |

---

## 2. Authentication (Devise + JWT)

### 2.1 Gem Setup

- `devise` — user model, bcrypt password hashing, password reset
- `devise-jwt` — JWT token strategy with denylist revocation (Redis)
- Separate Devise models: `AdminUser` (platform admins) and `User` (employees)

### 2.2 JWT Flow

1. `POST /api/v1/auth/sign_in` with email + password
2. Devise authenticates → devise-jwt generates access token (1 hour)
3. Token in `Authorization: Bearer <token>` header
4. React stores token in memory + refresh token in httpOnly cookie
5. `POST /api/v1/auth/refresh` for new access token
6. `POST /api/v1/auth/sign_out` adds JTI to Redis denylist

### 2.3 Dual Authentication Domains

| Aspect | AdminUser | User (Employee) |
|--------|-----------|----------------|
| Login endpoint | /api/v1/admin/auth/sign_in | /api/v1/auth/sign_in |
| Scope field | scope (SUPER_ADMIN, AGENCY, COMPANY) | role (ADMIN, MANAGER, EMPLOYEE) |
| Tenant resolution | agency_id / company_id | company_id |
| Token prefix | admin-jwt | user-jwt |
| Password reset | /api/v1/admin/auth/password | /api/v1/auth/password |

---

## 3. Authorization (Pundit)

All controller actions authorised through Pundit policies. Each resolves permissions based on user role/scope + tenant context.

### 3.1 Policy Example — LeaveApplicationPolicy

```ruby
class LeaveApplicationPolicy < ApplicationPolicy
  def index? = true
  def create? = user.employee? || user.manager? || user.admin?
  def approve? = (user.manager? && record.user.manager_id == user.id) || user.admin?
  def destroy? = record.user_id == user.id && record.pending?

  class Scope < Scope
    def resolve
      if user.admin?
        scope.where(company_id: user.company_id)
      elsif user.manager?
        scope.where(user_id: user.managed_user_ids + [user.id])
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
```

### 3.2 Admin Policy — Scope-Based Access

```ruby
class Admin::CompanyPolicy < ApplicationPolicy
  def index? = admin_user.super_admin? || admin_user.agency?
  def create? = admin_user.super_admin? || admin_user.agency?

  class Scope < Scope
    def resolve
      case admin_user.scope
      when 'SUPER_ADMIN' then scope.all
      when 'AGENCY' then scope.where(agency_id: admin_user.agency_id)
      when 'COMPANY' then scope.where(id: admin_user.company_id)
      end
    end
  end
end
```

### 3.3 Policy Map

| Policy | Key permissions | Scope resolution |
|--------|----------------|-----------------|
| LeaveApplicationPolicy | create (all), approve (manager+), destroy (owner, pending) | Admin: company; Manager: team; Employee: own |
| UserPolicy | index/show (admin+), create/update/deactivate (admin) | Admin: own company; Agency: companies; Super: all |
| CompanyPolicy | CRUD (super/agency), read (company admin) | Super: all; Agency: own; Company: own only |
| AgencyPolicy | CRUD (super only) | Super: all; others: denied |
| LeavePolicyPolicy | CRUD (admin+), read (all) | Scoped to current company |
| PublicHolidayPolicy | CRUD (admin+), read (all) | Scoped to current company |
| WarningLetterPolicy | read only (admin+) | Scoped to current company |
| ProfilePolicy | read/update own only | Current user only |

### 3.4 Global Enforcement

```ruby
class Api::V1::BaseController < ApplicationController
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_tenant_scope
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def set_tenant_scope
    @current_company = current_user.company
  end

  def policy_scope(scope)
    super(scope.where(company: @current_company))
  end
end
```

### 3.5 Admin Scoping

- SuperAdmin → no filter (sees everything)
- Agency → `Company.where(agency_id: current_admin.agency_id)`
- Company → `Company.where(id: current_admin.company_id)`

---

## 4. Audit Trail (PaperTrail)

### 4.1 Setup

All audited models tracked with custom metadata:

```ruby
class User < ApplicationRecord
  has_paper_trail meta: {
    company_id: :company_id,
    request_ip: -> { PaperTrail.request.controller_info&.dig(:ip) }
  }
end

class LeaveApplication < ApplicationRecord
  has_paper_trail meta: {
    company_id: :company_id,
    status_change: -> (la) { la.status_previously_changed? ? la.status : nil }
  }
end
```

### 4.2 Whodunnit Tracking

```ruby
def user_for_paper_trail
  current_user&.id&.to_s || current_admin_user&.id&.to_s
end

def info_for_paper_trail
  { ip: request.remote_ip, user_agent: request.user_agent }
end
```

### 4.3 Audited Models

| Model | Tracked fields | Custom metadata |
|-------|---------------|----------------|
| User | All except password_digest | company_id, request_ip |
| LeaveApplication | status, approved_by, reviewer_remarks, dates | company_id, status_change |
| LeaveBalance | used_days, remaining_days, carried_forward | company_id |
| Company | name, registration_number, hr_email, is_active | agency_id |
| LeavePolicy | name, advance_notice_days, is_active | company_id |
| LeaveType | default_days tiers, max_consecutive_days, flags | company_id via policy |
| PublicHoliday | name, holiday_date, is_mandatory | company_id |
| WarningLetter | reason, acknowledged, acknowledged_at | company_id |
| AdminUser | scope, is_active, agency_id, company_id | scope |

### 4.4 Versions Table Schema

```ruby
create_table :versions do |t|
  t.string   :item_type, null: false
  t.uuid     :item_id,   null: false
  t.string   :event,     null: false  # create, update, destroy
  t.string   :whodunnit              # user UUID
  t.jsonb    :object                 # snapshot before change
  t.jsonb    :object_changes         # diff
  t.uuid     :company_id             # tenant scoping
  t.string   :request_ip
  t.string   :status_change          # leave transitions
  t.datetime :created_at
end
```

---

## 5. API Routes

### 5.1 Route Structure

```ruby
namespace :api do
  namespace :v1 do
    devise_for :users, path: 'auth'
    devise_for :admin_users, path: 'admin/auth'

    resource  :profile, only: [:show, :update]
    resource  :dashboard, only: [:show]
    resources :leaves
    resources :leave_balances, only: [:index]
    resources :public_holidays, only: [:index]
    resources :team_requests, only: [:index, :update]

    namespace :admin do
      resource  :dashboard, only: [:show]
      resources :agencies
      resources :companies
      resources :users
      resources :departments
      resources :designations
      resources :leave_policies
      resources :leave_types
      resources :work_schedules
      resources :public_holidays
      resources :leave_applications
      resources :warning_letters, only: [:index, :show]
      resources :activity_logs, only: [:index]
    end
  end
end
```

### 5.2 Key Endpoints

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| POST | /api/v1/auth/sign_in | Login (employee) | Public |
| DELETE | /api/v1/auth/sign_out | Logout | Authenticated |
| POST | /api/v1/auth/password | Request password reset | Public |
| PUT | /api/v1/auth/password | Reset password with token | Public |
| GET | /api/v1/dashboard | Employee dashboard | Employee+ |
| GET | /api/v1/leaves | My leave history | Employee+ |
| POST | /api/v1/leaves | Apply for leave | Employee+ |
| PUT | /api/v1/leaves/:id | Edit pending leave | Owner only |
| DELETE | /api/v1/leaves/:id | Cancel pending leave | Owner only |
| GET | /api/v1/leave_balances | My leave balances | Employee+ |
| GET | /api/v1/team_requests | Team pending requests | Manager+ |
| PUT | /api/v1/team_requests/:id | Approve / reject | Manager+ |
| GET | /api/v1/profile | My profile | Employee+ |
| PUT | /api/v1/profile | Update profile | Employee+ |
| GET | /api/v1/admin/dashboard | Admin KPIs | Admin+ |
| CRUD | /api/v1/admin/users | User management | Admin+ |
| CRUD | /api/v1/admin/companies | Company management | Agency+ / SuperAdmin |
| CRUD | /api/v1/admin/agencies | Agency management | SuperAdmin only |
| CRUD | /api/v1/admin/leave_policies | Policy config | Admin+ |

---

## 6. Service Objects

| Service | Responsibility |
|---------|---------------|
| Leaves::ApplyService | Validate, check balance, create leave + day details, trigger notification |
| Leaves::ApprovalService | Approve/reject, update balance, check CEO escalation, trigger email |
| Leaves::BalanceCalculator | Entitlement tier from join_date, carry-forward, shared balances |
| Leaves::DurationCalculator | Total days from day details (full/half), exclude PH and rest days |
| Leaves::WarningChecker | EL frequency check, auto-generate warning letters |
| Users::OnboardService | Create user, assign default leave policy, init balances |
| Companies::OnboardService | Create company, setup default departments/designations/policies/PH |
| Dashboard::StatsService | Aggregate KPI data for dashboards |

---

## 7. Background Jobs (Sidekiq)

| Job | Trigger | Queue |
|-----|---------|-------|
| LeaveNotificationJob | Leave applied/approved/rejected | default |
| WarningLetterJob | EL exceeds 3x/year | default |
| BalanceRecalculationJob | Year-end carry-forward, policy change | low |
| PasswordResetEmailJob | Password reset requested | high |
| AnnualBalanceResetJob | Cron: Jan 1st | low |
| CleanupExpiredTokensJob | Cron: daily | low |

---

## 8. React Frontend Architecture

### 8.1 Route Guards

- **AuthGuard** — redirects to /login if no valid token
- **RoleGuard** — checks `user.role` (ADMIN, MANAGER, EMPLOYEE); 403 if unauthorised
- **ScopeGuard** — admin portal; checks `admin_user.scope` (SUPER_ADMIN, AGENCY, COMPANY)

### 8.2 Route Map

| Path | Page | Access |
|------|------|--------|
| /login | LoginPage | Public |
| /forgot-password | ForgotPasswordPage | Public |
| /dashboard | DashboardPage | All authenticated |
| /leaves | MyLeavesPage | All authenticated |
| /leaves/apply | ApplyLeavePage | All authenticated |
| /leaves/team | TeamRequestsPage | Manager, Admin |
| /profile | ProfilePage | All authenticated |
| /admin | AdminDashboardPage | Admin scope |
| /admin/users | UserManagementPage | Admin scope |
| /admin/users/:id | UserDetailPage | Admin scope |
| /admin/companies | CompanyManagementPage | SuperAdmin, Agency |
| /admin/agencies | AgencyManagementPage | SuperAdmin only |
| /admin/policies | PolicyManagementPage | Admin scope |
| /admin/schedules | ScheduleManagementPage | Admin scope |
| /admin/holidays | HolidayManagementPage | Admin scope |
| /admin/settings | SystemSettingsPage | Admin scope |
| /admin/leaves | LeaveApplicationsPage | Admin scope |

### 8.3 State Management

**Server state (TanStack Query):** All API data. Query keys: `['leaves', 'list']`, `['admin', 'users', 'list']`, `['dashboard']`. Mutations auto-invalidate related queries. Stale time: 30s dashboards, 5min policies/holidays.

**Client state (Zustand):** Auth (user, token, scope), sidebar UI, toast notifications, leave form multi-step state, table filter persistence.

**Integration:** Axios interceptor reads JWT from Zustand auth store. 401 responses trigger refresh or redirect to login.

---

## 9. Deployment

### 9.1 Kamal (Rails API)

| Component | Container | Details |
|-----------|-----------|---------|
| Rails API | click4cuti-api | Puma, port 3000, 2+ workers |
| Sidekiq | click4cuti-sidekiq | Same image, different entrypoint |
| PostgreSQL | postgres:16 | Accessory or managed |
| Redis | redis:7-alpine | Persistent volume |
| Traefik | Built-in | Reverse proxy, auto-SSL (Let's Encrypt) |

### 9.2 Netlify (React SPA)

- Build: `npm run build`, Publish: `dist`, Node 20
- `VITE_API_URL=https://api.click4cuti.com`
- SPA fallback: `/* /index.html 200`
- Branch deploys: main → production, develop → staging

### 9.3 CORS

```ruby
origins 'https://app.click4cuti.com',
        'https://staging.click4cuti.com',
        'http://localhost:5173'
resource '/api/*',
  headers: :any,
  methods: [:get, :post, :put, :patch, :delete, :options],
  credentials: true,
  expose: ['Authorization']
```

---

## 10. Security

- Passwords: bcrypt (12 rounds) via Devise
- JWT: RS256 or HS256, 1-hour access, 7-day refresh (httpOnly, SameSite=Strict)
- Token revocation: Redis JTI denylist
- Rate limiting: 5 attempts/min/IP on auth (rack-attack)
- Password reset: single-use, 6-hour expiry
- HTTPS enforced (Traefik auto-SSL)
- CORS restricted to known origins
- File upload: type whitelist (PDF, JPG, PNG), max 10MB
- JWT in memory only (not localStorage)
- XSS: React escaping + CSP headers
- Tenant isolation: all queries scoped via company_id + Pundit policies
- Automated tests: requesting cross-tenant resource returns 404 (not 403)

---

## 11. Testing Strategy

### Rails API (RSpec)

- Model specs: validations, scopes, associations, callbacks
- Request specs: all API endpoints, auth, error responses
- Service specs: leave calculation, balance logic, warning rules
- Policy specs: Pundit for every role/scope combination
- Job/mailer specs: Sidekiq behaviour, email content
- Integration: multi-step flows (apply → approve → balance update)

### React (Vitest + Testing Library)

- Unit: utility functions, hooks, formatters
- Component: UI components in isolation
- Page: full page render with MSW mocked API
- E2E: Playwright (future) for critical user flows

### Critical Test Scenarios

- Tenant isolation: User A cannot access User B's company data
- Leave balance: apply → approve → balance decremented correctly
- Half-day calculation: mixed full/half days produce correct total
- Shared balance: EL deducts from AL pool
- Service tier: entitlement changes at 2-year and 5-year thresholds
- Warning letter: auto-generated on 4th EL in a year
- JWT lifecycle: login → access → refresh → logout → denylist
- Admin scope: agency admin cannot see other agency's companies

---

## 12. Key Dependencies

### Ruby Gems

rails 8, pg, devise, devise-jwt, pundit, paper_trail, sidekiq, redis, rack-cors, rack-attack, blueprinter, aws-sdk-s3, rspec-rails, factory_bot_rails, shoulda-matchers, faker, kamal, lograge, sentry-ruby + sentry-rails

### npm Packages

react 19, vite 6, typescript, tailwindcss 4, @shadcn/ui, @tanstack/react-query 5, zustand 5, react-router-dom 7, axios, zod, react-hook-form, date-fns, lucide-react, recharts, vitest, @testing-library/react, msw, prettier, eslint
