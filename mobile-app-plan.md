# Click4Cuti Mobile App — React Native Plan

This document describes the plan for building the **Click4Cuti mobile app** in React Native, based on the design handoff bundle (`Mobile App - Tour.html`, V3 · Tour direction, extracted from the Option F landing).

The mobile app is a thin **employee + manager** client for the existing `click4cuti-api` (Rails 8 API). It does **not** cover the admin / super-admin / agency portals — those stay on the web SPA (`click4cuti-frontend`).

---

## 0. Progress at a glance — updated 2026-05-17

| Phase | Status | Notes |
|---|---|---|
| **Phase 1 — Spike** | ✅ **Done** | Expo SDK 54 + Expo Router + TS; NativeWind v4; Plus Jakarta Sans + IBM Plex Mono loaded; design tokens live; tab bar with center Apply CTA renders; `tsc --noEmit` clean; `expo-doctor` 17/17 pass. |
| **Phase 2 — Auth + read flows** | ✅ **Done** | Real `POST /auth/sign_in` with JWT-from-`Authorization` header → `expo-secure-store`. Real wiring for Home (`/dashboard`), My Leaves (`/leaves`), Leave Detail (`/leaves/:id` + `DELETE` cancel), Profile (`/profile` + `/leave_balances`), Sign out (`DELETE /auth/sign_out`). |
| **Phase 3 — Apply leave** | 🟡 **UI ready, submission pending** | `app/(employee)/apply.tsx` ships the full 3-step UI inc. half-day picker. Still need to wire `useApplyLeave()` (hook exists), public-holidays calendar marking, and document upload (blocked by G6). |
| **Phase 4 — Manager flow** | 🟡 **~90%** | `useTeamRequests()` + `useDecideTeamRequest()` mutations live; `approvals/[id].tsx` renders real data and submits approve/reject via `PUT /team_requests/:id`. Coverage strip is a stub awaiting G4. |
| **Phase 5 — Team + push** | ⬜ Blocked | Team calendar stub in place; needs G3 endpoint. Push notifications need G1/G2 on the API side. |
| **Phase 6 — Store release** | ⬜ Not started | EAS config not yet authored. |

**Built today, lives at `../click4cuti-mobile/`:**

```
app/_layout.tsx                    Root QueryClient + auth gating + font load
app/(auth)/sign-in.tsx             01 Sign in — POST /auth/sign_in
app/(employee)/home.tsx            02 Home — GET /dashboard
app/(employee)/apply.tsx           03 Apply leave — UI stub w/ half-day picker
app/(employee)/leaves/index.tsx    04 My leaves — GET /leaves
app/(employee)/leaves/[id].tsx     Leave detail — GET + DELETE
app/(employee)/team.tsx            07 Team calendar — visual stub
app/(employee)/me.tsx              08 Profile — GET /profile + balances
app/(manager)/approvals/index.tsx  Manager inbox — GET /team_requests
app/(manager)/approvals/[id].tsx   06 Approve — PUT /team_requests/:id

src/api/         Copied verbatim from click4cuti-frontend
src/lib/types.ts (518 lines, copied verbatim)
src/stores/authStore.ts           Web store body + SecureStore adapter
src/components/                    Eyebrow, Headline, StatusPill, BalanceCard,
                                   TabBar, LeaveCard, Avatar
src/hooks/                         useProfile, useDashboard, useLeaves,
                                   useLeaveBalances, usePublicHolidays,
                                   useTeamRequests
```

**Outstanding screens:** OOO success (`05`) — not yet stubbed; lives as a follow-up to Apply submission in Phase 3.

**Next concrete step:** wire `useApplyLeave()` in `app/(employee)/apply.tsx` so submission works against the API. Everything else is either complete or blocked by an API gap.

---

## 1. Scope (what we're building)

Eight screens, grouped into four flows, as defined by the design tour:

| # | Screen           | Flow         | Role          |
|---|------------------|--------------|---------------|
| 01 | Sign in         | Onboarding   | All users     |
| 02 | Home            | Employee     | employee/manager |
| 03 | Apply leave     | Employee     | employee/manager |
| 04 | My leaves       | Employee     | employee/manager |
| 05 | Out of office   | Employee     | employee/manager |
| 06 | Approve request | Manager      | manager        |
| 07 | Team calendar   | Manager      | manager        |
| 08 | Profile         | Account      | All users     |

