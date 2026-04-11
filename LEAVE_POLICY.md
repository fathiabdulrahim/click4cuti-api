# Click4Cuti — Malaysian Leave Policy Reference

Based on Employment Act 1955 (Akta Kerja 1955) — Sections 37, 60D, 60E, 60F, and Employment (Amendment) Act 2022.

---

## 1. Public Holidays (Cuti Umum)

Employers must provide **11 paid public holidays** per calendar year.

### 5 Mandatory (Wajib)

1. Hari Kebangsaan (National Day)
2. Hari Keputeraan Yang di-Pertuan Agong (King's Birthday)
3. Hari Keputeraan Raja/Yang Dipertua Negeri or Hari Wilayah Persekutuan
4. Hari Pekerja (Labour Day)
5. Hari Malaysia (Malaysia Day)

### 6 Employer's Choice (from gazetted list)

- Tahun Baru (New Year)
- Tahun Baru Cina (Chinese New Year)
- Hari Thaipusam
- Hari Wesak (Vesak Day)
- Nuzul Quran
- Hari Raya Aidilfitri
- Hari Raya Haji
- Awal Muharam
- Hari Deepavali
- Maulidur Rasul
- Hari Krismas (Christmas)

### Replacement Rules

- If a PH falls on a rest day, the next working day becomes a PH
- If that next day is also a PH, the following day becomes the replacement
- Employees working on PH are entitled to PH pay rate per Section 60D EA 1955

---

## 2. Annual Leave (Cuti Tahunan) — Section 60E

Paid annual leave entitlement by years of service:

| Years of Service | Annual Leave Days |
|-----------------|------------------|
| < 2 years | 8 days |
| 2–5 years | 12 days |
| > 5 years | 16 days |

- Companies may provide more than the statutory minimum
- Employees must apply at least 7 days in advance (or per company policy)
- Companies may allow carry-forward with configurable limits

---

## 3. Sick Leave & Hospitalisation — Section 60F

### Sick Leave Entitlement

| Years of Service | Sick Leave Days |
|-----------------|----------------|
| < 2 years | 14 days/year |
| 2–5 years | 18 days/year |
| > 5 years | 22 days/year |

### Hospitalisation Leave

- If admitted to hospital: total sick leave entitlement becomes **60 days per calendar year**
- Total sick leave + hospitalisation combined cannot exceed 60 days/year

### Conditions

- Must be examined by employer-appointed registered medical practitioner
- If unavailable, any registered practitioner within reasonable distance
- Employee must notify employer within **48 hours** of sick leave commencement
- Non-compliance = unauthorised absence → deducted from AL, then unpaid leave

---

## 4. Maternity Leave (Cuti Bersalin) — Section 37

- **60 consecutive days** from certified date of delivery
- Must provide **60-day advance notice** before expected confinement date
- Limited to first **5 living biological children** (all biological children regardless of age)
- Miscarriage/delivery before 28 weeks = regular sick leave
- Leave taken before delivery without medical certification = treated as annual leave
- Employee must have been employed within **4 months** before delivery

---

## 5. Paternity Leave (Cuti Bapa) — Employment (Amendment) Act 2022

- **7 consecutive days** per delivery of spouse (paid at normal rate)
- Limited to **5 times** regardless of number of spouses
- Requires minimum **12 months of service** before leave starts
- Must notify employer at least **30 days** before expected delivery (or as soon as possible after)

---

## 6. Emergency Leave

- Shares balance with Annual Leave (deducts from AL pool)
- Allowed **3 times per year** only
- If exceeds 3 times → automatic warning letter issued
- Supporting documents required to justify emergency leave usage
- Employee must acknowledge the warning letter

---

## 7. Special Leave (Optional — Company-Configurable)

### Marriage Leave (Cuti Kahwin)
- **1 day** for first legal marriage
- Confirmed employees only (not during probation)
- Must apply **14 days** before wedding date

### Compassionate Leave (Cuti Ehsan)
- **2 days** for death of immediate family member
- Immediate family: spouse, parents, grandparents, in-laws, siblings, children

### Disaster Leave (Cuti Malapetaka)
- **1 day** for natural disasters (flood, fire, etc.)

---

## 8. Implementation Notes for Click4Cuti

- Leave entitlement tiers stored as `default_days_tier1`, `default_days_tier2`, `default_days_tier3` in `LEAVE_TYPES`
- Tier calculation based on `users.join_date` compared to current date
- Emergency Leave linked to Annual Leave via `LEAVE_TYPES.shared_balance_with` FK
- Warning letters auto-generated via `Leaves::WarningChecker` service when EL count > 3/year
- Maternity eligibility checks: `users.gender = 'FEMALE'` and `users.number_of_children < 5`
- Public holidays per company stored in `PUBLIC_HOLIDAYS` table with `is_mandatory` flag
- State-specific PH rules determined by `companies.state` field
- Half-day leave tracked via `LEAVE_DAY_DETAILS.day_type` (FULL_DAY, HALF_DAY_AM, HALF_DAY_PM)
- Leave duration calculation excludes PH and rest days (from user's work schedule)
