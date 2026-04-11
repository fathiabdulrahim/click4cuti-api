# Click4Cuti — Product Requirements Document

**Version:** 1.0 | **Date:** April 2026 | **Status:** Draft

## 1. Introduction

### 1.1 Purpose

Click4Cuti is a multi-tenant SaaS web application for HR agencies and individual companies in Malaysia to manage employee leave digitally. Replaces manual spreadsheet-based leave tracking with centralised, EA 1955-compliant leave management.

### 1.2 Scope

- Multi-tenant platform supporting HR agencies managing multiple client companies
- Individual company onboarding without an agency
- SuperAdmin (The People Department) oversight of all tenants
- Employee self-service leave applications with manager/admin approval workflows
- Malaysian labour law compliant leave policies (EA 1955)
- Mobile-responsive web application

### 1.3 Definitions

| Term | Definition |
|------|-----------|
| EA 1955 | Employment Act 1955 (Malaysia) |
| AL | Annual Leave (Cuti Tahunan) |
| SL / MC | Sick Leave / Medical Certificate |
| EL | Emergency Leave (shares balance with AL) |
| PH | Public Holiday (Cuti Umum) |
| HOD | Head of Department |
| SuperAdmin | Platform-level administrator (The People Department) |
| Agency | HR agency managing multiple client companies |
| Tenant | A company instance within the platform |

### 1.4 Target Users

- **SuperAdmin** (The People Department) — platform-wide oversight and tenant management
- **Agency admins** — manage their portfolio of client companies
- **Company admins / Employers** — manage own company employees, policies, approvals
- **Managers / HODs** — approve team leave requests
- **Employees / Staff** — apply for leave, view balances, manage profile

---

## 2. Multi-Tenancy Model

Three-tier tenancy hierarchy:

- **SuperAdmin** — sees all agencies, companies, and users platform-wide
- **Agency level** — sees/manages only companies assigned to that agency
- **Company level** — sees only its own employees, policies, and leave data

Companies can exist independently (`agency_id` nullable) or under an agency. SuperAdmin can onboard agencies, companies, or both. Agency admins onboard companies under their agency. Company admins manage only their own tenant.

### 2.1 Access Control Matrix

| Resource | SuperAdmin | Agency | Company | Manager | Employee |
|----------|-----------|--------|---------|---------|----------|
| All agencies | CRUD | — | — | — | — |
| Companies (own agency) | CRUD | CRUD | — | — | — |
| Company (own) | CRUD | CRUD | CRUD | R | R |
| Users (own company) | CRUD | CRUD | CRUD | R (team) | — |
| Leave policies | CRUD | CRUD | CRUD | R | R |
| Leave applications | CRUD | CRUD | CRUD | Approve/Reject | Own CRUD |
| Own profile | RU | RU | RU | RU | RU |
| Activity log | R (all) | R (agency) | R (company) | — | — |

---

## 3. Functional Requirements

### 3.1 Dashboard

#### Employee Dashboard
- Leave balance cards: Annual Leave, Sick Leave, Emergency Leave (days remaining)
- Activity summary: pending requests count, approved leaves this year
- Upcoming public holidays for their company

#### Admin / Employer Dashboard
- KPI cards: total employees, pending approvals, on leave today
- Total leave pending, approved, rejected YTD
- Total leave applied by all staff YTD
- Calendar view of all leaves
- Recent activity feed

### 3.2 Leave Management

#### 3.2.1 Leave Types

**Mandatory:** Annual Leave, Medical Leave, Maternity Leave, Emergency Leave, Hospitalisation Leave, Unpaid Leave

**Special (company-configurable):** Compassionate Leave, Paternity Leave, Exam Leave, Marriage Leave, Disaster Leave, Others

#### 3.2.2 Leave Entitlement Tiers (EA 1955)

| Leave Type | < 2 years | 2–5 years | > 5 years |
|-----------|-----------|-----------|-----------|
| Annual Leave | 8 days | 12 days | 16 days |
| Sick Leave | 14 days | 18 days | 22 days |
| Hospitalisation | 60 days (incl. SL) | 60 days (incl. SL) | 60 days (incl. SL) |
| Maternity | 60 consecutive days | 60 consecutive days | 60 consecutive days |
| Paternity | 7 consecutive days | 7 consecutive days | 7 consecutive days |
| Emergency | Shares AL balance | Shares AL balance | Shares AL balance |

#### 3.2.3 Leave Application

- Select leave type from dropdown
- Choose start/end dates with per-day Full Day / Half Day AM / Half Day PM selection
- Auto-calculated total duration (0.5 day increments)
- Reason text field (mandatory)
- Extended reason field — required when exceeding max consecutive days (default 3 for AL)
- Document upload — mandatory for Medical Leave, optional for others
- Applications exceeding max consecutive days auto-flag for CEO/employer approval
- Advance notice validation: configurable (default 7 days before)

#### 3.2.4 Leave Approval Workflow

- Employer / Company Admin / SuperAdmin can approve or reject
- Rejection requires `reviewer_remarks`
- Manager/HOD can approve team requests (based on `designation.is_manager` flag)
- Statuses: PENDING, APPROVED, REJECTED, CANCELLED
- Employees can cancel own pending leaves
- Approved/rejected leaves cannot be edited