Out of scope for v1: Discuss/chat, AI suggestions banner, Slack/Calendar/Email auto-integrations on the OOO screen (we'll render them as static "set up" checklist items for now and wire them in v2).

---

## 2. Design DNA (lift verbatim from `js/mobile-v3.jsx`)

These tokens come straight from the prototype's `Fm` palette + `fmono` font. Recreate them in a `theme.ts`:

```ts
export const colors = {
  orange:     '#FE4E01',
  orangeDeep: '#E54400',
  orangeSoft: '#FFE4D3',
  orangeTint: '#FFF5EE',
  ink:        '#0F0D0B',
  inkSoft:    '#574F47',
  inkFaint:   '#928A82',
  paper:      '#F8F5F0',
  paperDeep:  '#EFE9E0',
  white:      '#FFFFFF',
  rule:       'rgba(15,13,11,0.09)',
  ruleStrong: 'rgba(15,13,11,0.18)',
  good:       '#2D7F4E',
  goodTint:   '#E4F1E9',
  warn:       '#C9A227',
  rose:       '#B91C1C',
};

export const fonts = {
  sans: 'PlusJakartaSans',           // 300/400/500/600/700/800
  mono: 'IBMPlexMono',               // 400/500/600/700 — used as monospaced eyebrows
};
```

Visual signatures to preserve pixel-accurately:

- Cream paper background (`#F8F5F0`).
- Big orange feature card on Home (`balance` card) with white progress fill.
- IBM Plex Mono "eyebrows" — 10.5px, 700, `0.14em` letter-spacing, uppercase.
- Big tight headlines (`fontWeight: 800`, `-0.025em` to `-0.035em` letter-spacing).
- Black `Continue →` CTAs (radius 14, h 52–54).
- Status chip — mono 9px, 700, palette switches by status (pending = orange-on-tint, approved = green-on-tint, rejected = red-on-tint).
- Tab bar — 5 slots, center "Apply" is an elevated orange square (44×44, radius 14, shadow), other icons inactive `#9A8F82`, active `orange`.
- Animated check ring on OOO screen (`fmCheck` + `fmRing` keyframes → use `Animated` / `react-native-reanimated`).

---

## 3. Tech stack

The guiding principle: **share, don't fork.** `click4cuti-frontend` already runs on TanStack Query + Zustand + Axios + react-hook-form + zod + date-fns. All five are rendering-agnostic and work identically in React Native — we copy those layers verbatim and only diverge at the JSX/styling boundary. See §3a for the exact copy-vs-rewrite map.

| Concern | Choice | Why |
|---|---|---|
| Framework | **React Native via Expo (managed)** | Single codebase iOS + Android; OTA updates via EAS; matches "MVP" speed |
| Language | TypeScript (strict) | Matches `click4cuti-frontend` |
| Navigation | **Expo Router** (file-based) | Modern, type-safe, RN-native — replaces `react-router-dom` |
| Data | **TanStack Query v5** + Axios | **Same as web.** Same `QueryClient`, same hooks, same query keys (`['dashboard']`, `['leaves', 'list']`). |
| Auth state | **Zustand** + `expo-secure-store` (via `createJSONStorage` adapter) | Same store as web; only the persist `storage:` line changes so the JWT lives in iOS Keychain / Android EncryptedSharedPreferences instead of localStorage |
| Forms | **react-hook-form** + zod | Same as web — bind to RN `TextInput` instead of `<input>` |
| Styling | **NativeWind v4** | Same Tailwind classes as the web app; design tokens (`colors.orange`, etc.) map straight into `tailwind.config.js`. Picked over Restyle because the existing FE team already writes Tailwind. |
| Dates | **date-fns** | Same version as web |
| Calendar | **react-native-calendars** (Wix) | Replaces `react-day-picker` — customisable enough to match the Apply-leave grid |
| Animations | **react-native-reanimated v3** | For OOO success ring + tab transitions |
| Icons | **lucide-react-native** | Same icon names as web `lucide-react` |
| Push notifications | **expo-notifications** | For leave approval/rejection alerts |
| Network status | `@react-native-community/netinfo` | Wired into Query's `onlineManager` |
| Sentry | `@sentry/react-native` | Parity with API monitoring |
| Build/Release | **EAS Build + EAS Submit** | App Store + Play Store from CI |
| Lint/Format | ESLint + Prettier (copy config from web) | |
| Testing | Jest + React Native Testing Library | |

**Why Expo and not bare RN?** No native modules are required for v1 (push, secure storage, calendar UI are all in the Expo SDK). If/when we need Slack/Calendar deep integrations we can prebuild without changing the codebase.

## 3a. Share-don't-fork — what copies, what adapts, what rewrites

The codebase splits cleanly into three layers. Treat them differently:

### Copy verbatim from `click4cuti-frontend`

These files are pure logic / pure HTTP and have **zero web-only dependencies**. Copy them across with no changes:

| Web path | Mobile path | Notes |
|---|---|---|
| `src/api/axios.ts` | `src/api/axios.ts` | Only the `baseURL` source changes (env var name) |
| `src/api/auth.ts` | `src/api/auth.ts` | `authApi.login()`, `authApi.logout()`, etc. |
| `src/api/profile.ts` | `src/api/profile.ts` | |
| `src/api/dashboard.ts` | `src/api/dashboard.ts` | |
| `src/api/leaves.ts` | `src/api/leaves.ts` | `ApplyLeavePayload` interface, all CRUD |
| `src/api/leaveBalances.ts` | `src/api/leaveBalances.ts` | |
| `src/api/publicHolidays.ts` | `src/api/publicHolidays.ts` | |
| `src/api/teamRequests.ts` | `src/api/teamRequests.ts` | |
| `src/lib/types.ts` | `src/lib/types.ts` | Shared User / LeaveApplication / etc. types |
| zod schemas under `src/schemas/` | `src/schemas/` | Form validation rules are identical |
| ESLint + Prettier config | `.eslintrc`, `.prettierrc` | |

If the FE team updates one of these, the mobile app updates too. We may eventually extract them into an `@click4cuti/shared` workspace package — out of scope for v1.

### Adapt (same library, swap one line)

`zustand`'s `persist` middleware needs a different storage backend. Everything else in the store body is identical:

```ts
// click4cuti-mobile/src/stores/authStore.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import * as SecureStore from 'expo-secure-store'
import type { User, AdminUser } from '@/lib/types'

const secureStorage = {
  getItem: (key: string) => SecureStore.getItemAsync(key),
  setItem: (key: string, value: string) => SecureStore.setItemAsync(key, value),
  removeItem: (key: string) => SecureStore.deleteItemAsync(key),
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      user: null,
      adminUser: null,
      isAuthenticated: false,
      setAuth: (token, user) =>
        set({ accessToken: token, user, adminUser: null, isAuthenticated: true }),
      setAdminAuth: (token, adminUser) =>
        set({ accessToken: token, adminUser, user: null, isAuthenticated: true }),
      clearAuth: () =>
        set({ accessToken: null, user: null, adminUser: null, isAuthenticated: false }),
    }),
    {
      name: 'click4cuti-auth',
      storage: createJSONStorage(() => secureStorage), // ← only line that changes
      partialize: (s) => ({
        accessToken: s.accessToken,
        user: s.user,
        adminUser: s.adminUser,
        isAuthenticated: s.isAuthenticated,
      }),
    },
  ),
)
```

Compare against `click4cuti-frontend/src/stores/authStore.ts` — body is line-for-line identical apart from the `storage:` adapter. Token now lives in Keychain / EncryptedSharedPreferences instead of localStorage — strictly an upgrade.

The axios interceptor is also a one-line tweak — same file, same shape, just reads `useAuthStore.getState().accessToken` (same as web) and on 401 routes to the Expo Router `(auth)/sign-in` path instead of `window.location.href`.

React Query needs two small wires to play nicely with the RN lifecycle. Add to the root layout:

```ts
// app/_layout.tsx
import { focusManager, onlineManager, QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AppState } from 'react-native'
import NetInfo from '@react-native-community/netinfo'

onlineManager.setEventListener((setOnline) =>
  NetInfo.addEventListener((s) => setOnline(!!s.isConnected)),
)
AppState.addEventListener('change', (status) => focusManager.setFocused(status === 'active'))

const queryClient = new QueryClient({ /* same defaults as web */ })
```

The `QueryClient` config, every `useQuery`/`useMutation` hook, every query key — unchanged.

### Rewrite (web-only, no RN equivalent)

These don't survive the platform jump and need real replacements:

| Web | Mobile replacement | Notes |
|---|---|---|
| `react-router-dom` | `expo-router` | File-based; same mental model |
| `react-day-picker` | `react-native-calendars` | Used on the Apply screen |
| `lucide-react` | `lucide-react-native` | Same icon names — find/replace import |
| `@radix-ui/*` + `shadcn/ui` | Hand-rolled primitives | We need ~6 primitives (Button, Sheet, Pill, Card, Input, BottomSheet). Faster to build them against our design tokens than to wrestle Tamagui/Gluestack into the design DNA. |
| Tailwind via `@tailwindcss/vite` | **NativeWind v4** | Same `className="..."` syntax; design tokens go into `tailwind.config.js` |
| `recharts` | n/a in v1 | No charts in the 8 screens |
| All JSX (`<div>`, `<button>`, etc.) | RN primitives (`View`, `Text`, `Pressable`) | Per-screen rewrite — but the data hooks they call are the same |

### Net result

Of the ~30 files in `click4cuti-frontend/src/`, roughly **20 copy verbatim**, **3–4 adapt**, and **6–8 rewrite** (mostly the page components themselves). The mobile app shares the API contract, the type definitions, and the data-fetching layer with the web app — divergence is only at the rendering layer, where it has to be.

---

## 4. Project structure

```
click4cuti-mobile/
├── app/                              # Expo Router file-based routes
│   ├── (auth)/
│   │   └── sign-in.tsx              # 01 · Sign in
│   ├── (employee)/                   # Tab group — role: employee or manager
│   │   ├── _layout.tsx              # TabBar (Home · Leaves · [Apply] · Team · Me)
│   │   ├── home.tsx                 # 02 · Home
│   │   ├── leaves/
│   │   │   ├── index.tsx            # 04 · My leaves
│   │   │   └── [id].tsx             # Leave detail (drill-in from list)
│   │   ├── apply.tsx                # 03 · Apply leave (modal-ish, 3-step wizard)
│   │   ├── apply-success.tsx        # 05 · Out of office (success state after Apply)
│   │   ├── team.tsx                 # 07 · Team calendar
│   │   └── me.tsx                   # 08 · Profile
│   ├── (manager)/                    # Gated by role
│   │   └── approvals/
│   │       ├── index.tsx            # Team requests list (drill-in)
│   │       └── [id].tsx             # 06 · Approve request
│   └── _layout.tsx                   # Root provider (QueryClient, theme, auth)
│
├── src/
│   ├── api/                          # COPY VERBATIM from click4cuti-frontend/src/api/*
│   │   ├── axios.ts                 # Same interceptor; reads token from Zustand (same as web)
│   │   ├── auth.ts                  # authApi.login(), .logout(), .forgotPassword() — unchanged
│   │   ├── profile.ts               # unchanged
│   │   ├── dashboard.ts             # unchanged
│   │   ├── leaves.ts                # unchanged
│   │   ├── leaveBalances.ts         # unchanged
│   │   ├── publicHolidays.ts        # unchanged
│   │   └── teamRequests.ts          # unchanged
│   ├── components/                   # Reusable design-system primitives
│   │   ├── Eyebrow.tsx              # FmEyebrow
│   │   ├── Headline.tsx             # FmHeadline
│   │   ├── StatusPill.tsx           # FmStatus (pending/approved/rejected)
│   │   ├── BalanceCard.tsx          # Orange hero card
│   │   ├── TabBar.tsx               # Custom tab bar with center "Apply" CTA
│   │   ├── Calendar.tsx             # Wraps react-native-calendars w/ our tokens
│   │   ├── LeaveCard.tsx            # Used in My Leaves + Team Requests
│   │   └── TeamRow.tsx              # Used in Team Calendar
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useDashboard.ts          # → GET /dashboard
│   │   ├── useLeaves.ts             # → /leaves
│   │   ├── useLeaveBalances.ts      # → /leave_balances
│   │   ├── usePublicHolidays.ts     # → /public_holidays
│   │   ├── useTeamRequests.ts       # → /team_requests (manager only)
│   │   └── useWorkingDays.ts        # Client-side calc using PHs + start/end
│   ├── lib/
│   │   ├── theme.ts                 # Tokens above (also wired into tailwind.config.js for NativeWind)
│   │   ├── types.ts                 # COPY VERBATIM from click4cuti-frontend/src/lib/types.ts
│   │   ├── workingDays.ts           # Mirror of Leaves::DurationCalculator
│   │   └── format.ts                # date-fns helpers (eyebrow date "TUE · 5 MAY 2026")
│   ├── schemas/                      # COPY VERBATIM from click4cuti-frontend/src/schemas/* (zod)
│   ├── stores/
│   │   └── authStore.ts             # Same body as web; persist storage swapped to expo-secure-store (see §3a)
│   └── env.ts                        # API_URL etc.
│
├── assets/
│   ├── logo-icon.svg                # Lifted from design bundle
│   └── fonts/                       # PlusJakartaSans, IBMPlexMono
│
├── app.config.ts                     # Expo config (scheme: click4cuti)
├── eas.json
├── tsconfig.json
└── package.json
```

---

## 5. Auth model

The API uses **devise-jwt** with a 24h expiry. The token is returned in the `Authorization` response header on `POST /api/v1/auth/sign_in`, and the `JwtDenylist` model revokes via `DELETE /api/v1/auth/sign_out`.

**Mobile auth flow:**

1. User submits email + password on `app/(auth)/sign-in.tsx`.
2. Call `authApi.login(email, password)` — **identical** to the web call (`POST /api/v1/auth/sign_in` with `{ user: { email, password } }`).
3. Read `Authorization` response header (it's in the CORS `expose` list — `config/initializers/cors.rb:expose: %w[Authorization]`). Strip the `Bearer ` prefix.
4. `useAuthStore.setAuth(token, user)` — same store API as web; persistence transparently routes through `expo-secure-store` (Keychain on iOS, EncryptedSharedPreferences on Android). **Never AsyncStorage** — tokens are credentials.
5. On every request, the (copied-verbatim) axios interceptor pulls token from `useAuthStore.getState().accessToken` and sets `Authorization: Bearer <token>`.
6. On 401 from API → `useAuthStore.getState().clearAuth()` (same as web), then `router.replace('/(auth)/sign-in')` instead of `window.location.href`.
7. Sign-out: `authApi.logout()` (server adds JTI to denylist), then `clearAuth()`.

**Refresh:** the API currently issues a 24h JWT with **no refresh token**. The web frontend reuses the same token until 401. We mirror that for v1 — re-login on expiry. (If/when the API adds refresh tokens, we add a `/auth/refresh` call to the axios response interceptor.)

**`AdminUser` is excluded.** The mobile app authenticates only against the **`User`** Devise scope (employees + managers + company admins). Platform-level admins continue to use the web admin portal.

---

## 6. Screen-by-screen API mapping

For each screen: which endpoints are called, what payload, what the response gives us, and any gaps to fill on the API side.

### 01 · Sign in (`app/(auth)/sign-in.tsx`)

| What | API | Notes |
|---|---|---|
| Submit credentials | `POST /api/v1/auth/sign_in` | Body: `{ user: { email, password } }`. Response sets `Authorization` header. |
| (Future) Forgot password | `POST /api/v1/auth/password` | Body: `{ user: { email } }`. The `FORGOT?` link in the design points here. |

After login → route to `(employee)/home`.

### 02 · Home (`app/(employee)/home.tsx`)

The orange balance hero, the "Apply for leave" CTA card, the "This month" indicator list, and the "Next festival" strip all hydrate from **one endpoint**:

| What | API | Notes |
|---|---|---|
| Greeting name + initials + role | `GET /api/v1/profile` | First-load only, cached. |
| Balance hero (`14 / 21 days`, "7 used so far") | `GET /api/v1/dashboard` | Returns `leave_balances[]` (one per type) with `total_entitled / used_days / remaining_days / pending_days`. We pick the **Annual** balance for the hero — Emergency shares pool so we surface AL specifically. |
| Pending approvals count (only for managers) | `GET /api/v1/dashboard` | `pending_requests` already in the payload. |
| Team-on-leave count (this month) | **GAP — see §9** | Currently `dashboard` doesn't expose this. Either extend `Dashboard::StatsService` or call `GET /api/v1/team_requests` (manager) / a new `/team_calendar` endpoint. |
| Your requests count | `GET /api/v1/dashboard` | Derive from `recent_applications` length or extend stats. |
| Next festival ("Hari Raya · in 3 days") | `GET /api/v1/dashboard` | `upcoming_holidays[]` (top 5, server-sorted). Take `[0]`. |

`useDashboard` query key: `['dashboard']`.

### 03 · Apply leave (`app/(employee)/apply.tsx`) — 3-step wizard

The design shows step 1/3 ("When?"). The full wizard:

- **Step 1 — When?** Pick start + end dates on calendar; pick `Annual / Sick / Emergency / Unpaid`; see auto-computed working days.
- **Step 2 — Why?** Reason textarea; extended_reason if >3 days for AL (per `CLAUDE.md` rule 8); optional document upload (mandatory for Medical, per rule 9).
- **Step 3 — Confirm.** Review + submit.

| What | API | Notes |
|---|---|---|
| Public holidays to ring-highlight on the calendar (8 & 11 May in design) | `GET /api/v1/public_holidays?year=2026` | Returns `[{ name, holiday_date, year, ... }]`. Cache for the whole year. |
| Leave types + remaining balance for the chips (`Annual · 14 left`, `Sick · 7 left`, etc.) | `GET /api/v1/leave_balances?year=2026` | Returns per-type balance with `leave_type` association. |
| Working-days auto-math ("5 working days, we've excluded the PH and weekends") | **Client-side**, using `src/lib/workingDays.ts` | Mirror `Leaves::DurationCalculator`: skip weekends and any date in the cached PH set. Server re-computes on submit, so this is just preview. |
| Submit application | `POST /api/v1/leaves` | Body: `{ leave: { leave_type_id, start_date, end_date, reason, extended_reason?, leave_day_details_attributes?: [{leave_date, day_type}] } }`. 422 with `{ error: "..." }` on validation failure (insufficient balance, max consecutive days, etc.). |
| Document upload (Medical only) | **GAP** — `POST /api/v1/leaves` currently doesn't accept attachments | Either accept `multipart/form-data` with `documents[]`, or add `POST /api/v1/leaves/:id/documents` after creation. See §9. |
| Document upload (Medical, fallback) | `POST /api/v1/user_documents` | Exists today as a generic document store; we can attach `linkable: leave_application`. |

`useApplyLeave` mutation invalidates `['dashboard']`, `['leaves']`, `['leave_balances']`.

### 04 · My leaves (`app/(employee)/leaves/index.tsx`)

| What | API | Notes |
|---|---|---|
| Stats row (`7 USED · 5 PENDING · 14 LEFT`) | `GET /api/v1/leave_balances` | Aggregate Annual balance — or just read from `useDashboard` if already cached. |
| Filter chips (All / Pending / Approved / Rejected) | Client-side filter on `useLeaves()` data | Status is in the blueprint as `"PENDING"` / `"APPROVED"` / `"REJECTED"`. |
| List (5 cards, status pill, ID `L-0427`) | `GET /api/v1/leaves` | Returns `LeaveApplicationBlueprint` default view. `id` shown in design is the short L-XXXX — we'll generate from `id.slice(0,8)` or add a `short_code` on the API. See §9. |
| Tap card → detail | `GET /api/v1/leaves/:id` | Returns `:detail` view (`reason`, `extended_reason`, `reviewer_remarks`, `approver`, `leave_day_details`). |
| Cancel a pending leave (long-press / detail action) | `DELETE /api/v1/leaves/:id` | Server sets `status: cancelled`. |

`useLeaves` query key: `['leaves', 'list']`.

### 05 · Out of office (`app/(employee)/apply-success.tsx`)

This screen is the **success state after Apply Leave is approved AND the leave start date has arrived** — note "FRI · 8 MAY · 5:58 PM" + "L-0427" in the design. Two ways to reach it:

1. **Confirmation flash** — right after `POST /api/v1/leaves` succeeds, show a simpler "Request sent" variant.
2. **Real OOO** — leave is approved + today is between `start_date` and `end_date`. Show on first app open during that window.

| What | API | Notes |
|---|---|---|
| Leave reference + dates | `GET /api/v1/leaves/:id` | Detail view. |
| Auto-handled checklist (Email / Slack / Calendar / Team notified) | **v1 = static UI; v2 = real integrations** | Render the four rows from a constant. Document this in the PR — these are aspirational items and clicking them does nothing in v1. |

### 06 · Approve request (`app/(manager)/approvals/[id].tsx`)

The manager flow. Only rendered if `currentUser.role === 'manager'` (or admin).

| What | API | Notes |
|---|---|---|
| Inbox of pending requests (entry point from Home "Pending approvals · 1") | `GET /api/v1/team_requests` | Returns all `pending` leaves the current manager can act on, with `:detail` view (`user`, `leave_type`, `reason`, etc.). |
| Single request card (name, role, dates, balance after, note) | `GET /api/v1/team_requests` element, or `GET /api/v1/leaves/:id` if accessed via deeplink | Blueprint includes `user.full_name`, `leave_type.name`, `total_days`, `reason`. Role/team comes from `user.department` — verify the User blueprint exposes it; see §9. |
| Team coverage strip (5 daily bars + "No conflicts · 4 others in office") | **GAP** | No endpoint today. Need a `GET /api/v1/team_requests/:id/coverage` returning per-day in/out counts for the requested range. See §9. |
| Approve | `PUT /api/v1/team_requests/:id` | Body: `{ leave: { status: 'approved', reviewer_remarks } }`. Server runs `Leaves::ApprovalService`. |
| Reject / "Discuss" | `PUT /api/v1/team_requests/:id` | Body: `{ leave: { status: 'rejected', reviewer_remarks } }`. "Discuss" in v1 = open the reject sheet with remarks (no chat). |
| AI suggestion ("Last 3 Hari Raya requests were all approved") | **v2** — not in v1 | |

Invalidates `['team_requests']`, `['dashboard']` (pending count).

### 07 · Team calendar (`app/(employee)/team.tsx`)

Visible to all users (employees see who's out, managers see same view plus quick-approve).

| What | API | Notes |
|---|---|---|
| Today summary (`1 out · 22 in · Prakash K. · Medical leave`) | **GAP** | Needs an endpoint that returns "approved leaves overlapping today" company-wide. See §9 (`GET /api/v1/team_calendar?date=today`). |
| Upcoming entries list (`Aisyah · Hari Raya · 8 – 12 May`, etc.) | **GAP** | Same endpoint, `?from=today&to=today+30d`. Could also be `GET /api/v1/leaves?scope=company&status=approved&from=...`. |
| Filter chips (Everyone / Support / Eng / Design / PM) | Client-side filter on department | Department comes from `user.department.name`. |
| Search icon (top right) | Client-side name search | |
| Month switcher (`M` badge) | Local state | |

### 08 · Profile (`app/(employee)/me.tsx`)

| What | API | Notes |
|---|---|---|
| Hero (avatar initials, name, role, "JOINED MAR 2023 · 3.2 YRS") | `GET /api/v1/profile` | UserBlueprint `:detail` already exposes `full_name`, `role`, `joined_date`, plus the new `leave_supervisor_l1/l2` fields from commit 5cc2789. We compute years-of-service client-side. |
| 2026 at-a-glance bars (`7 ANNUAL · 5 PENDING · 1 MEDICAL`) | `GET /api/v1/leave_balances?year=2026` | Aggregate `used_days` and `pending_days` across types. |
| "Leave types & balances" row | `GET /api/v1/leave_balances` | Drill-in screen lists each leave type with `remaining_days / total_entitled`. |
| "Manager" row (`Hazmi Rahman`) | `GET /api/v1/profile` | `leave_supervisor_l1.full_name`. |
| "Public holidays · Malaysia · KL" row | `GET /api/v1/public_holidays?year=2026` | Drill-in is a list. |
| "Auto-reply templates · 3 saved" | **v2** | Render but disabled. |
| "Notifications · Push / Email / WhatsApp" | `GET / PATCH /api/v1/app_settings` | The `AppSettings` resource exists. Verify the schema has notification toggles; if not, add them. |
| "Privacy & data" / "Help & support" | Static screens | |
| Edit profile | `PATCH /api/v1/profile` | Body permits `full_name, phone, address, nric, ...` (see `profiles_controller.rb:23`). |
| Sign out | `DELETE /api/v1/auth/sign_out` | Clear SecureStore + redirect to `(auth)/sign-in`. |

---

## 7. Cross-cutting concerns

### Tenant isolation
Already enforced on the API side (`set_tenant_scope` + Pundit). The mobile client doesn't need to send `company_id` — it's derived from `current_user`.

### Role-based routing
At root layout:
```ts
if (user.role === 'manager' || user.role === 'admin') {
  // mount (manager) group → "Approve" entry on Home + access to /approvals
}
```
Don't conditionally hide the tab bar — keep 5 tabs for everyone; "Pending approvals" row on Home is the manager hook.

### Push notifications
- Register device with `expo-notifications.getExpoPushTokenAsync()` after sign-in.
- `POST /api/v1/profile` with `expo_push_token` field — **need to add this column to `users`** (see §9).
- API-side: when `Leaves::ApprovalService` runs, the existing `LeaveNotificationJob` should also push to the user's `expo_push_token`. Tactically: add an Expo Push HTTP call in the job alongside the existing email/in-app notification.

### Offline support (v1: minimal)
TanStack Query's default cache covers re-opens. We don't queue write actions offline in v1 — show a "no connection" toast and block mutations.

### Date formatting
- Eyebrow: `format(date, 'EEE · d MMM yyyy').toUpperCase()` → `"TUE · 5 MAY 2026"`.
- Card date column: split into "MAY" / "8" / "·5D" using same date-fns.

### Working-days calculator (client-side preview)
Mirror `Leaves::DurationCalculator`:
```ts
function workingDays(start: Date, end: Date, holidays: Set<string>, weekend = [0, 6]) {
  let count = 0;
  for (const d of eachDayOfInterval({ start, end })) {
    if (weekend.includes(d.getDay())) continue;
    if (holidays.has(format(d, 'yyyy-MM-dd'))) continue;
    count++;
  }
  return count;
}
```
We deliberately re-implement (not call the API) so the count updates as the user drags the date range. Server is the source of truth on submit.

---

## 8. Phasing / delivery order

**Phase 1 — Spike (1 sprint). ✅ Done.** Expo app boots, design tokens in place, navigation skeleton, fonts loaded, screens stubbed. Lives in `../click4cuti-mobile/`.

**Phase 2 — Auth + read flows (1 sprint). ✅ Done.**
- ✅ Screen 01 (Sign in) → real `POST /auth/sign_in`, JWT into SecureStore.
- ✅ Screen 02 (Home) → `GET /dashboard`.
- ✅ Screen 08 (Profile read-only) → `GET /profile`, `GET /leave_balances`.
- ✅ Screen 04 (My leaves) → `GET /leaves`, plus drill-in detail + cancel.

**Phase 3 — Apply leave (1 sprint). 🟡 In flight.**
- 🟡 Screen 03 — UI built incl. half-day picker; `useApplyLeave()` hook ready; still need to bind the form to `POST /leaves`.
- ⬜ Pull `GET /public_holidays` into the calendar to ring-highlight holidays.
- ⬜ Mirror server-side working-days math client-side (`src/lib/workingDays.ts` exists; just needs to be wired to the picker).
- ⬜ Screen 05 (Out of office success).
- ⬜ Medical leave document upload — blocked by API gap G6.

**Phase 4 — Manager flow (1 sprint). 🟡 ~90%.**
- ✅ Inbox via `GET /team_requests` and approve/reject via `PUT /team_requests/:id`.
- ⬜ Pending-approvals entry on Home (count is in `/dashboard` already; needs the row to deeplink to `/approvals`).
- ⬜ Team coverage strip — blocked by API gap G4.

**Phase 5 — Team + polish (1 sprint). ⬜ Blocked.**
- ⬜ Screen 07 (Team calendar) — depends on new `/team_calendar` endpoint (API gap G3).
- ⬜ Push notifications wired end-to-end — depends on G1 (`expo_push_token` column) + G2 (Expo Push from `LeaveNotificationJob`).
- ⬜ Sentry + crash reporting.
- ⬜ TestFlight + Play Internal Testing.

**Phase 6 — Store release. ⬜ Not started.** EAS Submit to App Store + Play Store.

---

## 9. API gaps (work the Rails side needs to do)

Tracking everything the mobile app needs that the API doesn't expose today. These should land as separate PRs on `click4cuti-api` **before** the corresponding mobile phase.

| # | Gap | Where | Phase blocked |
|---|---|---|---|
| G1 | Expose `expo_push_token` on `users` | Migration + `profile_params` whitelist in `app/controllers/api/v1/profiles_controller.rb` | Phase 5 |
| G2 | Send Expo push from `LeaveNotificationJob` | `app/jobs/leave_notification_job.rb` | Phase 5 |
| G3 | New `GET /api/v1/team_calendar?from=&to=` returning approved leaves in the window for the current company, plus today's in/out counts | New controller + service | Phase 5 |
| G4 | New `GET /api/v1/team_requests/:id/coverage` returning per-day staffing for the request range | Controller action + service | Phase 4 |
| G5 | Dashboard stats — add `team_on_leave_this_month` and `your_requests_this_year` to `Dashboard::StatsService` | `app/services/dashboard/stats_service.rb` | Phase 2 (nice-to-have, can derive client-side until then) |
| G6 | Document upload on Leave application — accept `multipart` with `documents[]`, or keep `POST /user_documents` with `linkable_type=LeaveApplication, linkable_id` | `LeavesController#create` or `UserDocumentsController` | Phase 3 |
| G7 | Short reference code (`L-0427`) on `LeaveApplication` — add `short_code` column auto-generated on create, expose in blueprint | Migration + model | Phase 2 (cosmetic — can derive from UUID until then) |
| G8 | Verify `UserBlueprint` exposes `department.name` and `leave_supervisor_l1.full_name` in the default view | `app/serializers/user_blueprint.rb` | Phase 2 |
| G9 | Notification toggles on `AppSettings` (`push_enabled`, `email_enabled`, `whatsapp_enabled`) | Migration + permitted params | Phase 5 |

---

## 10. Open questions for the user

1. **Manager-only "Approve" entry** — should non-managers see the "Pending approvals" row on Home at all, or hide it entirely?
2. **Reject UX** — does "Discuss" need to be a real chat, or is it fine to map it to "Reject with remarks" in v1?
3. **OOO success screen** — should we show the animated checkmark every time a user opens the app during their leave, or only once at submission time?
4. **Auto-reply / Slack integration** — confirm we're shipping these as static placeholders in v1.
5. ~~**Half-day leaves**~~ — **Resolved 2026-05-17: include in step 1.** UI is in place at `app/(employee)/apply.tsx`; binds to `leave_day_details_attributes` when submission is wired.
6. **Multi-language** — Malay + English? The chats are in English; the LEAVE_POLICY.md is bilingual.
7. **iOS-only first, or both stores at launch?** Affects EAS provisioning timeline.

---

## 11. References

- Design source: `Mobile App - Tour.html` + `js/mobile-v3.jsx` (design handoff bundle).
- API surface: `config/routes.rb` lines 21–34 (employee-facing v1 routes).
- Existing web client patterns to mirror: `../click4cuti-frontend/src/api/*.ts`, `../click4cuti-frontend/src/stores/authStore.ts`.
- Business rules: `CLAUDE.md` § Critical Business Rules — these are server-enforced; the mobile UI just surfaces validation errors.
- Auth: `config/initializers/devise.rb` (JWT, 24h expiry, denylist revocation).
