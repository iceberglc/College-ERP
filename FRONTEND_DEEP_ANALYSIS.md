# FRONTEND DEEP ANALYSIS
## Iceberg College ERP — Django Frontend

**Analyzed by:** Claude (Senior Frontend Architect + Flutter Migration Planner)  
**Date:** 2026-06-11  
**Branch:** `claude/review-codebase-MWWNv`  
**Project root:** `/home/user/College-ERP/`

---

## Section 1: Project Overview

**What this system is:**  
ICEBERG Study Center ERP — a college/language-school management platform used in Uzbekistan. Students are primarily English-language learners. The system manages admissions, attendance, results, vocabulary, payments (UZS soʻm), leaderboards, library, assignments, messaging, and stories.

**Tech stack:**
- Backend: Django 5.2 LTS, Python 3.x
- Database: SQLite (dev) / PostgreSQL (prod via DigitalOcean)
- Auth: Custom EmailBackend + login_id field (NOT Django's default username)
- CSS framework: Bootstrap 5.1.3 (vendor bundle)
- Icons: FontAwesome Free 5 (solid/regular/brands)
- Charts: Chart.js (UMD bundle, `chart.umd.min.js`)
- JavaScript: Vanilla JS + jQuery 3.x (minimal use)
- Notifications: Firebase Cloud Messaging (FCM)
- REST API: Django REST Framework + SimpleJWT
- Deployment: Gunicorn + nginx / DigitalOcean App Platform

**User Roles (user_type field):**

| Value | Role | Description |
|-------|------|-------------|
| `"1"` | HOD / Admin | Branch or super admin. Manages everything in their branch scope. |
| `"2"` | Staff / Teacher | Takes attendance, adds results, manages vocabulary, assignments. |
| `"3"` | Student | Views own attendance, results, vocabulary, progress, payments. |

**Login method:**
- Admins log in with `email` + password
- Staff log in with `login_id` (format: `TC{MMDD}{NN}`, e.g. `TC052401`) + password
- Students log in with `login_id` (format: `IC{MMDD}{NN}`, e.g. `IC052401`) + password
- Login field on form is named `identifier` (maps to either email or login_id)

**Branch permissions:**
- `is_super_admin=True` → sees ALL branches
- `is_super_admin=False` → sees ONLY their `Admin.branches` (many-to-many)
- Staff and students each have a `branch` FK to `Branch`
- `branching.py` handles all filtering: `filter_students_for_user()`, `filter_staff_for_user()`, `filter_groups_for_user()`, `get_accessible_branches()`

---

## Section 2: Template Inheritance Map

```
main_app/base.html  ← MASTER BASE
├── main_app/login.html                  (login page, standalone)
├── registration/erpnext_base.html       ← password reset base
│   ├── registration/forgot_password.html
│   ├── registration/verify_reset_code.html
│   ├── registration/reset_password.html
│   ├── registration/password_reset_form.html
│   ├── registration/password_reset_done.html
│   ├── registration/password_reset_confirm.html
│   └── registration/password_reset_complete.html
├── hod_template/home_content.html       (admin dashboard)
├── hod_template/manage_student.html
├── hod_template/manage_staff.html
├── hod_template/manage_course.html
├── hod_template/manage_subject.html
├── hod_template/manage_group.html
├── hod_template/manage_branch.html
├── hod_template/manage_admin.html
├── hod_template/manage_session.html
├── hod_template/manage_enrollment.html
├── hod_template/manage_payments.html
├── hod_template/manage_stories.html
├── hod_template/manage_vocabulary_days.html
├── hod_template/manage_registration_leads.html
├── hod_template/add_student_template.html
├── hod_template/add_staff_template.html
├── hod_template/add_course_template.html
├── hod_template/add_subject_template.html
├── hod_template/add_group.html
├── hod_template/add_branch.html
├── hod_template/add_session_template.html
├── hod_template/add_admin_template.html
├── hod_template/add_enrollment.html
├── hod_template/add_invoice.html
├── hod_template/edit_student_template.html
├── hod_template/edit_staff_template.html
├── hod_template/edit_course_template.html
├── hod_template/edit_subject_template.html
├── hod_template/edit_session_template.html
├── hod_template/group_detail.html
├── hod_template/admin_view_profile.html
├── hod_template/admin_view_attendance.html
├── hod_template/student_feedback_template.html
├── hod_template/staff_feedback_template.html
├── hod_template/student_leave_view.html
├── hod_template/staff_leave_view.html
├── hod_template/student_notification.html
├── hod_template/staff_notification.html
├── hod_template/generate_invoices.html
├── hod_template/record_payment.html
├── hod_template/story_form.html
├── hod_template/admin_leaderboard_settings.html
├── hod_template/admin_manage_seasons.html
├── staff_template/erpnext_staff_home.html   (staff dashboard)
├── staff_template/staff_take_attendance.html
├── staff_template/staff_update_attendance.html
├── staff_template/staff_add_result.html
├── staff_template/edit_student_result.html
├── staff_template/staff_result_files.html
├── staff_template/upload_result_file.html
├── staff_template/staff_apply_leave.html
├── staff_template/staff_feedback.html
├── staff_template/staff_view_profile.html
├── staff_template/staff_view_notification.html
├── staff_template/staff_payments.html
├── staff_template/staff_assignments.html
├── staff_template/add_assignment.html
├── staff_template/view_submissions.html
├── staff_template/staff_vocabulary_days.html
├── staff_template/add_vocabulary_day.html
├── staff_template/staff_vocabulary_day_detail.html
├── staff_template/staff_story_form.html
├── staff_template/add_book.html
├── staff_template/issue_book.html
├── staff_template/view_issued_book.html
├── student_template/erpnext_student_home.html  (student dashboard)
├── student_template/student_view_attendance.html
├── student_template/student_view_result.html
├── student_template/student_result_files.html
├── student_template/student_apply_leave.html
├── student_template/student_feedback.html
├── student_template/student_view_profile.html
├── student_template/student_view_notification.html
├── student_template/student_payments.html
├── student_template/student_assignments.html
├── student_template/submit_assignment.html
├── student_template/leaderboard.html
├── student_template/leaderboard_history.html
├── student_template/leaderboard_season.html
├── student_template/vocabulary_day_list.html
├── student_template/vocabulary_day_detail.html
├── student_template/vocabulary_day_flashcard.html
├── student_template/vocabulary_day_quiz.html
├── student_template/view_books.html
├── student_template/student_progress.html
└── main_app/messages.html
    main_app/profile_hub.html
    main_app/payment_receipt.html
    main_app/error.html
```

**Partials/includes (not full pages):**
- `main_app/partials/glowing_bottom_nav.html` — mobile bottom navigation (4 tabs per role)
- `main_app/includes/animated_logout_button.html` — animated sign-out button (reusable)
- `main_app/includes/profile_settings_row.html` — avatar + profile row
- `main_app/erpnext_sidebar.html` — full sidebar navigation (included by base.html)
- `staff_template/includes/library_tabs.html` — tab bar for library pages

---

## Section 3: CSS Architecture

### CSS File Inventory

| File | Purpose | Pages |
|------|---------|-------|
| `iceberg.css` | Main design system: CSS variables (navy #06343A, lime #DFFF2F), layout primitives, sidebar, cards, tables, badges | All pages via base.html |
| `erpnext-style.css` | Sidebar layout, nav-link active states, content area padding, header | All pages via base.html |
| `glowing-bottom-nav.css` | Mobile bottom nav: pill shape, lime glow on active, 4-col grid | Mobile, all roles |
| `admin-dashboard-2026.css` | Admin dashboard: command section, metric cards, sparklines, radial, charts, activity feed, quick-actions grid | Admin home only |
| `staff-modern.css` | Staff dashboard: hero section, KPI cards, group list, action grid | Staff home only |
| `student-modern.css` | Student dashboard: hero with rank badge, stories strip, vocab tiles, assignments, notification cards | Student home only |
| `iceberg-bold.css` | Typography overrides, bolder headings, stronger shadows | All pages |
| `iceberg-mobile-polish.css` | Mobile-specific fixes: safe area insets, touch targets, overflow | Mobile, all pages |
| `iceberg-reliability.css` | Defensive overrides: z-index fixes, focus rings, ARIA, print styles | All pages |
| `admin-manage-mobile.css` | Admin manage pages on mobile: responsive tables, action buttons stacking | Admin manage pages on mobile |
| `animated-icons.css` | Keyframe animations for icons (pulse, spin, bounce) | Various pages |
| `animated-logout.css` | Sign-out button animation: rocket lift-off effect | Logout button (all roles) |
| `interactions.css` | Button hover/press states, micro-interactions, ripple | All interactive elements |
| `loading.css` | Page loading skeleton, spinner overlay | All pages during load |
| `mobile-adaptive.css` | Table scroll wrappers, card stacking for small screens | Tables on mobile |
| `notifications.css` | Notification cards, unread dot, notification list | Notification pages |
| `profile-hub.css` | Profile page: avatar picker, personal info form, theme selector | Profile hub page |
| `storefront-ui.css` | Stories strip on student home, story cards, story overlay | Student home |

### CSS Design Tokens (from `iceberg.css`)

```css
:root {
  --ice-navy:       #06343A;   /* Primary brand navy/teal-dark */
  --ice-navy-mid:   #073B42;   /* Slightly lighter navy */
  --ice-navy-deep:  #0E6873;   /* Deep teal accent */
  --ice-lime:       #DFFF2F;   /* Lime accent (active states, highlights) */
  --ice-bg:         #FAFAFA;   /* Page background */
  --ice-surface:    #FFFFFF;   /* Card/panel background */
  --ice-surface2:   #F4FAFB;   /* Alternate surface */
  --ice-border:     #DCEAEC;   /* Border color */
  --ice-muted:      #6B7F83;   /* Muted text */
  --ice-success:    #38A169;   /* Green: present/paid */
  --ice-danger:     #E56B6F;   /* Red: absent/rejected */
  --ice-cyan:       #06B6D4;   /* Cyan accent (charts, highlights) */
  --ice-warning:    #F59E0B;   /* Amber: late/pending */
}
```

**Student dashboard inline tokens (erpnext_student_home.html):**
```css
--navy:      #0C1F45;
--navy-mid:  #1B3F7A;
--cyan:      #06B6D4;
--bg-page:   #EEF3FB;
--surface:   #ffffff;
--border:    #E2EAF4;
```

**Typography:** `'Inter', -apple-system, BlinkMacSystemFont, sans-serif` — loaded from Google Fonts or system font stack.

**Font sizes:** 10–19px for UI text; 28–40px for KPI numbers; 11px for labels/kickers.

**Border radii:** 8px (small), 12px (medium), 18–24px (cards), 999px (pill/badges).

---

## Section 4: JavaScript Architecture

### JS File Inventory

| File | Purpose |
|------|---------|
| `csrf-setup.js` | Sets up CSRF token for all AJAX/fetch requests (reads `csrftoken` cookie) |
| `glowing-bottom-nav.js` | Bottom nav: active state management, scroll-to-hide on scroll-down, scroll-to-show on scroll-up |
| `iceberg-interactive.js` | Dark/light mode toggle, chart recreation on theme switch, sidebar toggle, keyboard shortcuts |
| `iceberg-mobile-polish.js` | iOS viewport height fix (100svh), safe area insets, bounce prevention, touch gesture handling |
| `platform-detect.js` | Detects iOS/Android/desktop, adds CSS class to `<html>` for platform-specific styles |
| `loading.js` | Page loading overlay: shows on navigation, hides on DOMContentLoaded |
| `animated-logout.js` | Animated sign-out: rocket animation, then submits logout form via POST |
| `safe-actions.js` | Confirm dialogs before delete/destructive actions; prevents double-submit on forms |
| `profile-hub.js` | Profile page: avatar picker grid (emoji), theme selector, avatar save via AJAX to `/profile/save-avatar/` |
| `responsive-tables.js` | Wraps tables in `.table-responsive` divs on mobile, adds horizontal scroll hint |
| `trend-chart.js` | Shared Chart.js helper: creates area/line charts with gradient fills (used by staff home) |
| `admin-manage-mobile.js` | Admin manage pages: mobile action menus (3-dot), swipe-to-reveal actions on cards |

### Key Inline JS patterns

**Admin home (home_content.html):**  
- Creates 4 Chart.js line charts: `branchChart`, `barChart`, `pieChart`, `pieChart2`, `barChart2`
- Data injected via `{{ monthly_chart_json|safe }}` and `{{ branch_chart_json|safe }}`
- Dark mode aware: reacts to `data-theme` attribute change
- Mobile aware: `isMobile()` disables point radius

**Staff home:**
- 2 Chart.js line charts: `pieChart` (attendance rate), `barChart` (sessions)
- Data from `{{ monthly_chart_json|safe }}`

**Student home:**
- No explicit Chart.js — uses CSS-based progress bars and numeric displays

**Attendance pages:**
- AJAX calls: `GET /staff/get_students/` for student list
- AJAX calls: `GET /staff/attendance/fetch/` for existing attendance
- AJAX calls: `POST /staff/attendance/save/` to save
- AJAX calls: `POST /staff/attendance/update_save/` to update
- Uses `fetch()` API with CSRF token

**Enrollment/Admin pages:**
- AJAX: `GET /ajax/teachers-for-course/` — returns teachers for a course (JSON)
- AJAX: `GET /ajax/groups-for-teacher/` — returns groups for a teacher (JSON)

---

## Section 5: Navigation Structure

### Sidebar (desktop, `erpnext_sidebar.html`)

**Admin sidebar sections:**
1. **Overview:** Dashboard, Profile & Settings
2. **People:** Students, Teachers, Admins
3. **Academic Management:** Groups & Enrollments, Branches, Courses, Attendance
4. **Finance:** Payments
5. **Vocabulary & Content:** Vocabulary, Leaderboard, Stories
6. **Communication:** Messages (with unread badge), Leads, Student Feedback, Teacher Feedback
7. **Requests:** Student Leave, Teacher Leave

**Staff sidebar sections:**
1. **Home:** Dashboard, Profile & Settings
2. **Teaching:** Take Attendance, Update Attendance, Scores, Result Files, Assignments, Payments (read-only), Vocabulary, Stories, Library
3. **Communication:** Messages, Notifications, Leave, Feedback

**Student sidebar sections:**
1. **Home:** Dashboard, Profile & Settings
2. **Study:** Attendance, Scores, Result Files, Assignments, Vocabulary, Progress, Payments, Leaderboard, Library
3. **Communication:** Messages, Notifications, Leave, Feedback

### Bottom Navigation (mobile, `glowing_bottom_nav.html`)

**Admin (4 tabs):**
1. Home → `/admin/home/`
2. People → `/student/manage/` (active when path contains student/staff/group)
3. Chat → `/messages/` (with unread dot)
4. Profile → `/profile/`

**Staff (4 tabs):**
1. Home → `/staff/home/`
2. Attendance → `/staff/attendance/take/`
3. Scores → `/staff/result/add/`
4. Profile → `/profile/`

**Student (4 tabs):**
1. Home → `/student/home/`
2. Attendance → `/student/view/attendance/`
3. Results → `/student/view/result/`
4. Profile → `/profile/`

---

## Section 6: Full Page Inventory

### 6.1 AUTH / PUBLIC PAGES

---

**Page: Login**
- Template: `main_app/login.html`
- URL: `/` or `/login/`
- View: `views.login_page` (GET) + `views.doLogin` (POST to `/doLogin/`)
- Role: Public (unauthenticated)
- Form fields: `identifier` (email or login_id), `password`
- POST action: `/doLogin/`
- On success: redirect based on user_type → `/admin/home/`, `/staff/home/`, or `/student/home/`
- On failure: redirect back to `/login/` with error message
- CSS: standalone (no base.html sidebar), imports iceberg.css
- Features: "Forgot password?" link, animated background, logo

---

**Page: Password Reset — Forgot Password**
- Template: `registration/forgot_password.html` (extends `registration/erpnext_base.html`)
- URL: `/password-reset/` (via Django's built-in or custom `password_recovery.py`)
- Role: Public
- Form: email field
- On success: sends OTP to email, redirects to verify step

**Page: Verify Reset Code**
- Template: `registration/verify_reset_code.html`
- URL: `/password-reset/verify/`
- Form: 6-digit code input

**Page: Reset Password**
- Template: `registration/reset_password.html`
- URL: `/password-reset/confirm/`
- Form: new_password, confirm_password

---

### 6.2 ADMIN (HOD) PAGES

---

**Page: Admin Dashboard (Home)**
- Template: `hod_template/home_content.html`
- Extends: `main_app/base.html`
- URL: `/admin/home/`
- Route name: `admin_home`
- View: `hod_views.admin_home`
- Role: Admin (user_type='1')
- Decorator: `@admin_only`
- Extra CSS: `admin-dashboard-2026.css`

**Context variables received:**
```python
total_students, total_staff, total_course, active_course_count, total_groups
new_students_7, new_students_previous  # week-over-week
new_staff_7, new_staff_previous
new_groups_7, new_groups_previous
new_courses_7, new_courses_previous
attendance_today_rate, today_attendance_present, today_attendance_total
total_capacity, active_enrollments, group_fill_pct
assignments_due_soon
metric_cards  # list of dicts with {icon, value, label, trend, trend_label, progress, spark, href, tone}
recent_students  # last 5 Student objects
recent_leads    # last 5 RegistrationLead objects (status=new)
recent_activity # list of dicts {title, meta, at, href, icon}
teacher_activity # Staff with annotated active_groups_count
upcoming_classes # Group objects with start_date
today_attendance_groups # per-group attendance summary
branch_chart_json  # JSON: {labels, lines: [{label, color, health[]}]}
monthly_chart_json # JSON: {labels, att_rate[], new_students[], sessions[]}
```

**Charts:**
1. `branchChart` — Branch Performance multi-line (health score %, last 6 months, one line per branch)
2. `barChart` — Monthly Attendance Rate % (line chart)
3. `pieChart` — New Students Monthly (line chart — mislabeled "pie")
4. `pieChart2` — Monthly Sessions (line chart)
5. `barChart2` — Combined Attendance % + Sessions (dual-line)

**Key buttons/actions:**
- "Add Student" → `/student/add/`
- "Manage Groups" → `/group/manage/`
- "Profile Settings" → `/profile/`
- Quick Actions grid (8 buttons): Add Student, Add Teacher, Add Program, Add Group, Enroll Student, Attendance, Group Messages, Teacher Feedback
- Metric cards are links (href per card)
- Recent students rows link to `/student/edit/{id}`
- Faculty pulse rows link to `/staff/edit/{id}`

**Layout:** Full-width command section at top (hero), then 4 metric cards, then quick actions grid, then charts and live sections in CSS grid.

---

**Page: Manage Students**
- Template: `hod_template/manage_student.html`
- URL: `/student/manage/`
- Route name: `manage_student`
- View: `hod_views.manage_student`
- Context: `students` (queryset, branch-scoped)
- Table columns: Name, Login ID, Email, Course, Branch, Status, Actions
- Actions per row: Edit (`/student/edit/{id}`), Delete (POST to `/student/delete/{id}` with confirm)
- Branch-scoped: branch admins see only own branch students
- Extra CSS: `admin-manage-mobile.css`
- Add button → `/student/add/`

---

**Page: Add Student**
- Template: `hod_template/add_student_template.html`
- URL: `/student/add/`
- Route name: `add_student`
- View: `hod_views.add_student` (GET renders form, POST creates)
- Form fields: first_name, last_name, email, date_of_birth, gender, phone, address, course, branch, status, level, password
- Backend: Creates `CustomUser` (user_type='3') + auto-creates `Student` via signal, generates `login_id` like `IC{MMDD}{NN}`
- On success: redirect to `manage_student` with success message

---

**Page: Edit Student**
- Template: `hod_template/edit_student_template.html`
- URL: `/student/edit/<int:student_id>`
- Route name: `edit_student`
- View: `hod_views.edit_student`
- Pre-populated form (same fields as add)
- POST updates Student, CustomUser, and regenerates login_id if DOB changes
- Branch check: branch admin can only edit students in their own branch (🐛 **verify IDOR guard**)

---

**Page: Manage Staff**
- Template: `hod_template/manage_staff.html`
- URL: `/staff/manage/`
- Route name: `manage_staff`
- Context: `staffs` (branch-scoped)
- Table columns: Name, Login ID, Email, Course, Branch, Specialization, Active, Actions
- Actions: Edit (`/staff/edit/{id}`), Delete (POST `/staff/delete/{id}`)

---

**Page: Add Staff**
- Template: `hod_template/add_staff_template.html`
- URL: `/staff/add`
- View: `hod_views.add_staff`
- Form: first_name, last_name, email, date_of_birth, gender, phone, address, course, branch, specialization, is_active, password
- Auto-generates `TC{MMDD}{NN}` login_id

---

**Page: Edit Staff**
- Template: `hod_template/edit_staff_template.html`
- URL: `/staff/edit/<int:staff_id>`
- Route name: `edit_staff`
- View: `hod_views.edit_staff`

---

**Page: Manage Courses**
- Template: `hod_template/manage_course.html`
- URL: `/course/manage/`
- Route name: `manage_course`
- View: `hod_views.manage_course`
- Context: `courses`
- Table: Name, Active, Is English, Monthly Fee, Created, Actions
- Actions: Edit, Delete, Toggle Active

---

**Page: Add Course**
- Template: `hod_template/add_course_template.html`
- URL: `/course/add`
- View: `hod_views.add_course`
- Form: name, is_active, is_english, monthly_fee

---

**Page: Edit Course**
- Template: `hod_template/edit_course_template.html`
- URL: `/course/edit/<int:course_id>`

---

**Page: Manage Subjects**
- Template: `hod_template/manage_subject.html`
- URL: `/subject/manage/`
- Context: `subjects` with staff+course
- Table: Name, Course, Staff, Actions

---

**Page: Add Subject**
- Template: `hod_template/add_subject_template.html`
- URL: `/subject/add/`
- Form: name, staff (FK), course (FK)

---

**Page: Manage Groups**
- Template: `hod_template/manage_group.html`
- URL: `/group/manage/`
- Route name: `manage_group`
- View: `hod_views.manage_group`
- Context: `groups` (branch-scoped, `is_archived=False`)
- Table: Name, Course, Teacher, Branch, Room, Schedule, Capacity, Enrolled, Monthly Fee, Start Date, Actions
- Actions per row: View Students, Edit, Archive, Delete
- Add Group button → `/group/add/`

---

**Page: Group Detail**
- Template: `hod_template/group_detail.html`
- URL: `/group/<int:group_id>/students/`
- Route name: `admin_group_detail`
- View: `hod_views.admin_group_detail`
- Shows enrolled students in a specific group
- Context: `group`, `students` (via Enrollment)
- IDOR protection: verifies group belongs to admin's accessible branches

---

**Page: Add Group**
- Template: `hod_template/add_group.html`
- URL: `/group/add/`
- View: `hod_views.add_group`
- Form: name, course, teacher (dynamic: AJAX loads teachers by course), branch, room, schedule, capacity, monthly_fee, start_date
- AJAX: `GET /ajax/teachers-for-course/?course_id=X` → JSON list of teachers
- On group creation: auto-creates `ChatThread` for the group

---

**Page: Edit Group**
- Template: `hod_template/edit_group.html` ⚠️ — not listed in templates; uses `hod_template/add_group.html` with editing context (verify)
- URL: `/group/edit/<int:group_id>`

---

**Page: Manage Branches**
- Template: `hod_template/manage_branch.html`
- URL: `/branch/manage/`
- Route name: `manage_branch`
- View: `hod_views.manage_branch`
- Table: Name, Address, Created, Admins, Actions
- Actions: Edit, Delete
- Also shows admin-branch access table (which admins can see which branches)

---

**Page: Add Branch**
- Template: `hod_template/add_branch.html`
- URL: `/branch/add/`
- Form: name, address

---

**Page: Manage Sessions**
- Template: `hod_template/manage_session.html`
- URL: `/session/manage/`
- Context: `sessions`
- Table: Start Year, End Year, Actions (Edit, Delete)

---

**Page: Manage Enrollment**
- Template: `hod_template/manage_enrollment.html`
- URL: `/enrollment/manage/`
- Context: `groups` (with enrollment counts), `enrollments`
- Actions: Delete enrollment, Add enrollment

---

**Page: Add Enrollment**
- Template: `hod_template/add_enrollment.html`
- URL: `/enrollment/add/`
- View: `hod_views.add_enrollment`
- Dynamic form: select course → AJAX loads teachers → AJAX loads groups for teacher → select student (search)
- AJAX: `/enrollment/group-info/` — returns group capacity + current enrollment count

---

**Page: Manage Admins**
- Template: `hod_template/manage_admin.html`
- URL: `/admin/manage/`
- Route name: `manage_admin`
- View: `hod_views.manage_admin`
- Table: Name, Email, Is Super Admin, Branches, Actions
- Actions: Edit branch access, Delete
- Only super admin can delete other admins
- 🐛 Cannot delete the last super admin (enforced by `Admin.clean()`)

---

**Page: Add Admin**
- Template: `hod_template/add_admin_template.html`
- URL: `/admin/add/`
- View: `hod_views.add_admin`
- Form: first_name, last_name, email, password, is_super_admin, branches (multi-select)
- Protected: only super admin can create new admins

---

**Page: Admin View Attendance**
- Template: `hod_template/admin_view_attendance.html`
- URL: `/attendance/view/`
- Route name: `admin_view_attendance`
- View: `hod_views.admin_view_attendance`
- Context: `groups` (branch-scoped)
- Select group → AJAX: `GET /attendance/fetch/?group_id=X&month=Y` → returns per-student attendance table
- Table: Student, date columns, P/A/L status, totals

---

**Page: Admin Payments**
- Template: `hod_template/manage_payments.html`
- URL: `/admin/payments/`
- Route name: `admin_payments`
- View: `payments_views.admin_payments`
- Context: invoices (branch-scoped), period filter, group filter
- Table: Student, Group, Period, Amount, Discount, Paid, Balance, Status, Due Date, Actions
- Actions: Record Payment, Cancel Invoice, Send Reminder, Download Receipt
- Add Invoice → `/admin/payments/invoice/add/`
- Generate Invoices → `/admin/payments/generate/`
- CSV export button

---

**Page: Generate Invoices**
- Template: `hod_template/generate_invoices.html`
- URL: `/admin/payments/generate/`
- Form: month/year selector, group filter
- POST creates Invoice records for all active enrollments

---

**Page: Record Payment**
- Template: `hod_template/record_payment.html`
- URL: `/admin/payments/invoice/<int:invoice_id>/record/`
- Form: amount, method (cash/card/transfer/payme/click/uzum), note, paid_on

---

**Page: Add Invoice (Manual)**
- Template: `hod_template/add_invoice.html`
- URL: `/admin/payments/invoice/add/`
- Form: student (search), group, period, amount, discount, note, due_date

---

**Page: Manage Stories**
- Template: `hod_template/manage_stories.html`
- URL: `/admin/stories/`
- Route name: `manage_stories`
- Context: `stories`
- Table: Title, Type, Emoji, Created By, Active, Expires, Actions
- Actions: Edit, Delete

---

**Page: Add/Edit Story**
- Template: `hod_template/story_form.html`
- URL Add: `/admin/stories/add/`
- URL Edit: `/admin/stories/<int:story_id>/edit/`
- Form: title, body, image (upload), story_type, emoji, bg_color, target_groups (multi-select), is_active, expires_at

---

**Page: Manage Vocabulary Days (Admin)**
- Template: `hod_template/manage_vocabulary_days.html`
- URL: `/admin/vocabulary-days/`
- Context: `vocab_days` across all accessible groups
- Table: Group, Day Number, Title, Word Count, Release Date, Scope
- Read-only view (editing is teacher's job)

---

**Page: Registration Leads**
- Template: `hod_template/manage_registration_leads.html`
- URL: `/admin/registration-leads/`
- Route name: `manage_registration_leads`
- View: `hod_views.manage_registration_leads`
- Context: leads (all statuses), summary counts by status
- Table: Full Name, Phone, Email, Program, Branch, Source, Status, Created
- Status filter chips
- Actions: Update status (inline POST), Add notes

---

**Page: Student Feedback (Admin View)**
- Template: `hod_template/student_feedback_template.html`
- URL: `/student/view/feedback/`
- View: `hod_views.student_feedback_message`
- Context: `feedbacks` (FeedbackStudent objects)
- Actions: Reply button → POST reply to same URL

---

**Page: Staff Feedback (Admin View)**
- Template: `hod_template/staff_feedback_template.html`
- URL: `/staff/view/feedback/`
- Context: `feedbacks` (FeedbackStaff objects)

---

**Page: Student Leave (Admin View)**
- Template: `hod_template/student_leave_view.html`
- URL: `/student/view/leave/`
- View: `hod_views.view_student_leave`
- Context: `leave_reports` (LeaveReportStudent)
- Table: Student, Date, Message, Status, Actions
- Actions: Approve (POST), Reject (POST)

---

**Page: Staff Leave (Admin View)**
- Template: `hod_template/staff_leave_view.html`
- URL: `/staff/view/leave/`
- Context: `leave_reports` (LeaveReportStaff)

---

**Page: Send Student Notification**
- Template: `hod_template/student_notification.html`
- URL: `/admin_notify_student`
- View: `hod_views.admin_notify_student` (GET) + `send_student_notification` (POST)
- Form: message, category, target (all students or specific group)

---

**Page: Send Staff Notification**
- Template: `hod_template/staff_notification.html`
- URL: `/admin_notify_staff`

---

**Page: Leaderboard Settings (Admin)**
- Template: `hod_template/admin_leaderboard_settings.html`
- URL: `/admin/leaderboard/settings/`
- Form: attendance_weight, homework_weight, quizzes_weight, results_weight, enable_* checkboxes

---

**Page: Manage Leaderboard Seasons**
- Template: `hod_template/admin_manage_seasons.html`
- URL: `/admin/leaderboard/seasons/`
- Context: `seasons` (LeaderboardSeason objects)
- Actions: Create season, Delete season, Take Snapshot (POST)

---

**Page: Admin View Profile**
- Template: `hod_template/admin_view_profile.html`
- URL: `/admin_view_profile`

---

### 6.3 STAFF PAGES

---

**Page: Staff Dashboard (Home)**
- Template: `staff_template/erpnext_staff_home.html`
- Extends: `main_app/base.html`
- URL: `/staff/home/`
- Route name: `staff_home`
- View: `staff_views.staff_home`
- Decorator: `@staff_only`
- Extra CSS: `staff-modern.css` + inline styles

**Context variables:**
```python
total_students, total_attendance, total_leave, total_subject  # KPI counts
groups  # Group objects where teacher=request.user's Staff
monthly_chart_json  # {labels, att_rate[], sessions[]}
```

**Charts:**
1. `pieChart` — Monthly Attendance Rate (line, own groups only)
2. `barChart` — Monthly Sessions Taken

**Key buttons:**
- "Take Attendance" → `/staff/attendance/take/`
- "Add Results" → `/staff/result/add/`
- Quick Action grid (8): Take Attendance, Update Attendance, Add Results, Edit Results, Apply Leave, Send Feedback, Messages, My Profile

---

**Page: Take Attendance**
- Template: `staff_template/staff_take_attendance.html`
- URL: `/staff/attendance/take/`
- View: `staff_views.staff_take_attendance`
- Decorator: `@staff_only`
- Step 1: Select group (dropdown, own groups only)
- Step 2: Select date (date picker)
- Step 3: AJAX `GET /staff/get_students/?group_id=X` → renders student list
- Step 4: Toggle each student: Present / Late / Absent
- Step 5: POST `AJAX /staff/attendance/save/` → JSON `{group_id, date, attendance: [{student_id, status}]}`
- IDOR protection: `get_students` checks `group.teacher == request.user`

---

**Page: Update Attendance**
- Template: `staff_template/staff_update_attendance.html`
- URL: `/staff/attendance/update/`
- View: `staff_views.staff_update_attendance`
- Like Take Attendance but for an existing date
- AJAX: `GET /staff/attendance/fetch/?group_id=X&date=Y` → existing status per student
- POST: `/staff/attendance/update_save/`
- IDOR: verifies group.teacher matches request.user

---

**Page: Add Result**
- Template: `staff_template/staff_add_result.html`
- URL: `/staff/result/add/`
- Route name: `staff_add_result`
- View: `staff_views.staff_add_result`
- Step 1: Select own course → AJAX `/staff/ajax/teachers-for-course/`
- Step 2: Select teacher (self only) + group → AJAX `/staff/ajax/groups-for-teacher/`
- Step 3: Select student
- POST: Creates `StudentResult(student, group, test, exam, comment)`
- Grading: test max 40, exam max 60, total 100

---

**Page: Edit Result**
- Template: `staff_template/edit_student_result.html`
- URL: `/staff/result/edit/`
- Route name: `edit_student_result`
- View: `EditResultView` (class-based)
- Same filters as add result
- AJAX: `GET /staff/result/fetch/?group_id=X&student_id=Y` → existing result
- PUT/PATCH updates the result
- IDOR: checks group.teacher matches staff

---

**Page: Staff Result Files**
- Template: `staff_template/staff_result_files.html`
- URL: `/staff/result/files/`
- Context: `result_files` (own uploads)
- Table: Title, Group, Student (optional), Uploaded, Description, Actions
- Actions: Download, Delete (POST `/staff/result/delete-file/{id}/`)
- Upload button → `/staff/result/upload-file/`

---

**Page: Upload Result File**
- Template: `staff_template/upload_result_file.html`
- URL: `/staff/result/upload-file/`
- View: `staff_views.upload_result_file`
- Form: title, description, group (own), student (optional), file (upload)
- Stores to `ResultFile` model, `file` in `results/` directory

---

**Page: Apply Leave (Staff)**
- Template: `staff_template/staff_apply_leave.html`
- URL: `/staff/apply/leave/`
- Route name: `staff_apply_leave`
- View: `staff_views.staff_apply_leave`
- Form: date, message
- POST: Creates `LeaveReportStaff(staff, date, message)`
- Also shows own leave history table (date, message, status badge)

---

**Page: Staff Feedback**
- Template: `staff_template/staff_feedback.html`
- URL: `/staff/feedback/`
- Form: feedback (textarea)
- POST: Creates `FeedbackStaff(staff, feedback)`
- Shows own feedback history with admin replies

---

**Page: Staff Notifications**
- Template: `staff_template/staff_view_notification.html`
- URL: `/staff/view/notification/`
- Context: `notifications` (own Notification objects, ordered by `-created_at`)
- Shows category badge, message, link, timestamp, read/unread state
- Mark all read: inline

---

**Page: Staff View Profile**
- Template: `staff_template/staff_view_profile.html`
- URL: `/staff/view/profile/`
- Context: Staff object with CustomUser data
- Read-only display (editing done via `/profile/`)

---

**Page: Staff Payments**
- Template: `staff_template/staff_payments.html`
- URL: `/staff/payments/`
- View: `payments_views.staff_payments`
- Context: invoices for students in teacher's groups (branch-scoped, read-only)
- Table: Student, Group, Period, Amount, Paid, Status, Due Date
- No write actions (read-only for staff)

---

**Page: Staff Assignments**
- Template: `staff_template/staff_assignments.html`
- URL: `/staff/assignments/`
- View: `staff_views.staff_assignments`
- Context: own assignments (created by this teacher)
- Table: Title, Subject, Group, Due Date, Submissions, Actions
- Actions: Edit, Delete, View Submissions

---

**Page: Add Assignment**
- Template: `staff_template/add_assignment.html`
- URL: `/staff/assignment/add/`
- Form: title, description, subject (own), group (own), due_date

---

**Page: View Submissions (for an assignment)**
- Template: `staff_template/view_submissions.html`
- URL: `/staff/assignment/<int:assignment_id>/submissions/`
- Table: Student, Submitted At, File, Note, Grade, Actions
- Grade submission: POST `/staff/submission/{id}/grade/` (grade field)

---

**Page: Staff Vocabulary Days**
- Template: `staff_template/staff_vocabulary_days.html`
- URL: `/staff/vocabulary-days/`
- Context: own vocabulary days (by groups where teacher=self)
- Table: Day Number, Title, Group, Words, Released, Scope
- Add → `/staff/vocabulary-days/add/`

---

**Page: Add Vocabulary Day**
- Template: `staff_template/add_vocabulary_day.html`
- URL: `/staff/vocabulary-days/add/`
- Form: group (own), day_number, title, level, release_at, release_scope, notes
- Then add words (word, meaning, example_sentence, pronunciation_note, order)
- POST creates VocabularyDay + VocabularyDayWord objects
- Auto-notifies enrolled students via Notification system

---

**Page: Staff Vocabulary Day Detail / Edit**
- Template: `staff_template/staff_vocabulary_day_detail.html`
- URL: `/staff/vocabulary-days/<int:day_id>/`
- Shows all words, add/remove words
- Edit day metadata at `/staff/vocabulary-days/<int:day_id>/edit/`
- Delete day: `/staff/vocabulary-days/<int:day_id>/delete/`

---

**Page: Staff Create Story**
- Template: `staff_template/staff_story_form.html`
- URL: `/staff/stories/post/`
- Route name: `staff_create_story`
- Form: title, body, image, story_type, emoji, bg_color, target_groups, is_active, expires_at

---

**Page: Library — Add Book**
- Template: `staff_template/add_book.html`
- URL: `/staff/addbook/`
- Tab include: `staff_template/includes/library_tabs.html`
- Form: name, author, isbn, category
- Creates `Book` record

---

**Page: Library — Issue Book**
- Template: `staff_template/issue_book.html`
- URL: `/staff/issue_book/`
- Form: student (search/select), book (ISBN lookup)
- Creates `Loan` record (issued_on, due_on = now + 14 days)

---

**Page: Library — View Issued Books**
- Template: `staff_template/view_issued_book.html`
- URL: `/staff/view_issued_book/`
- Table: Student, Book, Issued On, Due On, Status, Fine, Actions
- Return book: POST `/staff/return_book/{loan_id}/`

---

### 6.4 STUDENT PAGES

---

**Page: Student Dashboard (Home)**
- Template: `student_template/erpnext_student_home.html`
- Extends: `main_app/base.html`
- URL: `/student/home/`
- Route name: `student_home`
- View: `student_views.student_home`
- Decorator: `@student_only`
- Extra CSS: `storefront-ui.css`, `student-modern.css`, inline styles

**Context variables:**
```python
student               # Student object
groups                # Groups student is enrolled in
stories               # DashboardStory objects (active, filtered by group)
notifications         # Recent unread Notification objects
recent_assignments    # Upcoming assignments
latest_result         # Most recent StudentResult
scores_trend          # list of {group_name, total} for chart
attendance_weekly     # 8-week weekly attendance data
homework_weekly       # 8-week submission rate
vocab_quiz_trend      # Quiz score history
overall_performance   # Composite score trend
rank_info             # {rank, total, badge, score}
streak                # Days streak of attending/studying
```

**Features:**
- Stories strip (horizontal scroll): DashboardStory cards with emoji/image + title
- Rank badge (animated, shows current leaderboard position)
- KPI strip: My Groups count, Attendance %, Latest Score, Streak days
- Quick Actions: Vocabulary, Attendance, Results, Progress, Assignments, Payments, Leave, Library
- Recent Assignments list
- Latest Result display
- Notification strip (recent unread)

---

**Page: Student View Attendance**
- Template: `student_template/student_view_attendance.html`
- URL: `/student/view/attendance/`
- Route name: `student_view_attendance`
- View: `student_views.student_view_attendance`
- Context: attendance data per group, monthly breakdown
- Table: Date, Group, Status (P/A/L) with color coding
- Summary: total sessions, % present, % absent

---

**Page: Student View Result**
- Template: `student_template/student_view_result.html`
- URL: `/student/view/result/`
- Route name: `student_view_result`
- Context: `results` (StudentResult objects for this student)
- Table: Group, Test (0-40), Exam (0-60), Total (0-100), Comment
- Shows grade as colored badge

---

**Page: Student Result Files**
- Template: `student_template/student_result_files.html`
- URL: `/student/result/files/`
- Context: `result_files` (ResultFile where student=self OR student is null and group is student's group)
- Table: Title, Group, Uploaded By, Date, Download button
- Download → `/result/download/{file_id}/` (protected, student can only download own files)

---

**Page: Student Apply Leave**
- Template: `student_template/student_apply_leave.html`
- URL: `/student/apply/leave/`
- Form: date, message
- Leave history table: date, message, status badge

---

**Page: Student Feedback**
- Template: `student_template/student_feedback.html`
- URL: `/student/feedback/`
- Form: feedback (textarea)
- History table with admin replies

---

**Page: Student Notifications**
- Template: `student_template/student_view_notification.html`
- URL: `/student/view/notification/`
- Notification list with category badge, message, link, timestamp

---

**Page: Student Payments**
- Template: `student_template/student_payments.html`
- URL: `/student/payments/`
- View: `payments_views.student_payments`
- Context: own invoices
- Cards per invoice: Period, Amount, Discount, Total Due, Paid, Balance, Status badge
- Outstanding balance prominently shown
- Payment method breakdown

---

**Page: Student Leaderboard**
- Template: `student_template/leaderboard.html`
- URL: `/student/leaderboard/`
- View: `student_views.student_leaderboard`
- Scope filter: Group / Branch / All Students
- Time filter: This Week / This Month / All Time
- Context: rankings (list with rank, student_name, score, attendance_pct, homework_pct, quizzes_pct, results_pct, badge)
- Own row highlighted
- Filters: form GET with scope/time_filter params

---

**Page: Leaderboard History**
- Template: `student_template/leaderboard_history.html`
- URL: `/student/leaderboard/history/`
- Context: past seasons list

---

**Page: Leaderboard Season**
- Template: `student_template/leaderboard_season.html`
- URL: `/student/leaderboard/season/<int:season_id>/`
- Context: LeaderboardSnapshot objects for that season, ranked

---

**Page: Vocabulary Day List**
- Template: `student_template/vocabulary_day_list.html`
- URL: `/student/vocabulary-days/`
- Route name: `vocabulary_day_list`
- View: `student_views.vocabulary_day_list`
- Context: released VocabularyDay objects (filtered by student's enrolled groups)
- Cards: Day Number, Title, Word Count, Release Date, Completion checkmark
- Click → vocabulary_day_detail

---

**Page: Vocabulary Day Detail**
- Template: `student_template/vocabulary_day_detail.html`
- URL: `/student/vocabulary-days/<int:day_id>/`
- Route name: `vocabulary_day_detail`
- Context: `day` (VocabularyDay), `words` (VocabularyDayWord list), `completed` (bool)
- Word list: word, meaning, example_sentence, pronunciation_note
- Buttons: "Mark Complete" (POST `/student/vocabulary-days/{id}/complete/`), "Flashcards", "Quiz"

---

**Page: Vocabulary Flashcard**
- Template: `student_template/vocabulary_day_flashcard.html`
- URL: `/student/vocabulary-days/<int:day_id>/flashcard/`
- CSS flip-card animation: front=word, back=meaning+example
- Navigation: Prev / Next buttons
- Progress indicator: 3/10

---

**Page: Vocabulary Quiz**
- Template: `student_template/vocabulary_day_quiz.html`
- URL: `/student/vocabulary-days/<int:day_id>/quiz/`
- Multiple choice quiz: 4 options per word
- POST result: `/student/vocabulary-days/{id}/quiz/save/` → creates VocabularyQuizResult

---

**Page: Student Progress**
- Template: `student_template/student_progress.html`
- URL: `/student/progress/`
- View: `student_views.student_progress`
- Context: trend data (attendance weekly, homework weekly, quiz scores, overall score)
- Charts: attendance trend line, score trend line, homework completion bar
- Summary: current streak, average score, best quiz, attendance rate

---

**Page: Student Assignments**
- Template: `student_template/student_assignments.html`
- URL: `/student/assignments/`
- Context: assignments for student's enrolled groups, sorted by due_date
- Table: Title, Subject, Group, Due Date, Status (submitted/pending/overdue)
- Click assignment → submit

---

**Page: Submit Assignment**
- Template: `student_template/submit_assignment.html`
- URL: `/student/assignment/<int:assignment_id>/submit/`
- Form: file (upload), note (textarea)
- Creates Submission record

---

**Page: Student Library / View Books**
- Template: `student_template/view_books.html`
- URL: `/student/viewbooks/`
- Context: active loans for this student + all available books
- Table: Book Name, Author, ISBN, Category, Issued On, Due On, Status, Fine

---

### 6.5 SHARED PAGES (All Roles)

---

**Page: Group Messages / Chat**
- Template: `main_app/messages.html`
- URL: `/messages/` or `/messages/group/<int:group_id>/`
- View: `messaging_views.messages_home`
- Context: `threads` (ChatThread objects accessible to user), `active_thread`, `messages`
- Layout: thread list sidebar + chat message area
- Features: send message (POST), attach file, image preview, unread count
- Role filtering: admins see all group threads, teachers see own group threads, students see enrolled group threads

---

**Page: Profile Hub**
- Template: `main_app/profile_hub.html`
- URL: `/profile/`
- Route name: `profile_hub`
- View: `views.profile_settings_hub`
- CSS: `profile-hub.css`
- JS: `profile-hub.js`
- Features:
  - Avatar picker (24 emoji avatars) — saves via AJAX POST `/profile/save-avatar/`
  - Personal info form: first_name, last_name, phone, address, date_of_birth
  - Change password form
  - Theme selector: Dark / Light / System
  - Read-only: email, login_id

---

**Page: Payment Receipt**
- Template: `main_app/payment_receipt.html`
- URL: `/payments/receipt/<int:payment_id>/`
- Context: Payment object with invoice + student details
- Print-friendly layout

---

**Page: Error Page**
- Template: `main_app/error.html`
- Used for 400, 403, 404, 500 errors
- Shows ICEBERG branding + error message

---

## Section 7: Button / Action Inventory

### Login Page
| Button | Action |
|--------|--------|
| "Sign In" button | POST `/doLogin/` |
| "Forgot password?" link | GET `/password-reset/` |

### Admin Dashboard
| Button | Action |
|--------|--------|
| "Add Student" (hero) | GET `/student/add/` |
| "Manage Groups" (hero) | GET `/group/manage/` |
| "Profile Settings" (hero) | GET `/profile/` |
| Metric cards (4) | Each links to relevant manage page |
| Quick Action: Add Student | GET `/student/add/` |
| Quick Action: Add Teacher | GET `/staff/add` |
| Quick Action: Add Program | GET `/course/add` |
| Quick Action: Add Group | GET `/group/add/` |
| Quick Action: Enroll Student | GET `/enrollment/add/` |
| Quick Action: Attendance | GET `/attendance/view/` |
| Quick Action: Group Messages | GET `/messages/` |
| Quick Action: Teacher Feedback | GET `/staff/view/feedback/` |
| Recent student rows | GET `/student/edit/{id}` |
| Faculty rows | GET `/staff/edit/{id}` |
| "All leads" link | GET `/admin/registration-leads/` |

### Manage Pages (generic pattern)
| Button | Action |
|--------|--------|
| "Add [Entity]" | GET `/[entity]/add/` |
| "Edit" (row) | GET `/[entity]/edit/{id}` |
| "Delete" (row) | POST `/[entity]/delete/{id}` (with confirm dialog) |
| "Archive Group" | POST `/group/archive/{id}` |
| "Toggle Active" (course) | POST `/course/toggle-active/{id}` |

### Attendance (Staff)
| Button | Action |
|--------|--------|
| Group selector | AJAX GET `/staff/get_students/?group_id=X` |
| Present button per student | JS: sets status=1 |
| Late button per student | JS: sets status=2 |
| Absent button per student | JS: sets status=0 |
| "Save Attendance" | AJAX POST `/staff/attendance/save/` |
| "Update Attendance" | AJAX POST `/staff/attendance/update_save/` |

### Leave (Student)
| Button | Action |
|--------|--------|
| "Submit" (leave form) | POST `/student/apply/leave/` |

### Leave (Admin review)
| Button | Action |
|--------|--------|
| "Approve" | POST (inline) with status=1 |
| "Reject" | POST (inline) with status=-1 |

### Vocabulary
| Button | Action |
|--------|--------|
| "Mark Complete" | POST `/student/vocabulary-days/{id}/complete/` |
| "Flashcards" | GET `/student/vocabulary-days/{id}/flashcard/` |
| "Quiz" | GET `/student/vocabulary-days/{id}/quiz/` |
| "Submit Quiz" | POST `/student/vocabulary-days/{id}/quiz/save/` |
| "Add Vocabulary Day" (staff) | GET `/staff/vocabulary-days/add/` |
| "Delete Word" (staff detail) | POST (inline) |

### Payments
| Button | Action |
|--------|--------|
| "Generate Invoices" | GET/POST `/admin/payments/generate/` |
| "Record Payment" | GET `/admin/payments/invoice/{id}/record/` |
| "Cancel Invoice" | POST `/admin/payments/invoice/{id}/cancel/` |
| "Send Reminder" | POST `/admin/payments/invoice/{id}/remind/` |
| "Void Payment" | POST `/admin/payments/payment/{id}/void/` |
| "Download Receipt" | GET `/payments/receipt/{id}/` |
| "Export CSV" | GET `/admin/payments/?export=csv` |

### Messages
| Button | Action |
|--------|--------|
| Thread select | GET `/messages/group/{id}/` |
| "Send" | POST (AJAX or form) with body/attachment |
| Attachment button | File input, triggers upload |

### Profile Hub
| Button | Action |
|--------|--------|
| Avatar emoji click | AJAX POST `/profile/save-avatar/` with `{avatar: N}` |
| "Save Profile" | POST `/profile/` |
| "Change Password" | POST `/profile/` (different field set) |
| Theme toggle | POST `student_save_theme` or JS localStorage |
| "Sign Out" (animated) | POST `/logout_user/` (animated then submits) |

---

## Section 8: User Journey Maps

### 8.1 Admin User Journey

```
Login (/)
  → POST /doLogin/ → admin home (/admin/home/)
  
Admin Home
  → Quick Actions → any manage page
  → Sidebar → any admin section
  → Bottom Nav (mobile): Home | People | Chat | Profile

People Management Loop:
  /student/manage/ → [Edit|Delete]
                   → /student/add/ → form → save → /student/manage/
  /staff/manage/   → [Edit|Delete]
                   → /staff/add  → form → save → /staff/manage/
  /admin/manage/   → [Edit|Delete|Branch Access]
                   → /admin/add/ → form → save → /admin/manage/

Academic Management Loop:
  /group/manage/ → [Edit|Archive|Delete|View Students]
                → /group/add/ → AJAX course→teacher → form → save
  /enrollment/manage/ → /enrollment/add/ → AJAX chain → save
  /course/manage/ → /course/add/ | /course/edit/{id}
  /branch/manage/ → /branch/add/ | /branch/edit/{id}
  /attendance/view/ → Select group → AJAX → view attendance table

Finance:
  /admin/payments/ → CSV export | /admin/payments/generate/ | record | cancel | remind

Communication:
  /messages/ → select thread → read/send
  /admin/registration-leads/ → update status
  /student/view/feedback/ → reply
  /student/view/leave/ → approve/reject

Content:
  /admin/stories/ → add/edit/delete
  /admin/vocabulary-days/ → view (read-only)
  /admin/leaderboard/settings/ → update weights
  /admin/leaderboard/seasons/ → manage seasons

Profile:
  /profile/ → avatar, name, password, theme
  
Logout: POST /logout_user/ → /login/
```

### 8.2 Staff User Journey

```
Login (/)
  → POST /doLogin/ → staff home (/staff/home/)

Staff Home
  → Quick Actions: Take Attendance, Update Attendance, Add Results, Edit Results, Apply Leave, Feedback, Messages, Profile
  → Sidebar → all staff sections
  → Bottom Nav (mobile): Home | Attendance | Scores | Profile

Teaching Loop:
  /staff/attendance/take/
    → select group (own only) → select date
    → AJAX /staff/get_students/ → mark P/L/A
    → AJAX POST /staff/attendance/save/
  
  /staff/attendance/update/
    → select group + date → AJAX load existing
    → edit → AJAX POST /staff/attendance/update_save/
  
  /staff/result/add/
    → select course → AJAX teachers → select group
    → select student → enter test (0-40) + exam (0-60)
    → POST save
  
  /staff/result/edit/
    → same selectors → AJAX fetch existing → edit

Result Files:
  /staff/result/files/ → /staff/result/upload-file/ → form → save
  
Vocabulary:
  /staff/vocabulary-days/ → /staff/vocabulary-days/add/ → form+words → save
  /staff/vocabulary-days/{id}/ → add/remove words → edit

Assignments:
  /staff/assignments/ → /staff/assignment/add/ → form → save
  /staff/assignment/{id}/submissions/ → grade submissions

Library:
  /staff/addbook/ → form → save (Book record)
  /staff/issue_book/ → form → Loan record
  /staff/view_issued_book/ → /staff/return_book/{id}/

Communication:
  /messages/ → group chat (own groups)
  /staff/view/notification/ → read notifications

Requests:
  /staff/apply/leave/ → form → POST → history table
  /staff/feedback/ → form → POST → history table

Profile:
  /profile/ → same as admin profile hub

Logout: POST /logout_user/
```

### 8.3 Student User Journey

```
Login (/)
  → POST /doLogin/ → student home (/student/home/)

Student Home
  → Stories strip (horizontal scroll)
  → Rank badge (links to leaderboard)
  → KPI cards: Groups, Attendance %, Score, Streak
  → Quick Actions: Vocabulary, Attendance, Results, Progress, Assignments, Payments, Leave, Library
  → Recent assignments list
  → Notification strip
  → Bottom Nav (mobile): Home | Attendance | Results | Profile

Study Journey:
  /student/vocabulary-days/ → vocabulary_day_detail → flashcard | quiz
  /student/view/attendance/ → per-group calendar view
  /student/view/result/ → scores table
  /student/result/files/ → download files
  /student/progress/ → trend charts
  /student/leaderboard/ → rank table (filter scope/time)
  /student/assignments/ → /student/assignment/{id}/submit/
  /student/viewbooks/ → active loans

Finance:
  /student/payments/ → invoice cards + payment history
  /payments/receipt/{id}/ → print receipt

Communication:
  /messages/ → enrolled group chats
  /student/view/notification/ → notification list
  
Requests:
  /student/apply/leave/ → form → history
  /student/feedback/ → form → replies

Profile:
  /profile/ → avatar, name, password, theme

Logout: POST /logout_user/
```

---

## Section 9: Backend Connection Map

### URL → View → Template → Models

| URL Pattern | View | Template | Key Models |
|-------------|------|----------|------------|
| `GET /` | `views.login_page` | `login.html` | CustomUser |
| `POST /doLogin/` | `views.doLogin` | — (redirect) | CustomUser |
| `GET /admin/home/` | `hod_views.admin_home` | `home_content.html` | Student, Staff, Group, Attendance, AttendanceReport, Assignment, RegistrationLead |
| `GET /student/manage/` | `hod_views.manage_student` | `manage_student.html` | Student, Branch |
| `GET /student/add/` | `hod_views.add_student` | `add_student_template.html` | Course, Branch |
| `POST /student/add/` | `hod_views.add_student` | — (redirect) | CustomUser, Student |
| `GET /student/edit/{id}` | `hod_views.edit_student` | `edit_student_template.html` | Student, Course, Branch |
| `POST /student/edit/{id}` | `hod_views.edit_student` | — | CustomUser, Student |
| `POST /student/delete/{id}` | `hod_views.delete_student` | — | CustomUser, Student |
| `GET /staff/manage/` | `hod_views.manage_staff` | `manage_staff.html` | Staff, Branch |
| `GET /staff/add` | `hod_views.add_staff` | `add_staff_template.html` | Course, Branch |
| `GET /group/manage/` | `hod_views.manage_group` | `manage_group.html` | Group, Branch, Course, Staff |
| `GET /group/add/` | `hod_views.add_group` | `add_group.html` | Group, Course, Staff, Branch |
| `GET /branch/manage/` | `hod_views.manage_branch` | `manage_branch.html` | Branch, Admin |
| `GET /attendance/view/` | `hod_views.admin_view_attendance` | `admin_view_attendance.html` | Group, Attendance, AttendanceReport |
| `GET /attendance/fetch/` | `hod_views.get_admin_attendance` | JSON response | AttendanceReport |
| `GET /admin/payments/` | `payments_views.admin_payments` | `manage_payments.html` | Invoice, Payment, Student, Group |
| `GET /messages/` | `messaging_views.messages_home` | `messages.html` | ChatThread, ChatMessage, ChatReadState |
| `GET /profile/` | `views.profile_settings_hub` | `profile_hub.html` | CustomUser, Student/Staff/Admin |
| `GET /staff/home/` | `staff_views.staff_home` | `erpnext_staff_home.html` | Staff, Group, Attendance, LeaveReportStaff |
| `GET /staff/attendance/take/` | `staff_views.staff_take_attendance` | `staff_take_attendance.html` | Group, Student, Enrollment |
| `POST /staff/attendance/save/` | `staff_views.save_attendance` | JSON response | Attendance, AttendanceReport |
| `GET /staff/result/add/` | `staff_views.staff_add_result` | `staff_add_result.html` | Course, Staff, Group, Student |
| `GET /student/home/` | `student_views.student_home` | `erpnext_student_home.html` | Student, Group, Attendance, StudentResult, VocabularyDay, Assignment, DashboardStory, Notification, LeaderboardSnapshot |
| `GET /student/view/attendance/` | `student_views.student_view_attendance` | `student_view_attendance.html` | AttendanceReport, Attendance, Group |
| `GET /student/vocabulary-days/` | `student_views.vocabulary_day_list` | `vocabulary_day_list.html` | VocabularyDay, VocabularyDayCompletion |
| `GET /student/vocabulary-days/{id}/` | `student_views.vocabulary_day_detail` | `vocabulary_day_detail.html` | VocabularyDay, VocabularyDayWord |
| `GET /student/vocabulary-days/{id}/flashcard/` | `student_views.vocabulary_day_flashcard` | `vocabulary_day_flashcard.html` | VocabularyDay, VocabularyDayWord |
| `POST /student/vocabulary-days/{id}/quiz/save/` | `student_views.save_quiz_result` | JSON | VocabularyQuizResult |
| `GET /student/leaderboard/` | `student_views.student_leaderboard` | `leaderboard.html` | Student, AttendanceReport, StudentResult, Submission, VocabularyQuizResult, LeaderboardSettings |
| `GET /student/progress/` | `student_views.student_progress` | `student_progress.html` | AttendanceReport, StudentResult, Submission, VocabularyQuizResult |

---

## Section 10: API Endpoints

### REST API (prefix: `/api/v1/`)

**Auth:**
- `POST /api/v1/auth/login/` — JWT login (returns access_token + refresh_token)
- `POST /api/v1/auth/logout/` — logout
- `POST /api/v1/auth/token/refresh/` — refresh JWT token

**Profile:**
- `GET /api/v1/me/` — own user info
- `POST /api/v1/me/change-password/` — change password
- `POST /api/v1/me/fcm-token/` — save FCM token

**Core data:**
- `GET /api/v1/courses/` — list courses
- `GET /api/v1/groups/` — list groups (filtered by role)
- `GET /api/v1/groups/{pk}/` — group detail with students
- `GET/POST /api/v1/attendance/` — attendance (student: own, staff: own groups)
- `GET /api/v1/results/` — results (student: own)
- `GET/POST /api/v1/assignments/` — assignments
- `GET/PATCH /api/v1/assignments/{pk}/` — assignment detail
- `POST /api/v1/assignments/{pk}/submit/` — submit file
- `GET /api/v1/notifications/` — notifications
- `POST /api/v1/notifications/mark-all-read/` — mark all read
- `PATCH /api/v1/notifications/{pk}/read/` — mark one read
- `GET/POST /api/v1/leave/` — leave requests
- `GET/PATCH /api/v1/leave/{pk}/` — leave detail
- `GET/POST /api/v1/feedback/` — feedback
- `GET/PATCH /api/v1/feedback/{pk}/` — feedback detail
- `GET /api/v1/invoices/` — invoices (student: own, admin: all scoped)
- `GET /api/v1/invoices/{pk}/` — invoice detail

**Dashboards:**
- `GET /api/v1/student/home/` — student dashboard data
- `GET /api/v1/admin/home/` — admin dashboard data
- `GET /api/v1/stats/` — staff/admin stats

**Admin management:**
- `GET /api/v1/admin/stats/` — admin KPIs
- `GET /api/v1/admin/users/` — user list
- `GET /api/v1/admin/groups/` — all groups
- `GET/POST /api/v1/admin/enroll/` — enrollments
- `GET/POST /api/v1/admin/students/` — student list + create
- `GET/PATCH/DELETE /api/v1/admin/students/{pk}/` — student detail
- `GET/POST /api/v1/admin/staff/` — staff list + create
- `GET/PATCH/DELETE /api/v1/admin/staff/{pk}/` — staff detail
- `GET /api/v1/admin/leads/` — registration leads
- `GET/PATCH /api/v1/admin/leads/{pk}/` — lead detail
- `GET /api/v1/admin/branches/` — branches (read-only)

**Admin CRUD (admin_views.py):**
- `GET/POST /api/v1/admin/branches-manage/` — branch CRUD
- `GET/PATCH/DELETE /api/v1/admin/branches-manage/{pk}/` — branch detail
- `GET/POST /api/v1/admin/courses/` — course CRUD
- `GET/PATCH/DELETE /api/v1/admin/courses/{pk}/`
- `GET/POST /api/v1/admin/sessions/` — session CRUD
- `GET/PATCH/DELETE /api/v1/admin/sessions/{pk}/`
- `GET/POST /api/v1/admin/subjects/` — subject CRUD
- `GET/PATCH/DELETE /api/v1/admin/subjects/{pk}/`
- `GET /api/v1/admin/groups/{pk}/` — group with enrolled students
- `GET/POST /api/v1/admin/enrollments/` — enroll/unenroll
- `GET /api/v1/admin/leave-requests/` — all leave (student+staff)
- `PATCH /api/v1/admin/leave-requests/{pk}/` — approve/reject
- `GET /api/v1/admin/attendance-report/` — attendance report
- `GET/POST /api/v1/admin/stories/` — story CRUD
- `GET/PATCH/DELETE /api/v1/admin/stories/{pk}/`
- `POST /api/v1/admin/send-notification/` — push notification
- `GET /api/v1/admin/invoices-manage/` — invoice list
- `POST /api/v1/admin/invoices-manage/{pk}/pay/` — record payment

**Vocabulary:**
- `GET /api/v1/vocabulary/` — released vocab days (student only)
- `GET /api/v1/vocabulary/{pk}/` — vocab day detail with words
- `POST /api/v1/vocabulary/{pk}/complete/` — mark complete
- `GET /api/v1/vocabulary/{pk}/quiz/` — quiz questions
- `POST /api/v1/vocabulary/{pk}/quiz-result/` — save result

**Staff vocabulary:**
- `GET /api/v1/staff/vocabulary/` — own vocab days
- `POST /api/v1/staff/vocabulary/create/` — create vocab day
- `GET/PATCH/DELETE /api/v1/staff/vocabulary/{pk}/` — edit vocab day
- `GET/POST /api/v1/staff/vocabulary/{pk}/words/` — manage words
- `DELETE /api/v1/staff/vocabulary/{pk}/words/{word_pk}/` — delete word

**Other:**
- `GET /api/v1/student/progress/` — progress data
- `GET /api/v1/stories/` — active stories
- `POST /api/v1/stories/create/` — create story (staff)
- `GET /api/v1/stories/{pk}/` — story detail
- `GET /api/v1/leaderboard/` — leaderboard rankings
- `POST /api/v1/upload/` — file upload

---

## Section 11: Authentication & Permissions

**Login flow:**
1. User POSTs `identifier` (email or login_id) + `password` to `/doLogin/`
2. `views.doLogin` tries `authenticate(request, username=identifier, password=password)` via `EmailBackend`
3. `EmailBackend` resolves: if `@` in identifier → lookup by email; else lookup by login_id
4. On success: `login(request, user)`; redirect based on `user_type`
5. On failure: redirect to `/login/?error=Invalid credentials`

**Role decorators:**
```python
@admin_only   # user_type == '1'
@staff_only   # user_type == '2'
@student_only # user_type == '3'
```
Wrong-role users are redirected to their own home page (not 403).

**Branch filtering:**
- `branching.filter_students_for_user(user, qs)` — super admins get all; branch admins get students in their branches
- `branching.filter_staff_for_user(user, qs)` — same
- `branching.filter_groups_for_user(user, qs)` — same
- `branching.get_accessible_branches(user)` — returns Branch queryset

**JWT API permissions:**
- `api/permissions.py` has `IsAdmin`, `IsStaff`, `IsStudent` permission classes
- All API views require `IsAuthenticated` minimum
- Role-specific views add role permission class
- Branch scoping re-applied in API views

---

## Section 12: Known Problems & Bugs

### 🐛 Bugs

1. **`pieChart` / `barChart` naming mismatch** — Admin home uses `pieChart` IDs for what are actually line charts. Minor, non-breaking.

2. **Missing `edit_group.html` template** — the URL `/group/edit/{group_id}` is registered but there is no separate edit_group.html in the template list. Likely reuses `add_group.html` with a context variable (verify).

3. **Staff view profile** (`/staff/view/profile/`) is mostly read-only but the profile hub (`/profile/`) is where edits happen. The sidebar links both, which can be confusing.

4. **Vocabulary `release_scope=all`** — when a VocabularyDay has scope=all, students outside the teacher's group can see it. The query in `vocabulary_day_list` must handle this correctly (verify edge cases).

5. **Admin `check_email_availability` endpoint** (`/check_email_availability`) — appears to be AJAX only, no template. Used in add_admin form (verify).

6. **Registration leads** — the `full_name` field is populated by `_first_value()` from the raw payload, but if only `first_name`/`last_name` are sent, `full_name` may be empty. Template must handle empty `full_name`.

7. **Branch admin cannot delete students from other branches** — verified in `delete_student` view via `branching.filter_students_for_user`. ✅

8. **get_attendance returns 403 for cross-branch groups** — verified in `get_admin_attendance` with branch check. ✅

### ⚠️ Needs Verification

- `edit_group.html` template existence (listed in URLs but not in template tree above)
- IDOR in `edit_student`: does the view verify the student belongs to admin's branch before allowing edit?
- IDOR in `upload_result_file`: does it verify the group belongs to the teacher?
- Chat: can a student read messages from a group they're not enrolled in by passing a group_id?

---

## Section 13: Features That Must Be Preserved in Flutter

1. **Role-based navigation** — completely separate nav for admin/staff/student
2. **Branch scoping** — admin sees only own branch; super admin sees all
3. **Attendance workflow** — select group → date → per-student P/L/A toggle → save
4. **Result grading** — test (0-40) + exam (0-60) = total (0-100)
5. **Vocabulary day system** — list → detail → flashcard → quiz → save result
6. **Leaderboard** — scope filters (group/branch/all), time filters, badges
7. **Story strip** — horizontal scroll, emoji fallback, group targeting
8. **Chat/Messages** — per-group threads with file attachments
9. **Leave request flow** — submit → admin sees → approve/reject → notification
10. **Feedback with replies** — student/staff submit; admin replies shown
11. **Payments** — invoice list, paid/balance, receipt download, UZS formatting
12. **Profile hub** — avatar picker (24 emoji), theme toggle, password change
13. **Login ID generation** — auto `IC`/`TC` + MMDD + NN format
14. **Dark mode** — theme stored per user, affects charts and CSS variables
15. **Push notifications** — FCM integration for attendance, vocab, payments
16. **Progress charts** — attendance trend, score trend, quiz history
17. **Assignment submission** — file upload, note, due date display
18. **Library** — loan tracking, overdue fine (₹5/day per day overdue)
19. **Registration leads** — intake form (public), status management (admin)
20. **Notification categories** — attendance, result, announcement, homework, vocabulary, payment, general
