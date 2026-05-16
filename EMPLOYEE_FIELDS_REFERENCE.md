# Employee Fields Reference — MySyarikat HRMS

Source: `https://manage.mysyarikat.com/employees/25429`
Captured: 2026-05-16
Sample employee: Nur Fatin Najihah Abd Aziz (2203007), Trainee Fullstack Developer

This document lists all fields available on each tab of the employee detail page, captured for reference when designing Click4Cuti's employee data model.

---

## Header / Summary Section

Displayed above the tabs, summarising the employee:

- Profile photo
- Full Name
- Employee No.
- Designation
- Phone Number
- Email
- User Role (Employee / Manager / Admin)
- Department
- Employee Status (Employed / etc.)

Actions on header:
- Print Record (dropdown: Print PDF (Malay) / Print PDF (English))
- Reset Password
- Change Employee Status

---

## Tabs

The employee detail page contains 13 tabs:

1. Personal Detail
2. Employment
3. Contact
4. Family Detail
5. Compensation
6. Document
7. Career Progress
8. Training & Certificate
9. Equipment
10. Leave Policy
11. Claim Policy
12. Disciplinary
13. App Setting

---

## 1. Personal Detail

### Personal Details (section)
| Field | Type | Options / Notes |
|---|---|---|
| First Name | text | required |
| Last Name | text | required |
| NRIC | text | required |
| Date of Birth | date | required |
| NRIC (Old) | text | |
| NRIC Color | select | Blue, Red |
| Place of Birth | text | |
| Gender | select | Male, Female |
| Race | select | Malay, Chinese, Indian, Others |
| Religion | select | Islam, Buddhism, Hindu, Christian, Others |
| Blood Type | select | A, B, AB, O |
| Education Level | select | Pre School, Primary School, Secondary School, College/University, Diploma, Degree, Master, PhD |
| Marital Status | select | Single, Married, Divorced, Widowed |
| Family Members | number | |
| Nationality | select | Citizen, Non Citizen, Permanent Resident |
| Bumi Status | select | Bumiputera, Non Bumiputera |

### Driving License Details (section)
| Field | Type | Options / Notes |
|---|---|---|
| Driving License Number | text | |
| License Class | select | A, A1, B, B1, B2, C, D, DA, E, E1, E2, F, G, H, I, M (Malaysian JPJ classes with descriptions) |
| License Expiry Date | date | |

### Working Experience (section, repeatable list)
"Add Work Experience" modal fields:
| Field | Type | Notes |
|---|---|---|
| Company Name | text | |
| Position | text | |
| Start Date | date | |
| End Date | date | |
| Period | text | auto-calculated |

---

## 2. Employment

### Employment Details (section)
| Field | Type | Options / Notes |
|---|---|---|
| Employee No. | text | |
| Company | text | |
| Designation | text | |
| Branch Location | text/select | |
| Date Joining | date | |
| Date of Sign (LO) | date | Letter of Offer signing date |
| Employee Type | select | Not Applicable, Permanent, Contract Basis, SL1M OJT, OJT, Part-Time Staff, Freelance, Probation, Internship |
| Probation Period Day(s) | number | |
| Department | select | Human Resource, Sales & Marketing, Technology, CEO Office (org-defined) |
| OKU Status | select | No, Yes (disabled person status) |

### Approval Details (section)
Configure employee approval. Changes affect all pending applications for this employee.

| Field | Type | Notes |
|---|---|---|
| Leave Supervisor — First Level Approval | user select | required |
| Leave Supervisor — Second Level Approval | user select | |
| Claim Supervisor — First Level Approval | user select | required |
| Claim Supervisor — Second Level Approval | user select | |
| Overtime Supervisor — First Level Approval | user select | |
| Overtime Supervisor — Second Level Approval | user select | |
| Timeoff Supervisor — First Level Approval | user select | |
| Timeoff Supervisor — Second Level Approval | user select | |