#### 3.2.5 Leave Balance Rules

- AL and EL share the same balance pool
- Balance tracks: total entitled, carried forward, used, pending, remaining
- Carry-forward with configurable limits; uncarried balance forfeited
- Balance auto-calculated based on service tenure tier
- Unusual leave (beyond entitlement) calculated and flagged

#### 3.2.6 Warning Letter Automation

- EL usage exceeding 3 times/year auto-triggers warning letter
- Warning letters require employee acknowledgement
- Supporting documents required to justify excessive EL

### 3.3 Public Holidays

- 11 paid PH per calendar year per company
- 5 mandatory: Hari Kebangsaan, Hari Keputeraan YDP Agong, Hari Keputeraan Raja/Yang Dipertua Negeri or Hari Wilayah, Hari Pekerja, Hari Malaysia
- 6 employer-chosen from gazetted list
- Replacement holiday when PH falls on rest day
- State-specific PH rules via `company.state` field
- Working on PH entitled to PH pay rate per Section 60D EA 1955

### 3.4 User Management

#### Staff Profiles
- **Personal:** email, password, full name, phone, address
- **Work:** employee ID, join date, department, designation, role, manager
- **Leave info:** total balance and taken per type, entitlement tier
- **Eligibility:** gender (maternity/paternity), number of children (maternity cap), confirmed status

#### Admin Actions
- Add user with role assignment (Admin, Manager, Employee)
- View/edit user details and role
- Reset user password
- Deactivate/reactivate user

### 3.5 Policies & Schedules

#### Leave Policies
- Named policies per company (Standard, Executive, Maternity)
- Configurable leave types with tiered entitlements
- Per leave type: max consecutive days, document requirements, half-day eligibility, carry-forward rules, max times/year, shared balance config
- Advance notice days configurable per policy
- Assigned to users via junction table with effective date ranges

#### Work Schedules
- Named schedules: Standard Office Hours, Night Shift, Day Shift, WFH
- Configurable start/end time, break time, rest days
- Assigned to users with effective date ranges

### 3.6 System Settings

- Job designations with `is_manager` flag for approval permissions
- Company profile: name, registration number, HR email, address, state

### 3.7 Maternity Leave Rules (Section 37 EA 1955)

- 60 consecutive days from certified date of delivery
- 60-day advance notice required
- Limited to first 5 living biological children
- Miscarriage/delivery before 28 weeks = regular sick leave
- Leave taken before delivery without medical certification = annual leave
- Employee must have been employed within 4 months before delivery

### 3.8 Paternity Leave Rules

- 7 consecutive days per delivery of spouse
- Limited to 5 times regardless of number of spouses
- Requires 12 months service before paternity leave starts
- Must notify employer at least 30 days before expected delivery

### 3.9 Special Leave (Optional, Company-Configurable)

- **Marriage Leave** — 1 day for first legal marriage (confirmed employees only, 14-day advance)
- **Compassionate Leave** — 2 days for death of immediate family
- **Disaster Leave** — 1 day for flood, fire, or other disasters

---

## 4. Notifications

### 4.1 Email Notifications

- Leave submitted → email to SuperAdmin + Company Admin
- Leave approved → email to applicant
- Leave rejected → email to applicant with rejection reason
- Warning letter issued → email to employee

All tracked with delivery status: PENDING, SENT, FAILED.

### 4.2 Activity Log

Polymorphic actor tracking:
- Authentication events: sign in, sign out, password reset
- Leave lifecycle: applied, approved, rejected, cancelled
- User management: created, updated, deactivated
- Company/agency onboarding
- Policy and schedule changes

Captures: actor ID, actor type (AdminUser/User), company context, IP address, timestamp.

---

## 5. Non-Functional Requirements

- **Performance:** Dashboard < 2s load. Leave submission < 1s.
- **Security:** bcrypt passwords, hashed session tokens, HTTPS, CSRF, rate limiting on auth
- **Scalability:** 100+ companies with 1000+ employees each
- **Availability:** 99.5% uptime
- **Mobile:** Responsive on all modern mobile browsers
- **Compliance:** EA 1955 compliant leave calculations
- **Audit:** All state-changing operations logged
- **Data Isolation:** Strict tenant-level — no cross-tenant leakage

---

## 6. Sprint Roadmap

| Sprint | Focus | Deliverables |
|--------|-------|-------------|
| 1–2 | Foundation | Auth (dual domain), company/agency CRUD, DB schema, sessions |
| 3–4 | Core Leave | Leave types, policies, balances, application form, half-day logic, doc upload |
| 5–6 | Approval Workflow | Manager/admin approval, rejection reasons, status transitions, CEO escalation |
| 7–8 | Compliance | EA 1955 tiers, maternity/paternity rules, PH management, warning letters |
| 9–10 | Admin Console | Dashboards, user management, policy config, work schedules, designations |
| 11–12 | Notifications & Polish | Email notifications, activity log, carry-forward, mobile responsive, UAT |