### Yearly Form (section)
| Field | Type | Notes |
|---|---|---|
| EA Person in Charge | user select | required |

### Company Access (section)
Lists companies the employee has access to, e.g. "VHA Cognitive (M) Sdn Bhd — Main Company".

---

## 3. Contact

### Contact Details (section)
| Field | Type |
|---|---|
| Phone Number | text |
| Mobile Number | text |
| Email | email |
| Personal Email | email |
| Address | textarea |
| Mailing Address | textarea |

### Emergency Contact (section)
| Field | Type |
|---|---|
| Name | text |
| Mobile Number | text |

---

## 4. Family Detail

Repeatable list. "Add Family Details" modal fields:

| Field | Type | Options / Notes |
|---|---|---|
| Relation | select | Spouse, Child, Parent (required) |
| First Name | text | required |
| Last Name | text | |
| Gender | select | required |
| NRIC/Passport | text | |
| Date of Birth | date | required |
| Phone No. | text | |
| Email | email | |
| Address | textarea | |
| Employment Status | select | required |
| OKU Status | select | required |

---

## 5. Compensation

### Bank Details (section)
| Field | Type | Options / Notes |
|---|---|---|
| Bank | select | Long list of Malaysian banks: Affin Bank, Alliance Bank, Al-Rajhi, Ambank, Bank Islam, Bank Rakyat, Bank Muamalat, Bank of America, Bank of China, BOTM UFJ, Agrobank, BSN, CIMB, Citibank, Deutsche Bank, Hong Leong, HSBC, ICBC, JPMorgan Chase, Kuwait Finance House, Maybank, Mizuho, OCBC, Public Bank, RHB, Standard Chartered, SMBC, RBS, UOB, DBS, Post Office Savings, KEB Hana, Baiduri, Bank Islam Brunei, MBSB, Merchantrade, Money Touch 'n Go, GX Bank |
| Account Number | text | |
| Account Type | select | Saving, Current, Fixed, Others |
| Branch | text | |
| Account Status | select | Active, Inactive |

### Statutory Details (section)
#### Employee Provident Fund (EPF)
| Field | Type | Options / Notes |
|---|---|---|
| EPF Number | text | |
| EPF Contribution Start Date | select | Before 1 August 1998, After 1 August 1998, After 1 August 2001 |

#### Social Security Organization (SOCSO)
| Field | Type |
|---|---|
| SOCSO Number | text |
| SOCSO Contribution Start Age | number |

#### Employment Insurance System (EIS)
| Field | Type |
|---|---|
| Employee Contribution Rate | number/percent |
| Employer Contribution Rate | number/percent |

#### Income Tax
| Field | Type |
|---|---|
| Income Tax Number | text |
| Value of Living Accommodation (VOLA) | number |

### Income Tax Details (section)
Note: data here is synced with Family Details — there is a "Sync" / "Update Family Detail" action when out of sync.

#### Children Information
| Field | Type |
|---|---|
| Employee has Child | yes/no |
| Under the age of 18 years | number |
| 18 Years & above and studying (Certificate/Matriculation) | number |
| Disabled Child | number |

#### Spouse Information
| Field | Type | Options |
|---|---|---|
| Spouse is Working | yes/no |
| Spouse is Disabled | yes/no |
| Spouse Gender | select | Male, Female |

#### Relief Information
| Field | Type | Notes |
|---|---|---|
| Contribution to SOCSO including SIP | yes/no | |
| Employee Category | select | Determine whether employee is Returning Expert Programme (REP), Knowledge Worker at Specific Region (Iskandar Malaysia) etc. |

---

## 6. Document

Repeatable list. "Document Information" / Add Document modal fields:

| Field | Type | Notes |
|---|---|---|
| File | file upload | required (Drag & Drop / Browse) |
| Remarks | textarea | required |

Has a search field for filtering existing documents.

---

## 7. Career Progress

Title: "Career Progress Records" with company grouping (e.g. "VHA Cognitive (M) Sdn Bhd"). Repeatable list.

"Add Career Progress" modal fields:

| Field | Type | Options / Notes |
|---|---|---|
| Job Title | text | required |
| Effective date | date | |
| Manager | user select | typeahead "Start typing to search..." |
| Department | select | Human Resource, Sales & Marketing, Technology, CEO Office |
| Job type | select | Not Applicable, Permanent, Contract Basis, SL1M OJT, OJT, Part-Time Staff, Freelance, Probation, Internship |
| Description | textarea | required |

---

## 8. Training & Certificate

Repeatable list. Add modal fields:

| Field | Type | Notes |
|---|---|---|
| Training Title | text | required |
| Start Date | date | required |
| End Date | date | required |
| Description | textarea | required |
| Received Date | date | required (certificate received) |
| Expired Date | date | required (certificate expiry) |
| Certification | file upload | Drag & Drop / Browse |

---

## 9. Equipment

Repeatable list. "Assign Equipment Form" modal fields:

| Field | Type | Notes |
|---|---|---|
| Equipment Type | text/select | required |
| Equipment Details | text | required |
| Date Received | date | required |
| Date Return | date | |
| Supporting Document | file upload | Drag & Drop / Browse |

---

## 10. Leave Policy

Title: "Leave Policies". Tabular list with Export action.

Columns:
- No.
- Leave Type (e.g. Annual Leave, Medical Leave, Compassionate Leave - Maternity Leave, Compassionate Leave - Death of Family Member, etc.)
- Entitlement (Day(s))
- Balance (Day(s))
- Remarks
- Included
- Actions: Edit

"Update Leave Policy" modal fields (per row):
| Field | Type |
|---|---|
| Leave Entitlement | number (Day(s)), required |
| Leave Balance | number (Day(s)), required |
| Total Applied | number (read-only) |

---

## 11. Claim Policy

Title: "Claim Policies". Tabular list with Export action.

Columns:
- No.
- Claim Type (e.g. Meal, Mileage (KM), Others/Misc, Telephone & Broadband, Toll, Petrol, Cloud Infrastructure, Online Ads for Google and Facebook)
- Application Limit (RM)
- Annual Limit (RM)
- Balance (RM)
- Remarks
- Included
- Actions: Edit

"Update Claim Policy" modal fields (per row):
| Field | Type | Notes |
|---|---|---|
| Application limit (RM) | currency / Unlimited checkbox | required |
| Annual limit (RM) | currency / Unlimited checkbox | required |
| Total Applied | currency | read-only |
| Claim balance (RM) | currency | |

---

## 12. Disciplinary

Title: "Disciplinary Details". Repeatable list. "Disciplinary Information" modal fields:

| Field | Type | Notes |
|---|---|---|
| Issue | text | required |
| Details | textarea | required |
| Date Issued | date | required |
| Action Taken | text/textarea | |
| Supporting Document | file upload | Drag & Drop / Browse |

---

## 13. App Setting

Title: "App Setting". All toggles (Enable / Disable):

| Setting | Type |
|---|---|
| MySyarikat App Version | display / toggle |
| Enable Notification | toggle |

### Attendance Setting (sub-section)
| Setting | Type |
|---|---|
| Enable employee clock in/out selfie | toggle |
| Enable early & late indicator | toggle |
| Display attendance confirmation before submit | toggle |

---

## Notes

- Required fields are marked with `*` in the UI.
- All list-style tabs (Family Detail, Document, Career Progress, Training & Certificate, Equipment, Disciplinary) support add/edit/delete and a search field.
- Leave Policy and Claim Policy are pre-seeded per company and only the per-employee entitlement/balance/limit is editable.
- Several Compensation > Income Tax fields are derived from Family Details and can be synced.
- Approval Details (Employment tab) configure multi-level approval chains for Leave, Claim, Overtime, and Timeoff.
