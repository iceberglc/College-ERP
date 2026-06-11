# FLUTTER APP MIGRATION PLAN
## Iceberg College ERP — Flutter Web Frontend

**Author:** Claude (Senior Flutter Architect)  
**Date:** 2026-06-11  
**Branch:** `claude/review-codebase-MWWNv`  
**Source analysis:** `FRONTEND_DEEP_ANALYSIS.md`  
**Flutter app location:** `/home/user/iceberg_app/`  
**Django backend:** `/home/user/College-ERP/`

---

## Table of Contents

1. [App Purpose & Target Users](#1-app-purpose--target-users)
2. [Required Roles](#2-required-roles)
3. [Authentication Flow](#3-authentication-flow)
4. [Navigation Structure](#4-navigation-structure)
5. [Complete Flutter Screen List](#5-complete-flutter-screen-list)
   - [5.1 Shared / Public](#51-shared--public-screens)
   - [5.2 Student Screens](#52-student-screens)
   - [5.3 Staff Screens](#53-staff-screens)
   - [5.4 Admin Screens](#54-admin-screens)
   - [5.5 Superadmin Screens](#55-superadmin-screens)
6. [Role-Based Routing](#6-role-based-routing)
7. [Backend API Requirements](#7-backend-api-requirements)
   - [7.1 Existing Endpoints (Reusable)](#71-existing-endpoints-reusable)
   - [7.2 New Endpoints Needed](#72-new-endpoints-needed)
8. [Dart Data Models](#8-dart-data-models)
9. [State Management Plan](#9-state-management-plan)
10. [Folder Structure](#10-folder-structure)
11. [UI Design System](#11-ui-design-system)
12. [Mobile-First Design Rules](#12-mobile-first-design-rules)
13. [Tablet & Desktop Adaptation](#13-tablet--desktop-adaptation)
14. [Error / Loading / Empty States](#14-error--loading--empty-states)
15. [Charts & Analytics Plan](#15-charts--analytics-plan)
16. [Forms & Validation Plan](#16-forms--validation-plan)
17. [File & Image Upload Plan](#17-file--image-upload-plan)
18. [Security & Permission Requirements](#18-security--permission-requirements)
19. [Migration Stages](#19-migration-stages)
20. [Testing Plan](#20-testing-plan)
21. [Risks & Things to Double-Check](#21-risks--things-to-double-check)

---

## 1. App Purpose & Target Users

**What the app is:**  
ICEBERG Study Center ERP — a Flutter Web (and future mobile) frontend for a college/language-school management system in Uzbekistan. Students are primarily English-language learners. The system replaces a Django HTML frontend.

**Target users:**
- **Students** — English-language learners; primarily mobile (smartphone) users; ages 16–30; Uzbek-speaking with English being learned
- **Staff / Teachers** — language teachers; moderate tech literacy; use daily for attendance, results, vocabulary management
- **Branch Admins (HODs)** — branch managers; use desktop or tablet; moderate to high frequency
- **Super Admins** — IT managers / owners; full system access; infrequent use; desktop-preferred

**Languages / locale:**  
- UI in English (teacher-facing, student-facing), with Uzbek data (names, addresses)
- Currency: Uzbek soʻm (UZS) — format with space thousands separator, no decimals e.g. `450 000 so'm`
- Date format: `DD MMM YYYY` (e.g., `11 Jun 2026`)

**Platforms:**  
- Primary: Web (Flutter Web, CanvasKit renderer)
- Secondary: Android APK (same codebase)
- Future: iOS

---

## 2. Required Roles

| Django `user_type` | Flutter role name | Login method | Redirect path |
|---|---|---|---|
| `"1"` | Admin / HOD | email + password | `/admin/home` |
| `"1"` + `is_super_admin=True` | Superadmin | email + password | `/superadmin/home` |
| `"2"` | Staff / Teacher | `TC{MMDD}{NN}` + password | `/staff/home` |
| `"3"` | Student | `IC{MMDD}{NN}` + password | `/student/home` |

**Role detection in Flutter:**
```dart
// From /api/v1/me/ response:
bool isSuperAdmin = user.userType == '1' && user.isSuperAdmin == true;
bool isAdmin   = user.userType == '1' && !isSuperAdmin;
bool isStaff   = user.userType == '2';
bool isStudent = user.userType == '3';
```

---

## 3. Authentication Flow

### 3.1 Login
1. User enters `identifier` (email or login_id) + password on `LoginScreen`
2. Flutter POSTs to `POST /api/v1/auth/login/` with `{"identifier": "...", "password": "..."}`
3. Backend returns `{"access": "...", "refresh": "..."}`
4. Flutter stores tokens in `flutter_secure_storage` (web: `localStorage` fallback)
5. Dio interceptor injects `Authorization: Bearer <access>` on every request
6. On 401, interceptor calls `POST /api/v1/auth/token/refresh/` with refresh token
7. On refresh failure, clear tokens and redirect to `/login`
8. App calls `GET /api/v1/me/` to get user profile and determine role
9. GoRouter `redirect` sends user to role home page

### 3.2 Token Storage
```dart
// Tokens stored with flutter_secure_storage
await _storage.write(key: 'access_token', value: access);
await _storage.write(key: 'refresh_token', value: refresh);
```

### 3.3 Logout
- DELETE stored tokens
- Call `POST /api/v1/auth/logout/` (best-effort)
- GoRouter redirect fires → `/login`

### 3.4 Forgot Password (Phase 2)
- `POST /api/v1/auth/password-reset/` → backend sends OTP to email
- `POST /api/v1/auth/password-reset/verify/` → submit OTP code
- `POST /api/v1/auth/password-reset/confirm/` → new password

> **⚠️ Needs verification:** Forgot password REST endpoints do not yet exist in the API. Django has template-based password reset at `/password-reset/`. REST equivalents must be added (see Section 7.2).

---

## 4. Navigation Structure

### 4.1 Shell Tabs per Role

**Student Shell** (bottom nav, 4 tabs):
```
[Home]  [Vocabulary]  [Progress]  [More]
```

**Staff Shell** (bottom nav, 4 tabs):
```
[Home]  [Classes]  [Vocabulary]  [More]
```

**Admin Shell** (bottom nav OR sidebar on tablet/desktop, 4 tabs):
```
[Home]  [Students]  [Groups]  [More]
```

**Superadmin Shell** (sidebar on desktop, bottom nav on mobile, 4 tabs):
```
[Home]  [Branches]  [Analytics]  [More]
```

### 4.2 "More" Drawer / Screen

Each role's "More" screen is a list screen with deep links to standalone routes (non-shell screens pushed as pages).

### 4.3 Adaptive Layout

- **Mobile (< 600px):** Bottom nav bar, full-screen pages, drawer-less
- **Tablet (600–1200px):** Left rail nav (mini icons + labels), slightly wider cards
- **Desktop (> 1200px):** Full sidebar (expanded), two-column layouts, data tables

Implementation: `adaptive_shell.dart` detects `MediaQuery.of(context).size.width` and switches layout.

---

## 5. Complete Flutter Screen List

For each screen: **Status** is one of:
- ✅ **BUILT** — screen file exists, API connected
- 🔧 **STUB** — screen file exists as placeholder
- ❌ **MISSING** — not yet built

---

### 5.1 Shared / Public Screens

---

**Screen: Splash**
- File: inline in `app_router.dart` (`_SplashScreen`)
- Status: ✅ BUILT
- Role: All (before auth check)
- Purpose: Show logo while auth state loads
- Django equivalent: N/A
- API: none (reads local token)
- Behavior: After 1–2 seconds, GoRouter redirect fires based on auth state
- Improvements: Add iceberg wave animation

---

**Screen: Login**
- File: `lib/features/auth/screens/login_screen.dart`
- Status: ✅ BUILT
- Role: Public (unauthenticated)
- Purpose: Authenticate user, get JWT tokens
- Django equivalent: `main_app/login.html`
- API: `POST /api/v1/auth/login/`
- Fields: `identifier` (email or login_id), `password`, show/hide password toggle
- Behavior: On success → GET /me/ → redirect to role home; on failure → show inline error
- UI components: Logo, card with field inputs, submit button, "Forgot password?" link
- Important behavior: The field label should say "Email or Login ID" — not "username"
- Improvements: Remember me checkbox (stores token longer), biometric unlock (Phase 3)

---

**Screen: Forgot Password**
- File: `lib/features/auth/screens/forgot_password_screen.dart`
- Status: ❌ MISSING
- Role: Public
- Purpose: Initiate password reset via email OTP
- Django equivalent: `registration/forgot_password.html`
- API: `POST /api/v1/auth/password-reset/` (needs to be built — see Section 7.2)
- Flow: Enter email → check inbox → enter 6-digit OTP → set new password

---

**Screen: Notifications (Shared)**
- File: `lib/shared/screens/notifications_screen.dart`
- Status: ✅ BUILT
- Role: Student, Staff, Admin
- Purpose: All notifications with mark-read
- Django equivalent: Notification model in sidebar
- API: `GET /api/v1/notifications/`, `POST /api/v1/notifications/mark-all-read/`, `PATCH /api/v1/notifications/{pk}/read/`
- UI components: List tiles, unread dot, category icon, timestamp, empty state
- Categories: attendance, result, announcement, homework, vocabulary, payment, general

---

**Screen: Messages (Chat)**
- File: `lib/shared/screens/messages_screen.dart`
- Status: ✅ BUILT
- Role: Student, Staff, Admin
- Purpose: WhatsApp-style chat per group thread
- Django equivalent: `main_app/chat.html` (group messaging)
- API: ⚠️ **MISSING** — no REST endpoint for chat exists yet. Django has only HTML view.
- Data needed: ChatThread list, ChatMessage list with pagination, unread count per thread
- Actions: Send text message, send file attachment, view thread
- UI components: Thread list view, message bubbles (own = right, others = left), file attachment preview, send field
- Important behavior: Students see only their enrolled group threads; teachers see all their groups; admins see all branch groups
- Security: Backend must verify user is member of thread before returning messages

---

**Screen: Profile Hub**
- File: `lib/shared/screens/profile_hub_screen.dart`
- Status: ✅ BUILT
- Role: Student, Staff, Admin
- Purpose: View/edit profile, change password, switch theme
- Django equivalent: `/profile/` (HOD), `/staff/view/profile/`, `/student/view/profile/`
- API: `GET /api/v1/me/`, `POST /api/v1/me/change-password/`
- Fields: Avatar (24 emoji picker), first name, last name, email (read-only), phone, address
- Theme toggle: light / dark
- Password section: current password, new password, confirm password
- Important behavior: Avatar choice should be saved to `Student.theme` or user profile; does not upload a real photo

---

### 5.2 Student Screens

---

**Screen: Student Home (Dashboard)**
- File: `lib/features/student/screens/student_home_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Personal dashboard — attendance rate, progress, upcoming vocab, stories, leaderboard preview
- Django equivalent: `student_template/home_content.html`
- API: `GET /api/v1/student/home/`
- Data needed:
  ```json
  {
    "student_name": "...",
    "course": "...",
    "attendance_rate": 87.5,
    "attendance_present": 21,
    "attendance_total": 24,
    "next_vocab": {"id": 5, "title": "Day 5", "word_count": 10},
    "recent_results": [{"subject": "...", "total": 85}],
    "stories": [...],
    "leaderboard_rank": 3,
    "assignments_due": [...],
    "balance_due": 150000
  }
  ```
- UI components: IceHeroCard (greeting), attendance ring chart, story strip (horizontal scroll), mini leaderboard, quick action buttons
- Actions: Tap story → story detail, tap vocab → vocab day, tap assignment → assignment detail

---

**Screen: Student Vocabulary List**
- File: `lib/features/student/screens/student_vocabulary_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Browse released vocabulary days
- Django equivalent: `student_template/vocabulary_list.html`
- API: `GET /api/v1/vocabulary/`
- Data: list of VocabularyDay objects (id, title, day_number, word_count, completed, quiz_score)
- UI: Card list, progress indicator per card, completion badge, locked/unlocked state
- Navigation: Tap card → `/student/vocabulary/:id`

---

**Screen: Student Vocabulary Day Detail**
- File: `lib/features/student/screens/student_vocabulary_detail_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Show word list for a vocab day, launch flashcards or quiz
- Django equivalent: `student_template/vocabulary_day.html`
- API: `GET /api/v1/vocabulary/{pk}/`
- Data: `{title, day_number, words: [{id, word, translation, example, image_url}]}`
- UI: Word cards (word + translation + example), action buttons (Study Flashcards, Take Quiz)
- Navigation: "Flashcards" → `/student/vocabulary/:id/flashcards`; "Quiz" → `/student/vocabulary/:id/quiz`

---

**Screen: Student Flashcard**
- File: `lib/features/student/screens/student_flashcard_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: 3D flip-card study mode for vocabulary words
- Django equivalent: No Django equivalent — enhancement
- API: `GET /api/v1/vocabulary/{pk}/` (same as detail)
- UI: Single card (front=word, back=translation+example), prev/next buttons, flip animation, progress bar (3/10), celebration confetti on last card
- Navigation: Completion → back to detail or → quiz

---

**Screen: Student Vocabulary Quiz**
- File: `lib/features/student/screens/student_vocabulary_quiz_screen.dart`
- Status: ✅ BUILT (verify quiz result submission)
- Role: Student
- Purpose: Multiple-choice quiz for a vocab day
- Django equivalent: `student_template/vocabulary_quiz.html`
- API: `GET /api/v1/vocabulary/{pk}/quiz/`, `POST /api/v1/vocabulary/{pk}/quiz-result/`
- Data GET: `{questions: [{word, options: [str], correct_index}]}`
- Data POST: `{score, total, answers: [int]}`
- UI: One question at a time, 4 options, immediate feedback (green/red), final score screen
- Important behavior: Quiz result saved; affects leaderboard score

---

**Screen: Student Attendance**
- File: `lib/features/student/screens/student_attendance_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: View own attendance per subject/month
- Django equivalent: `student_template/view_attendance.html`
- API: `GET /api/v1/attendance/`
- Data: `[{subject, date, status}]` or monthly summary
- UI: Calendar view OR table view with month filter, totals (Present / Absent / Leave), attendance percentage
- Important behavior: Student sees ONLY own attendance — enforced by backend `IsStudent` permission + owner filter

---

**Screen: Student Results**
- File: `lib/features/student/screens/student_results_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: View exam results per subject
- Django equivalent: `student_template/view_result.html`
- API: `GET /api/v1/results/`
- Data: `[{subject, test_score (0-40), exam_score (0-60), total (0-100), grade, teacher_comment}]`
- UI: Cards per subject, score breakdown bar, grade badge, result file download link
- Navigation: Result file download → `GET /api/v1/upload/{filename}` or `/student/result-files`

---

**Screen: Student Result Files**
- File: `lib/features/student/screens/student_result_files_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Browse and download uploaded result PDFs/files
- Django equivalent: No direct equivalent — uses file upload system
- API: `GET /api/v1/results/` (includes file URLs)
- UI: File list with icon by type (PDF/image/other), filename, date, download button

---

**Screen: Student Assignments**
- File: `lib/features/student/screens/student_assignments_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: View assignments, submit work
- Django equivalent: (No HTML equivalent — API-first feature)
- API: `GET /api/v1/assignments/`, `POST /api/v1/assignments/{pk}/submit/`
- Data: `[{id, title, due_date, description, submission_status, file_url}]`
- UI: Card list by due date, status badge (pending/submitted/graded), submit button, upload dialog
- Important behavior: Past-due assignments shown with overdue badge; after submission, show "submitted" state

---

**Screen: Student Leaderboard**
- File: `lib/features/student/screens/student_leaderboard_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Competitive ranking by quiz scores
- Django equivalent: `student_template/leaderboard.html`
- API: `GET /api/v1/leaderboard/`
- Data: `{rank, total, entries: [{rank, student_name, avatar_emoji, score, badge}]}`
- Scope filters: my group / branch / all students
- UI: Podium top-3, ranked list below, own rank highlighted, scope filter chips

---

**Screen: Student Progress**
- File: `lib/features/student/screens/student_progress_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Trend charts for attendance, quiz scores, vocabulary completion
- Django equivalent: No HTML equivalent — enhancement
- API: `GET /api/v1/student/progress/`
- Data: `{attendance_trend: [{month, rate}], quiz_history: [{date, score, total}], vocab_completion: [{day, completed}]}`
- UI: Three sparkline/line charts, completion percentage, streak count

---

**Screen: Student Payments**
- File: `lib/features/student/screens/student_payments_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: View invoices, paid amounts, outstanding balance
- Django equivalent: No student-facing HTML (admin only in Django)
- API: `GET /api/v1/invoices/`
- Data: `[{id, period, amount, discount, paid, balance, status, due_date}]`
- UI: Header with total balance, list of invoices per month, status badge (paid/partial/overdue), UZS formatting
- Important behavior: Student CANNOT pay or edit — read-only view; "pay via Payme" deep link (future)

---

**Screen: Student Leave**
- File: `lib/features/student/screens/student_leave_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Submit and view own leave requests
- Django equivalent: `student_template/leave_view.html` + leave apply form
- API: `GET /api/v1/leave/`, `POST /api/v1/leave/`
- Data POST: `{start_date, end_date, reason}`
- Data GET: `[{id, start_date, end_date, reason, status, admin_comment}]`
- UI: Leave history list (status: pending/approved/rejected), add button, modal form
- Status badges: pending=yellow, approved=green, rejected=red

---

**Screen: Student Feedback**
- File: `lib/features/student/screens/student_feedback_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Submit feedback and see admin replies
- Django equivalent: `student_template/student_feedback_template.html`
- API: `GET /api/v1/feedback/`, `POST /api/v1/feedback/`
- Data: `[{id, message, reply, replied_at, created_at}]`
- UI: Thread-style list (message + admin reply), send new feedback button, text field

---

**Screen: Student Notifications**
- File: `lib/features/student/screens/student_notifications_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Student-specific notifications view
- Note: May be replaced by shared `/notifications` route
- API: `GET /api/v1/notifications/`

---

**Screen: Student Books (Library)**
- File: `lib/features/student/screens/student_books_screen.dart`
- Status: ✅ BUILT (shows "coming soon" if API 404s)
- Role: Student
- Purpose: Library browser — view available books, own loans, overdue fines
- Django equivalent: `student_template/library.html` (if exists) — ⚠️ Needs verification
- API: No endpoint exists yet — needs `GET /api/v1/library/loans/`
- Data needed: `[{book_title, author, borrowed_date, due_date, return_date, fine_due}]`
- Fine logic: ₹5/day (or 5000 UZS/day) per day overdue — **Needs verification of currency**
- UI: Available books tab, my loans tab, overdue alert banner

---

**Screen: Student More**
- File: `lib/features/student/screens/student_more_screen.dart`
- Status: ✅ BUILT
- Role: Student
- Purpose: Overflow menu linking to secondary screens
- Links: Attendance, Results, Assignments, Payments, Leave, Feedback, Books, Result Files, Profile

---

### 5.3 Staff Screens

---

**Screen: Staff Home (Dashboard)**
- File: `lib/features/staff/screens/staff_home_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Teacher dashboard — today's groups, attendance summary, recent results
- Django equivalent: `staff_template/home_content.html`
- API: `GET /api/v1/stats/`
- Data needed:
  ```json
  {
    "total_students": 45,
    "groups": [...],
    "today_attendance": {"taken": 3, "total_groups": 4},
    "pending_results": 2,
    "pending_assignments": 5,
    "upcoming_vocab": [...]
  }
  ```
- UI: Stats cards, today's class schedule, quick actions (Take Attendance, Add Result)

---

**Screen: Staff Classes (Groups)**
- File: `lib/features/staff/screens/staff_classes_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: View own groups and their enrolled student lists
- Django equivalent: No direct equivalent — groups listed from `GET /api/v1/groups/`
- API: `GET /api/v1/groups/`
- Data: `[{id, name, course, room, schedule, enrolled_count}]`
- UI: Group cards, tap → `DraggableScrollableSheet` showing student list

---

**Screen: Staff Attendance**
- File: `lib/features/staff/screens/staff_attendance_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Take attendance for a group on a date
- Django equivalent: `staff_template/take_attendance.html`
- API: `GET /api/v1/groups/`, `GET /api/v1/attendance/?group=X&date=Y`, `POST /api/v1/attendance/`
- Data POST: `{group, date, records: [{student_id, status}]}` where status = P/A/L
- UI: Group dropdown → date picker → list of students with P/L/A toggle chips → submit
- Important behavior: Cannot mark attendance for another teacher's group (backend enforces this)

---

**Screen: Staff Update Attendance**
- File: `lib/features/staff/screens/staff_update_attendance_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Correct previously submitted attendance
- Django equivalent: No separate page — Django uses same form with edit mode
- API: `GET /api/v1/attendance/`, `PATCH /api/v1/attendance/` (or PUT per record)
- UI: Same as take attendance but pre-filled with existing records

---

**Screen: Staff Results**
- File: `lib/features/staff/screens/staff_results_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Add and edit student results
- Django equivalent: `staff_template/add_result_template.html`, `staff_template/edit_result_template.html`
- API: `GET /api/v1/results/?group=X`, `POST /api/v1/results/`, `PATCH /api/v1/results/{pk}/`
- Data POST: `{student, subject, test_score (0-40), exam_score (0-60)}`
- Important IDOR fix: Backend must verify the group/student belongs to the requesting teacher. This was explicitly flagged as a security requirement.
- UI: Group selector → student list → result entry form (test + exam fields, auto-calculates total)

---

**Screen: Staff Vocabulary List**
- File: `lib/features/staff/screens/staff_vocabulary_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Manage vocabulary days for own groups
- Django equivalent: `staff_template/vocabulary_list.html`
- API: `GET /api/v1/staff/vocabulary/`, `POST /api/v1/staff/vocabulary/create/`
- Data: `[{id, group_name, day_number, title, word_count, release_at, release_scope}]`
- UI: Cards per vocab day, "Create" FAB, status (scheduled/released)

---

**Screen: Staff Vocabulary Day Detail**
- File: `lib/features/staff/screens/staff_vocabulary_detail_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Edit vocab day, add/remove words
- Django equivalent: `staff_template/vocabulary_day_edit.html`
- API: `GET/PATCH/DELETE /api/v1/staff/vocabulary/{pk}/`, `GET/POST /api/v1/staff/vocabulary/{pk}/words/`, `DELETE /api/v1/staff/vocabulary/{pk}/words/{word_pk}/`
- Data word: `{word, translation, example, image_url (optional)}`
- UI: Title, release settings, word list (add inline), image upload per word

---

**Screen: Staff Assignments**
- File: `lib/features/staff/screens/staff_assignments_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Create assignments and review student submissions
- Django equivalent: (API-first feature)
- API: `GET/POST /api/v1/assignments/`, `GET/PATCH /api/v1/assignments/{pk}/`
- UI: Tab between "My Assignments" and "Submissions", create FAB, grade input per submission

---

**Screen: Staff Leave**
- File: `lib/features/staff/screens/staff_leave_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Submit and view own leave requests
- Django equivalent: `staff_template/leave_view.html`
- API: Same as student leave: `GET/POST /api/v1/leave/`
- UI: Same pattern as student leave screen

---

**Screen: Staff Feedback**
- File: `lib/features/staff/screens/staff_feedback_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Submit feedback to admin and see replies
- Django equivalent: `staff_template/staff_feedback_template.html`
- API: `GET/POST /api/v1/feedback/`

---

**Screen: Staff More**
- File: `lib/features/staff/screens/staff_more_screen.dart`
- Status: ✅ BUILT
- Role: Staff
- Purpose: Links to secondary screens
- Links: Attendance, Update Attendance, Results, Assignments, Leave, Feedback, Vocabulary, Profile

---

**Screen: Staff Notifications**
- File: `lib/features/staff/screens/staff_placeholder_screens.dart` → `StaffNotificationsScreen`
- Status: 🔧 STUB
- Role: Staff
- Purpose: Staff-specific notifications
- API: `GET /api/v1/notifications/`
- Note: Should reuse `NotificationsScreen` shared screen

---

**Screen: Staff Payments**
- File: `lib/features/staff/screens/staff_placeholder_screens.dart` → `StaffPaymentsScreen`
- Status: 🔧 STUB
- Role: Staff
- Purpose: View own salary / payment history — ⚠️ Needs verification of whether this feature exists in Django backend. No clear Staff→Invoice relationship in models.
- If not applicable: Remove from UI

---

### 5.4 Admin Screens

---

**Screen: Admin Home (Dashboard)**
- File: `lib/features/admin/screens/admin_home_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: Branch overview — KPI cards, recent activity, charts
- Django equivalent: `hod_template/home_content.html`
- API: `GET /api/v1/admin/home/` + `GET /api/v1/admin/stats/`
- Data needed: (see Section 6.2 of FRONTEND_DEEP_ANALYSIS.md for full context variable list)
- Charts: attendance trend (line), new students (line), branch performance (multi-line)
- UI: Hero section with branch name, 4–6 KPI cards, quick actions grid, charts, recent tables

---

**Screen: Admin Students List**
- File: `lib/features/admin/screens/admin_students_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View, search, add, edit, delete students
- Django equivalent: `hod_template/manage_student.html`
- API: `GET /api/v1/admin/students/`, `DELETE /api/v1/admin/students/{pk}/`
- Filters: branch (if superadmin), course, status
- Search: by name or login_id
- Actions per row: Edit → `/admin/students/:id/edit`, Delete (confirm dialog)
- IDOR guard: backend enforces branch scope — admin cannot delete students from other branches
- UI: Data table (desktop) or card list (mobile), search bar, filter chips, FAB to add

---

**Screen: Admin Add Student**
- File: `lib/features/admin/screens/admin_add_student_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: Create a new student account
- Django equivalent: `hod_template/add_student_template.html`
- API: `POST /api/v1/admin/students/`
- Fields: first_name, last_name, email, date_of_birth, gender, phone, address, course, branch, status, level, password
- Auto-generated: `login_id` (IC + MMDD + NN) — generated by backend, shown in success toast
- Validation: email uniqueness check, date_of_birth required, password min 8 chars

---

**Screen: Admin Edit Student**
- File: ❌ MISSING
- Role: Admin
- Purpose: Edit existing student
- Django equivalent: `hod_template/edit_student_template.html`
- API: `GET /api/v1/admin/students/{pk}/`, `PATCH /api/v1/admin/students/{pk}/`
- Fields: same as add, but pre-populated; login_id shown as read-only
- Route: `/admin/students/:id/edit`

---

**Screen: Admin Staff List**
- File: `lib/features/admin/screens/admin_staff_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View, search, add, edit, delete staff
- Django equivalent: `hod_template/manage_staff.html`
- API: `GET /api/v1/admin/staff/`, `DELETE /api/v1/admin/staff/{pk}/`
- UI: Same pattern as students list

---

**Screen: Admin Add Staff**
- File: `lib/features/admin/screens/admin_add_staff_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: Create a new teacher account
- Django equivalent: `hod_template/add_staff_template.html`
- API: `POST /api/v1/admin/staff/`
- Fields: first_name, last_name, email, date_of_birth, gender, phone, address, course, branch, specialization, is_active, password
- Auto-generated: `login_id` (TC + MMDD + NN)

---

**Screen: Admin Edit Staff**
- File: ❌ MISSING
- Role: Admin
- Purpose: Edit existing staff member
- Django equivalent: `hod_template/edit_staff_template.html`
- API: `GET /api/v1/admin/staff/{pk}/`, `PATCH /api/v1/admin/staff/{pk}/`
- Route: `/admin/staff/:id/edit`

---

**Screen: Admin Groups List**
- File: `lib/features/admin/screens/admin_groups_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View, add, edit, archive, delete groups
- Django equivalent: `hod_template/manage_group.html`
- API: `GET /api/v1/admin/groups/`, `POST /api/v1/admin/groups/` (needs endpoint — see 7.2)
- Columns: Name, Course, Teacher, Branch, Schedule, Capacity, Enrolled, Fee
- Actions: View students → `/admin/groups/:id`, Edit, Archive, Delete

---

**Screen: Admin Group Detail**
- File: ❌ MISSING
- Role: Admin
- Purpose: View enrolled students in a group
- Django equivalent: `hod_template/group_detail.html`
- API: `GET /api/v1/admin/groups/{pk}/` (admin_views.GroupDetailView — EXISTS)
- Data: `{group, students: [{name, login_id, status}]}`
- Actions: Remove enrollment, add enrollment
- Route: `/admin/groups/:id`

---

**Screen: Admin Add/Edit Group**
- File: ❌ MISSING
- Role: Admin
- Purpose: Create or edit a group with teacher assignment
- Django equivalent: `hod_template/add_group.html`
- API: `POST /api/v1/admin/groups/` (needs endpoint), `PATCH /api/v1/admin/groups/{pk}/` (needs endpoint)
- Fields: name, course, teacher (filtered by course+branch), branch, room, schedule, capacity, monthly_fee, start_date
- Note: Teacher list must be dynamically filtered by selected course
- Route: `/admin/groups/add`, `/admin/groups/:id/edit`

---

**Screen: Admin Courses**
- File: `lib/features/admin/screens/admin_courses_screen.dart`
- Status: ✅ BUILT (verify API connection)
- Role: Admin
- Purpose: CRUD for courses
- Django equivalent: `hod_template/manage_course.html`
- API: `GET/POST /api/v1/admin/courses/`, `PATCH/DELETE /api/v1/admin/courses/{pk}/`
- Fields: name, is_active, is_english, monthly_fee

---

**Screen: Admin Subjects**
- File: `lib/features/admin/screens/admin_subjects_screen.dart`
- Status: ✅ BUILT (verify API connection)
- Role: Admin
- Purpose: CRUD for subjects
- Django equivalent: `hod_template/manage_subject.html`
- API: `GET/POST /api/v1/admin/subjects/`, `PATCH/DELETE /api/v1/admin/subjects/{pk}/`
- Fields: name, course (FK), staff (FK)

---

**Screen: Admin Sessions**
- File: `lib/features/admin/screens/admin_sessions_screen.dart`
- Status: ✅ BUILT (verify API connection)
- Role: Admin
- Purpose: CRUD for academic sessions
- Django equivalent: `hod_template/manage_session.html`
- API: `GET/POST /api/v1/admin/sessions/`, `PATCH/DELETE /api/v1/admin/sessions/{pk}/`
- Fields: start_year, end_year

---

**Screen: Admin Branches**
- File: `lib/features/admin/screens/admin_branches_screen.dart`
- Status: ✅ BUILT (verify CRUD vs read-only)
- Role: Admin (full CRUD), Superadmin (full CRUD)
- Purpose: Manage physical branches
- Django equivalent: `hod_template/manage_branch.html`
- API: `GET/POST /api/v1/admin/branches-manage/`, `PATCH/DELETE /api/v1/admin/branches-manage/{pk}/`
- Fields: name, address

---

**Screen: Admin Enrollment**
- File: ❌ MISSING
- Role: Admin
- Purpose: Enroll students into groups
- Django equivalent: `hod_template/manage_enrollment.html`, `hod_template/add_enrollment.html`
- API: `GET/POST /api/v1/admin/enrollments/`
- Data: select group → select student → enroll; OR view/delete existing enrollments
- Route: `/admin/enrollment`

---

**Screen: Admin Leave Requests**
- File: `lib/features/admin/screens/admin_leave_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View and approve/reject all leave requests (student + staff)
- Django equivalent: `hod_template/manage_leave.html`
- API: `GET /api/v1/admin/leave-requests/`, `PATCH /api/v1/admin/leave-requests/{pk}/`
- Data PATCH: `{status: "approved"|"rejected", admin_comment: "..."}`
- UI: Tabbed (student / staff), status filter, approve/reject buttons per row

---

**Screen: Admin Attendance Report**
- File: `lib/features/admin/screens/admin_attendance_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View attendance report across groups
- Django equivalent: `hod_template/admin_view_attendance.html`
- API: `GET /api/v1/admin/attendance-report/?group={id}&month={YYYY-MM}`
- UI: Group selector, month picker, table (student × day), P/A/L cells color-coded

---

**Screen: Admin Payments / Invoices**
- File: `lib/features/admin/screens/admin_payments_screen.dart`
- Status: ✅ BUILT (verify data binding)
- Role: Admin
- Purpose: View invoices, record payments
- Django equivalent: `hod_template/manage_payments.html`
- API: `GET /api/v1/admin/invoices-manage/`, `POST /api/v1/admin/invoices-manage/{pk}/pay/`
- Data GET: `[{student, group, period, amount, discount, paid, balance, status, due_date}]`
- Data POST (pay): `{amount, method, note, paid_on}`
- Payment methods: cash, card, transfer, payme, click, uzum
- UI: Table with filters (period, group, status), "Record Payment" modal, UZS formatting, CSV export (future)

---

**Screen: Admin Stories**
- File: `lib/features/admin/screens/admin_stories_screen.dart`
- Status: ✅ BUILT (verify CRUD)
- Role: Admin
- Purpose: Create, edit, delete stories visible to students
- Django equivalent: `hod_template/manage_stories.html`, `hod_template/story_form.html`
- API: `GET/POST /api/v1/admin/stories/`, `PATCH/DELETE /api/v1/admin/stories/{pk}/`
- Fields: title, body, image (upload), story_type, emoji, bg_color, target_groups (multi), is_active, expires_at
- UI: Story card list, create FAB, story preview modal

---

**Screen: Admin Leads (Registration)**
- File: `lib/features/admin/screens/admin_leads_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: View and update registration leads / enquiries
- Django equivalent: `hod_template/manage_registration_leads.html`
- API: `GET /api/v1/admin/leads/`, `PATCH /api/v1/admin/leads/{pk}/`
- Data GET: `[{id, full_name, phone, email, program, branch, source, status, created_at}]`
- Status options: new, contacted, enrolled, dropped
- UI: Status filter chips (new / contacted / enrolled / dropped), table, inline status update

---

**Screen: Admin Send Notification**
- File: `lib/features/admin/screens/admin_notify_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: Push notification to group or all students
- Django equivalent: No direct HTML page — admin control
- API: `POST /api/v1/admin/send-notification/`
- Data: `{title, body, target: "all"|"group"|"branch", group_id?, branch_id?}`
- UI: Title field, body field, target selector, send button

---

**Screen: Admin Manage Admins**
- File: ❌ MISSING
- Role: Admin (super admin only)
- Purpose: View, add, edit, delete admin accounts
- Django equivalent: `hod_template/manage_admin.html`, `hod_template/add_admin_template.html`
- API: Needs new endpoint — `GET/POST /api/v1/admin/admins/`, `PATCH/DELETE /api/v1/admin/admins/{pk}/`
- Data: `[{email, first_name, last_name, is_super_admin, branches: [...]}]`
- Special rule: Cannot delete last super admin (enforced by `Admin.clean()`)
- Fields for create: first_name, last_name, email, password, is_super_admin, branches (multi-select)
- Route: `/admin/admins`

---

**Screen: Admin More**
- File: `lib/features/admin/screens/admin_more_screen.dart`
- Status: ✅ BUILT
- Role: Admin
- Purpose: Overflow menu for secondary screens
- Links: Courses, Subjects, Sessions, Branches, Enrollment, Stories, Admins, Send Notification, Attendance Report, Leave Requests, Payments, Profile

---

**Screen: Admin Placeholder Screens**
- File: `lib/features/admin/screens/admin_placeholder_screens.dart`
- Status: 🔧 STUB
- Contains: `AdminVocabularyAdminScreen`, `AdminEnrollmentScreen`
- Role: Admin

---

### 5.5 Superadmin Screens

---

**Screen: Superadmin Home**
- File: `lib/features/superadmin/screens/superadmin_home_screen.dart`
- Status: ✅ BUILT
- Role: Superadmin
- Purpose: System-wide KPIs across all branches
- Django equivalent: Same `hod_template/home_content.html` with super admin scope
- API: `GET /api/v1/admin/home/` (branch scope = all branches for superadmin)
- Charts: Multi-branch attendance comparison, total students per branch

---

**Screen: Superadmin Analytics**
- File: `lib/features/superadmin/screens/superadmin_placeholder_screens.dart` → `SuperadminAnalyticsScreen`
- Status: 🔧 STUB
- Role: Superadmin
- Purpose: Cross-branch analytics and reporting
- API: Needs new `GET /api/v1/superadmin/analytics/` endpoint

---

**Screen: Superadmin More**
- File: `lib/features/superadmin/screens/superadmin_placeholder_screens.dart` → `SuperadminMoreScreen`
- Status: 🔧 STUB
- Role: Superadmin
- Purpose: Superadmin settings and tools
- Links: Manage Admins, Branches, Analytics, Profile

---

## 6. Role-Based Routing

### 6.1 GoRouter Redirect Logic

```dart
redirect: (context, state) {
  final auth = ref.read(authProvider);
  final path = state.matchedLocation;

  if (auth.status == AuthStatus.loading) return '/splash';
  if (auth.status == AuthStatus.unauthenticated) {
    return path == '/login' ? null : '/login';
  }

  if (path == '/login' || path == '/splash') {
    final user = auth.user!;
    if (user.isSuperAdmin) return '/superadmin/home';
    if (user.isAdmin)      return '/admin/home';
    if (user.isStaff)      return '/staff/home';
    return '/student/home';
  }

  return null;
},
```

### 6.2 Complete Route Map

| Path | Screen | Role |
|------|--------|------|
| `/login` | LoginScreen | Public |
| `/splash` | _SplashScreen | All |
| `/student/home` | StudentHomeScreen | Student |
| `/student/vocabulary` | StudentVocabularyScreen | Student |
| `/student/vocabulary/:id` | StudentVocabularyDetailScreen | Student |
| `/student/vocabulary/:id/flashcards` | StudentFlashcardScreen | Student |
| `/student/vocabulary/:id/quiz` | StudentVocabularyQuizScreen | Student |
| `/student/progress` | StudentProgressScreen | Student |
| `/student/more` | StudentMoreScreen | Student |
| `/student/attendance` | StudentAttendanceScreen | Student |
| `/student/results` | StudentResultsScreen | Student |
| `/student/assignments` | StudentAssignmentsScreen | Student |
| `/student/leaderboard` | StudentLeaderboardScreen | Student |
| `/student/payments` | StudentPaymentsScreen | Student |
| `/student/leave` | StudentLeaveScreen | Student |
| `/student/feedback` | StudentFeedbackScreen | Student |
| `/student/notifications` | StudentNotificationsScreen | Student |
| `/student/books` | StudentBooksScreen | Student |
| `/student/result-files` | StudentResultFilesScreen | Student |
| `/student/profile` | ProfileHubScreen | Student |
| `/staff/home` | StaffHomeScreen | Staff |
| `/staff/classes` | StaffClassesScreen | Staff |
| `/staff/vocabulary` | StaffVocabularyScreen | Staff |
| `/staff/vocabulary/:id` | StaffVocabularyDetailScreen | Staff |
| `/staff/more` | StaffMoreScreen | Staff |
| `/staff/attendance` | StaffAttendanceScreen | Staff |
| `/staff/attendance/update` | StaffUpdateAttendanceScreen | Staff |
| `/staff/results` | StaffResultsScreen | Staff |
| `/staff/assignments` | StaffAssignmentsScreen | Staff |
| `/staff/leave` | StaffLeaveScreen | Staff |
| `/staff/feedback` | StaffFeedbackScreen | Staff |
| `/staff/profile` | ProfileHubScreen | Staff |
| `/admin/home` | AdminHomeScreen | Admin |
| `/admin/students` | AdminStudentsScreen | Admin |
| `/admin/students/:id/edit` | AdminEditStudentScreen ❌ | Admin |
| `/admin/staff` | AdminStaffScreen | Admin |
| `/admin/staff/:id/edit` | AdminEditStaffScreen ❌ | Admin |
| `/admin/groups` | AdminGroupsScreen | Admin |
| `/admin/groups/:id` | AdminGroupDetailScreen ❌ | Admin |
| `/admin/groups/add` | AdminAddGroupScreen ❌ | Admin |
| `/admin/groups/:id/edit` | AdminEditGroupScreen ❌ | Admin |
| `/admin/courses` | AdminCoursesScreen | Admin |
| `/admin/subjects` | AdminSubjectsScreen | Admin |
| `/admin/sessions` | AdminSessionsScreen | Admin |
| `/admin/branches` | AdminBranchesScreen | Admin |
| `/admin/enrollment` | AdminEnrollmentScreen ❌ | Admin |
| `/admin/leave` | AdminLeaveScreen | Admin |
| `/admin/attendance` | AdminAttendanceScreen | Admin |
| `/admin/payments` | AdminPaymentsScreen | Admin |
| `/admin/stories` | AdminStoriesScreen | Admin |
| `/admin/leads` | AdminLeadsScreen | Admin |
| `/admin/notify` | AdminNotifyScreen | Admin |
| `/admin/admins` | AdminManageAdminsScreen ❌ | Admin (super only) |
| `/admin/more` | AdminMoreScreen | Admin |
| `/admin/profile` | ProfileHubScreen | Admin |
| `/superadmin/home` | SuperadminHomeScreen | Superadmin |
| `/superadmin/branches` | AdminGroupsScreen | Superadmin |
| `/superadmin/analytics` | SuperadminAnalyticsScreen 🔧 | Superadmin |
| `/superadmin/more` | SuperadminMoreScreen 🔧 | Superadmin |
| `/messages` | MessagesScreen | All |
| `/notifications` | NotificationsScreen | All |
| `/profile` | ProfileHubScreen | All |

---

## 7. Backend API Requirements

### 7.1 Existing Endpoints (Reusable)

All endpoints at `/api/v1/` prefix. All require `Authorization: Bearer <access_token>` header.

| Method | Endpoint | Used by |
|--------|----------|---------|
| POST | `/auth/login/` | Login screen |
| POST | `/auth/logout/` | Profile hub / logout |
| POST | `/auth/token/refresh/` | Dio interceptor |
| GET | `/me/` | Auth state provider |
| POST | `/me/change-password/` | Profile hub |
| POST | `/me/fcm-token/` | App startup |
| GET | `/courses/` | Add student/staff/group forms |
| GET | `/groups/` | Staff classes, attendance |
| GET | `/groups/{pk}/` | Staff class detail |
| GET/POST | `/attendance/` | Staff attendance |
| GET | `/results/` | Student results |
| GET/POST | `/assignments/` | Student/staff assignments |
| GET/PATCH | `/assignments/{pk}/` | Assignment detail |
| POST | `/assignments/{pk}/submit/` | Student submit |
| GET | `/notifications/` | Notifications screen |
| POST | `/notifications/mark-all-read/` | Notifications screen |
| PATCH | `/notifications/{pk}/read/` | Notification item |
| GET/POST | `/leave/` | Student/staff leave |
| GET/PATCH | `/leave/{pk}/` | Leave detail |
| GET/POST | `/feedback/` | Student/staff feedback |
| GET/PATCH | `/feedback/{pk}/` | Feedback detail |
| GET | `/invoices/` | Student payments |
| GET | `/invoices/{pk}/` | Invoice detail |
| GET | `/student/home/` | Student dashboard |
| GET | `/admin/home/` | Admin/superadmin dashboard |
| GET | `/stats/` | Staff dashboard |
| GET | `/admin/stats/` | Admin KPI cards |
| GET | `/admin/users/` | Admin user list |
| GET | `/admin/groups/` | Admin groups list |
| GET/POST | `/admin/enroll/` | Enrollment |
| GET/POST | `/admin/students/` | Admin students |
| GET/PATCH/DELETE | `/admin/students/{pk}/` | Admin student detail |
| GET/POST | `/admin/staff/` | Admin staff |
| GET/PATCH/DELETE | `/admin/staff/{pk}/` | Admin staff detail |
| GET | `/admin/leads/` | Registration leads |
| GET/PATCH | `/admin/leads/{pk}/` | Lead detail |
| GET | `/admin/branches/` | Branch list |
| GET/POST | `/admin/branches-manage/` | Branch CRUD |
| GET/PATCH/DELETE | `/admin/branches-manage/{pk}/` | Branch detail |
| GET/POST | `/admin/courses/` | Course CRUD |
| GET/PATCH/DELETE | `/admin/courses/{pk}/` | Course detail |
| GET/POST | `/admin/sessions/` | Session CRUD |
| GET/PATCH/DELETE | `/admin/sessions/{pk}/` | Session detail |
| GET/POST | `/admin/subjects/` | Subject CRUD |
| GET/PATCH/DELETE | `/admin/subjects/{pk}/` | Subject detail |
| GET | `/admin/groups/{pk}/` | Admin group detail with students |
| GET/POST | `/admin/enrollments/` | Enrollment management |
| GET | `/admin/leave-requests/` | All leave requests |
| PATCH | `/admin/leave-requests/{pk}/` | Approve/reject leave |
| GET | `/admin/attendance-report/` | Attendance report |
| GET/POST | `/admin/stories/` | Story CRUD |
| GET/PATCH/DELETE | `/admin/stories/{pk}/` | Story detail |
| POST | `/admin/send-notification/` | Push notifications |
| GET | `/admin/invoices-manage/` | Invoice management |
| POST | `/admin/invoices-manage/{pk}/pay/` | Record payment |
| GET | `/vocabulary/` | Student vocab list |
| GET | `/vocabulary/{pk}/` | Vocab day detail |
| POST | `/vocabulary/{pk}/complete/` | Mark complete |
| GET | `/vocabulary/{pk}/quiz/` | Quiz questions |
| POST | `/vocabulary/{pk}/quiz-result/` | Save quiz result |
| GET | `/staff/vocabulary/` | Staff vocab list |
| POST | `/staff/vocabulary/create/` | Create vocab day |
| GET/PATCH/DELETE | `/staff/vocabulary/{pk}/` | Edit vocab day |
| GET/POST | `/staff/vocabulary/{pk}/words/` | Manage words |
| DELETE | `/staff/vocabulary/{pk}/words/{word_pk}/` | Delete word |
| GET | `/student/progress/` | Student progress charts |
| GET | `/stories/` | Active stories (student home) |
| POST | `/stories/create/` | Create story (staff) |
| GET | `/stories/{pk}/` | Story detail |
| GET | `/leaderboard/` | Leaderboard |
| POST | `/upload/` | File upload |

### 7.2 New Endpoints Needed

These endpoints do NOT yet exist in the backend and must be built before the corresponding Flutter screen can be completed:

| Priority | Endpoint | Method | Purpose | Notes |
|----------|----------|--------|---------|-------|
| HIGH | `/auth/password-reset/` | POST | Initiate password reset | Send OTP to email |
| HIGH | `/auth/password-reset/verify/` | POST | Verify OTP code | Returns reset token |
| HIGH | `/auth/password-reset/confirm/` | POST | Set new password | — |
| HIGH | `/admin/groups/` | POST | Create new group | With teacher assignment |
| HIGH | `/admin/groups/{pk}/` | PATCH/DELETE | Edit/archive/delete group | — |
| HIGH | `/admin/admins/` | GET/POST | List/create admin accounts | Super admin only |
| HIGH | `/admin/admins/{pk}/` | PATCH/DELETE | Edit/delete admin | Cannot delete last super admin |
| MEDIUM | `/chat/threads/` | GET | List chat threads | Filtered by role |
| MEDIUM | `/chat/threads/{pk}/messages/` | GET/POST | Chat messages | Paginated |
| MEDIUM | `/chat/threads/{pk}/messages/{msg_pk}/` | DELETE | Delete message | Owner or admin only |
| MEDIUM | `/library/books/` | GET | Available books | — |
| MEDIUM | `/library/loans/` | GET | Own active loans | — |
| LOW | `/admin/invoices-manage/` | POST | Create invoice manually | — |
| LOW | `/admin/invoices-manage/generate/` | POST | Bulk invoice generation | By group/period |
| LOW | `/superadmin/analytics/` | GET | Cross-branch analytics | — |
| LOW | `/admin/vocabulary-days/` | GET | Admin view of all vocab days | Read-only |
| LOW | `/staff/results/` | GET/POST/PATCH | Staff-specific result management | With group+student scope |

---

## 8. Dart Data Models

All models should be generated with `json_serializable` or hand-written with `fromJson`/`toJson`.

### 8.1 User / Auth Models

```dart
class AuthUser {
  final int id;
  final String email;
  final String loginId;
  final String userType;       // '1', '2', '3'
  final bool isSuperAdmin;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? address;
  // role helpers
  bool get isAdmin     => userType == '1' && !isSuperAdmin;
  bool get isSuperAdminUser => userType == '1' && isSuperAdmin;
  bool get isStaff     => userType == '2';
  bool get isStudent   => userType == '3';
}
```

### 8.2 Core Models

```dart
class Branch    { int id; String name; String address; }
class Course    { int id; String name; bool isActive; bool isEnglish; double monthlyFee; }
class Subject   { int id; String name; int courseId; int? staffId; }
class Session   { int id; String startYear; String endYear; }

class Group {
  int id; String name; int courseId; String courseName;
  int teacherId; String teacherName; int branchId; String branchName;
  String room; String schedule; int capacity; int enrolled;
  double monthlyFee; DateTime? startDate; bool isArchived;
}

class Enrollment {
  int id; int studentId; String studentName; int groupId; String groupName;
  DateTime enrolledAt;
}
```

### 8.3 Student / Staff Profile Models

```dart
class StudentProfile {
  int id; int userId; String loginId; String firstName; String lastName;
  String email; String? phone; String? address;
  DateTime? dateOfBirth; String? gender;
  int courseId; String courseName; int branchId; String branchName;
  String status;    // 'active', 'inactive', 'graduated'
  String? level;    // 'beginner', 'elementary', etc.
  String? theme;    // avatar emoji
}

class StaffProfile {
  int id; int userId; String loginId; String firstName; String lastName;
  String email; String? phone;
  int courseId; String courseName; int branchId; String branchName;
  String? specialization; bool isActive;
}
```

### 8.4 Attendance Models

```dart
class AttendanceRecord {
  int id; int studentId; String studentName;
  int groupId; DateTime date; String status; // 'P', 'A', 'L'
}

class AttendanceSummary {
  int present; int absent; int leave; int total;
  double get rate => total == 0 ? 0 : present / total * 100;
}
```

### 8.5 Result Models

```dart
class StudentResult {
  int id; int studentId; String subjectName;
  int testScore;  // 0-40
  int examScore;  // 0-60
  int get total => testScore + examScore;
  String? teacherComment;
  String? resultFileUrl;
}
```

### 8.6 Vocabulary Models

```dart
class VocabularyDay {
  int id; int groupId; int dayNumber; String title;
  int wordCount; DateTime? releaseAt; String releaseScope;
  bool completed; int? quizScore;
}

class VocabularyWord {
  int id; String word; String translation; String? example; String? imageUrl;
}

class QuizQuestion {
  String word; List<String> options; int correctIndex;
}
```

### 8.7 Leave & Feedback Models

```dart
class LeaveRequest {
  int id; DateTime startDate; DateTime endDate; String reason;
  String status;  // 'pending', 'approved', 'rejected'
  String? adminComment; DateTime createdAt;
}

class Feedback {
  int id; String message; String? reply; DateTime? repliedAt; DateTime createdAt;
}
```

### 8.8 Invoice / Payment Models

```dart
class Invoice {
  int id; int studentId; String studentName; int? groupId;
  String period;   // 'YYYY-MM'
  double amount; double discount; double paid;
  double get balance => amount - discount - paid;
  String status;   // 'pending', 'partial', 'paid', 'overdue', 'cancelled'
  DateTime? dueDate;
}

class Payment {
  int id; int invoiceId; double amount;
  String method;   // 'cash', 'card', 'transfer', 'payme', 'click', 'uzum'
  String? note; DateTime paidOn;
}
```

### 8.9 Story & Notification Models

```dart
class Story {
  int id; String title; String body; String? imageUrl;
  String storyType; String? emoji; String? bgColor;
  bool isActive; DateTime? expiresAt;
}

class AppNotification {
  int id; String title; String message; String category;
  bool isRead; DateTime createdAt;
}
```

### 8.10 Chat Models

```dart
class ChatThread {
  int id; int groupId; String groupName; String lastMessage;
  DateTime lastAt; int unreadCount;
}

class ChatMessage {
  int id; int threadId; int senderId; String senderName;
  String body; String? fileUrl; String? fileName;
  DateTime sentAt; bool isOwn;
}
```

### 8.11 Leaderboard & Progress

```dart
class LeaderboardEntry {
  int rank; int studentId; String studentName;
  String avatarEmoji; int score; String? badge;
}

class ProgressData {
  List<AttendanceTrend> attendanceTrend;
  List<QuizHistory> quizHistory;
  List<VocabCompletion> vocabCompletion;
}
```

---

## 9. State Management Plan

**Tool:** `flutter_riverpod` — already in use.

### 9.1 Provider Architecture

```
authProvider (StateNotifierProvider)
  └── AuthState { status, user, tokens }
  
// Per-feature async data:
studentHomeProvider (FutureProvider)
staffHomeProvider   (FutureProvider)
adminHomeProvider   (FutureProvider)

groupsProvider          (FutureProvider<List<Group>>)
studentsProvider        (FutureProvider<List<StudentProfile>>)
staffProvider           (FutureProvider<List<StaffProfile>>)
attendanceProvider      (FutureProvider<List<AttendanceRecord>>)
resultsProvider         (FutureProvider<List<StudentResult>>)
vocabularyListProvider  (FutureProvider<List<VocabularyDay>>)
vocabularyDetailProvider(family: int pk) → FutureProvider<VocabularyDay>
notificationsProvider   (FutureProvider<List<AppNotification>>)
invoicesProvider        (FutureProvider<List<Invoice>>)
leaderboardProvider     (FutureProvider<List<LeaderboardEntry>>)
```

### 9.2 Mutations

Use `StateNotifier` or `AsyncNotifier` for write operations:

```dart
class AttendanceNotifier extends AsyncNotifier<void> {
  Future<void> submit(AttendanceSubmission data) async { ... }
}
```

Optimistic updates where appropriate (mark notification as read instantly, revert on error).

### 9.3 Cache Strategy

- All FutureProviders are `ref.keepAlive()` within a shell — data persists while user is on that shell branch
- Pull-to-refresh re-triggers the provider
- Token refresh handled in Dio interceptor, not in providers

---

## 10. Folder Structure

Current structure (maintain this):

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart        # Dio + BaseOptions + JWT interceptor
│   │   └── api_providers.dart     # Provider exposing ApiClient
│   ├── auth/
│   │   └── auth_state.dart        # AuthState, AuthNotifier, authProvider
│   ├── router/
│   │   └── app_router.dart        # All GoRouter routes
│   ├── theme/
│   │   └── app_theme.dart         # IceColors, IceTheme
│   └── utils/
│       └── formatters.dart        # UZS formatter, date formatter, login_id parser
│
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── forgot_password_screen.dart  ← TO BUILD
│   ├── student/
│   │   └── screens/              # All student screens
│   ├── staff/
│   │   └── screens/              # All staff screens
│   ├── admin/
│   │   └── screens/              # All admin screens
│   └── superadmin/
│       └── screens/              # All superadmin screens
│
├── shared/
│   ├── screens/
│   │   ├── profile_screen.dart   # Legacy — keep for now
│   │   ├── profile_hub_screen.dart
│   │   ├── messages_screen.dart
│   │   └── notifications_screen.dart
│   └── widgets/
│       ├── adaptive_layout.dart  # width breakpoint widget
│       ├── adaptive_shell.dart   # sidebar vs bottom nav
│       ├── ice_action_button.dart
│       ├── ice_hero_card.dart
│       ├── ice_kpi_card.dart
│       ├── ice_list_tile.dart
│       ├── ice_nav_bar.dart
│       └── ice_page_header.dart
│
└── main.dart
```

**To add (new shared widgets):**
```
shared/widgets/
├── ice_data_table.dart      # Desktop-style sortable table
├── ice_stat_chip.dart       # Small stat pill (e.g. "87% attended")
├── ice_confirm_dialog.dart  # Standard delete/confirm dialog
├── ice_form_sheet.dart      # Bottom sheet with form fields
├── ice_story_strip.dart     # Horizontal scrolling story row
└── ice_chart_card.dart      # Card wrapping fl_chart line/bar
```

---

## 11. UI Design System

### 11.1 IceColors (already defined in `app_theme.dart`)

| Token | Hex | Use |
|-------|-----|-----|
| `navy` | `#06343A` | Sidebar bg, hero sections, text headings |
| `navyMid` | `#073B42` | Card bg on dark sections |
| `navyDeep` | `#0E6873` | Primary accent, buttons, active nav items |
| `lime` | `#DFFF2F` | CTA highlight, active indicators on dark bg |
| `limeAlt` | `#C7FF3D` | Hover state for lime |
| `bg` | `#FAFAFA` | Main scaffold background (light mode) |
| `surface` | `#FFFFFF` | Card backgrounds |
| `surface2` | `#F4FAFB` | Alternate row, secondary card |
| `border` | `#DCEAEC` | Card border, dividers |
| `text` | `#06343A` | Primary text |
| `muted` | `#6B7F83` | Secondary/caption text |
| `success` | `#38A169` | Approved, present, positive |
| `warning` | `#E5A936` | Pending, warning |
| `danger` | `#E56B6F` | Rejected, absent, error |
| `info` | `#0284C7` | Info badge, link color |

**Dark mode overrides:**
| Token | Hex |
|-------|-----|
| `darkBg` | `#040F10` |
| `darkSurface` | `#071518` |
| `darkBorder` | `#0F2F33` |
| `darkText` | `#DCEAEC` |

### 11.2 Typography (Inter via `google_fonts`)

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| `headlineLarge` | 26sp | 900 | Page heroes |
| `headlineMedium` | 20sp | 800 | Section titles |
| `titleMedium` | 15sp | 700 | Card titles, list tile primary |
| `bodyMedium` | 14sp | 500 | Body text, list tile secondary |
| `bodySmall` | 12sp | 500 | Captions, timestamps, muted text |

### 11.3 Border Radius Constants

```dart
IceTheme.r    = 24.0  // standard cards
IceTheme.rSm  = 14.0  // small chips, badges
IceTheme.rLg  = 32.0  // hero cards, bottom sheets
```

### 11.4 Standard Component Patterns

**Primary Button:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: IceColors.navyDeep,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IceTheme.rSm)),
  ),
  ...
)
```

**Lime CTA (on dark background):**
```dart
backgroundColor: IceColors.lime,
foregroundColor: IceColors.navy,
```

**Status badge:**
```dart
Color _statusColor(String status) => switch (status) {
  'approved' || 'paid' || 'present' => IceColors.success,
  'pending' || 'partial' => IceColors.warning,
  'rejected' || 'overdue' || 'absent' => IceColors.danger,
  _ => IceColors.muted,
};
```

---

## 12. Mobile-First Design Rules

1. **Minimum touch target:** 48×48dp for all interactive elements
2. **Bottom-up navigation:** Primary actions (submit, save) at bottom of screen, not top
3. **Pull-to-refresh:** All list screens must support `RefreshIndicator`
4. **Keyboard avoidance:** Forms inside `SingleChildScrollView` with `resizeToAvoidBottomInset: true`
5. **One column on mobile:** No side-by-side fields on screens < 600px
6. **Swipe-to-dismiss:** Where delete is appropriate (notifications), support swipe gesture
7. **Infinite scroll / pagination:** Any list > 20 items uses `ListView.builder` + scroll listener + API pagination
8. **Loading skeleton:** Show animated grey boxes (shimmer) while data loads — not spinner-only
9. **Toast feedback:** Snackbar for success/error after form submit — always, never silent
10. **Empty state illustrations:** Every list screen has an empty state with icon + message + CTA
11. **Large text:** Support system font scale up to 1.3× without layout overflow
12. **Back button:** Every non-shell screen has a back button (AppBar leading)

---

## 13. Tablet & Desktop Adaptation

**Width breakpoints (defined in `adaptive_layout.dart`):**
```dart
const kMobile  = 600.0;   // < 600 → mobile layout
const kTablet  = 1024.0;  // 600–1024 → tablet layout  
const kDesktop = 1280.0;  // > 1024 → desktop layout
```

**Layout changes per breakpoint:**

| Component | Mobile | Tablet | Desktop |
|-----------|--------|--------|---------|
| Navigation | Bottom nav bar | Left rail (icons + labels) | Left sidebar (expanded, 240px) |
| Grid columns | 1 | 2 | 2–3 |
| KPI cards | Horizontal scroll | 2×2 grid | 4-in-a-row |
| Lists | Full-width cards | Cards in grid | Data table with sortable columns |
| Forms | Full-screen | Modal dialog | Right panel or modal |
| Charts | Full-width, compressed | Full-width | Two-column with labels |

**Implementation pattern:**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > kDesktop) return _DesktopLayout();
    if (constraints.maxWidth > kMobile) return _TabletLayout();
    return _MobileLayout();
  },
)
```

---

## 14. Error / Loading / Empty States

### 14.1 Loading States

Every async screen must handle `loading` state:
- **Skeleton loaders:** `shimmer` package for list/card skeletons (not spinners alone)
- **Progress indicator:** `CircularProgressIndicator` in `IceColors.navyDeep` color only for short ops
- **Button loading:** Inline spinner replacing button text during form submit; disable to prevent double-submit

### 14.2 Error States

```dart
// Standard error widget:
Column(children: [
  Icon(Icons.wifi_off_rounded, size: 64, color: IceColors.muted),
  Text('Could not load data', style: bodyMedium),
  Text('Check your connection and try again', style: bodySmall),
  ElevatedButton.icon(
    onPressed: () => ref.refresh(provider),
    icon: Icon(Icons.refresh),
    label: Text('Retry'),
  ),
])
```

**Error categories to handle:**
- 401 → Auto-refresh token; if fails → logout + redirect to `/login`
- 403 → "You don't have permission" inline message (do NOT crash)
- 404 → "Not found" inline message with back button
- 422 → Field-level validation errors from API (map to form fields)
- 500 → "Server error" with retry
- Network timeout → "No internet" with retry

### 14.3 Empty States

Every list screen needs:
```dart
// Example:
Widget _empty() => Center(child: Column(children: [
  Text('📋', style: TextStyle(fontSize: 48)),
  Text('No leaves yet', style: headlineMedium),
  Text('Your leave requests will appear here.', style: bodySmall),
  ElevatedButton(onPressed: _apply, child: Text('Apply for Leave')),
]));
```

Custom empty messages per screen:
- Students list: "No students yet — add your first student"
- Vocabulary: "No vocabulary days released yet"
- Notifications: "You're all caught up!"
- Leaderboard: "Not enough data yet"
- Payments: "No invoices yet"

---

## 15. Charts & Analytics Plan

**Chart library:** `fl_chart` (already in pubspec or to be added — verify)

### 15.1 Required Charts

| Screen | Chart type | Data | Library |
|--------|-----------|------|---------|
| Admin Home | Multi-line (branch performance) | `{labels, lines: [{label, color, values}]}` | fl_chart `LineChart` |
| Admin Home | Line (attendance %) | `[{month, rate}]` | fl_chart `LineChart` |
| Admin Home | Line (new students) | `[{month, count}]` | fl_chart `LineChart` |
| Student Home | Donut / ring (attendance) | `{present, absent, leave}` | fl_chart `PieChart` |
| Student Progress | Line (attendance trend) | `[{month, rate}]` | fl_chart `LineChart` |
| Student Progress | Bar (quiz scores) | `[{date, score}]` | fl_chart `BarChart` |
| Student Progress | Step/bar (vocab completion) | `[{day, completed}]` | fl_chart `BarChart` |
| Leaderboard | No chart — ranked list | — | — |

### 15.2 Chart Implementation Notes

- All charts must respect dark mode (use `IceColors.darkBg` for grid, `IceColors.darkText` for labels)
- Touch tooltips required for all charts
- Charts animate on first render (500ms)
- Sparklines (mini charts in KPI cards): `fl_chart` `LineChart` with no axes, no labels, height 40dp
- Charts must have `RepaintBoundary` wrapper to prevent unnecessary repaints

---

## 16. Forms & Validation Plan

### 16.1 Standard Form Pattern

All forms use `GlobalKey<FormState>` + `TextEditingController` or `ref.read(formProvider)`.

```dart
final _formKey = GlobalKey<FormState>();
// ...
TextFormField(
  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
  decoration: InputDecoration(label: Text('Full Name')),
)
```

### 16.2 Field Types

| Field | Widget | Validation |
|-------|--------|------------|
| Text (name, address) | `TextFormField` | required, maxLength |
| Email | `TextFormField(keyboardType: email)` | required, contains `@` |
| Phone | `TextFormField(keyboardType: phone)` | optional, digits only |
| Password | `TextFormField(obscureText)` | required, min 8 chars |
| Date | `showDatePicker()` → TextFormField | required, not future (for DOB) |
| Dropdown (course, branch) | `DropdownButtonFormField` | required |
| Multi-select (branches for admin, groups for story) | `MultiSelectDialog` (custom) | optional |
| Number (score, fee) | `TextFormField(keyboardType: number)` | range validation |
| Toggle (is_active, is_super_admin) | `SwitchListTile` | — |
| File upload | `FilePicker` → upload dialog | see Section 17 |
| Text area (reason, message) | `TextFormField(maxLines: 4)` | required for some |

### 16.3 API Validation Errors

After submit, if API returns 422/400 with field errors:
```json
{"first_name": ["This field is required."], "email": ["Already in use."]}
```
Map these to the form fields:
```dart
setState(() {
  _firstNameError = errors['first_name']?.first;
  _emailError = errors['email']?.first;
});
```

### 16.4 Confirm Dialogs for Destructive Actions

```dart
// Before any DELETE:
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Delete Student?'),
    content: Text('This cannot be undone.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: IceColors.danger),
        onPressed: () => Navigator.pop(context, true),
        child: Text('Delete'),
      ),
    ],
  ),
);
if (confirmed == true) _delete();
```

---

## 17. File & Image Upload Plan

**Upload endpoint:** `POST /api/v1/upload/` (returns file URL)

### 17.1 Upload Flow

```dart
// 1. User taps upload button
// 2. FilePicker.platform.pickFiles(type: FileType.any) — works on web + mobile
// 3. Show selected filename with loading indicator
// 4. POST multipart/form-data to /api/v1/upload/
// 5. API returns {"url": "/media/uploads/file.pdf"}
// 6. Store URL in form field, display success
```

### 17.2 File Types by Feature

| Feature | Accepted types | Max size |
|---------|---------------|----------|
| Assignment submission | PDF, DOC, DOCX, ZIP, images | 20MB |
| Story image | JPG, PNG, WebP | 5MB |
| Vocabulary word image | JPG, PNG | 2MB |
| Result file (teacher) | PDF, images | 10MB |
| Chat attachment | Any | 10MB |

### 17.3 Web Platform Notes

- `FilePicker` works on Flutter Web via `<input type="file">` in CanvasKit
- File bytes available via `PlatformFile.bytes` on web (not path)
- Send as `MultipartFile.fromBytes(bytes, filename: name)`
- Progress indicator during upload (Dio supports `onSendProgress`)

### 17.4 Image Display

- Use `Image.network(url)` with `errorBuilder` fallback to placeholder
- Cache with `cached_network_image` package (add to pubspec if not present)
- Avatars are emoji only (no real image uploads for avatars)

---

## 18. Security & Permission Requirements

> These are MANDATORY requirements. Frontend role checks are UX only. All enforcement is backend-side.

### 18.1 Authentication

- All API calls include `Authorization: Bearer <token>`
- Token expires → auto-refresh via Dio interceptor
- Refresh fails → clear local storage → redirect to `/login`
- Never store plaintext password

### 18.2 Role-Based Access

- Flutter router `redirect` guards: unauthenticated users → `/login`
- Wrong-role path → redirect to role's home (mirroring Django behavior)
- Frontend only shows UI elements allowed for the role (never shows admin actions to students)
- Backend validates role on EVERY API request (not just session-time check)

### 18.3 Branch Isolation

- Branch admins MUST NOT be able to see or modify students from other branches
- Backend enforces: `filter_students_for_user()`, `filter_staff_for_user()`, `filter_groups_for_user()`
- Flutter MUST NOT pass branch IDs that the user didn't receive from the API
- All dropdown/select data is fetched from the API (user can only pick what they're allowed to see)

### 18.4 IDOR Prevention

| Scenario | Backend enforcement needed |
|----------|--------------------------|
| Student view another student's results | `StudentResult.student == request.user.student` |
| Staff take attendance for another teacher's group | `Group.teacher == request.user.staff` |
| Branch admin delete student from other branch | `branching.filter_students_for_user()` |
| Admin access another admin's data | Not applicable (all admins equal within scope) |
| Student access another student's leave | `LeaveReport.student == request.user.student` |
| Student view another student's invoices | `Invoice.student == request.user.student` |

### 18.5 Safe Redirects

- Never use `?next=` URL parameters to redirect after login (open redirect risk)
- GoRouter handles all redirects internally — no URL-param-based redirects
- Deep links to role-specific pages always run through the auth redirect guard

### 18.6 Data Sanitization in UI

- Never render HTML from API responses with `flutter_html` unless sanitized
- Chat messages: render as plain text, escape HTML entities
- Story body: if HTML rendering is needed, use `flutter_html` with `allowedElements` whitelist

---

## 19. Migration Stages

### Stage 0: Foundation (DONE ✅)
- [x] Flutter project created at `/home/user/iceberg_app/`
- [x] IceColors design system defined
- [x] GoRouter configured
- [x] Riverpod configured
- [x] Dio API client with JWT interceptor
- [x] Auth state management
- [x] Login screen
- [x] Shell navigation for all 4 roles

### Stage 1: Student MVP (DONE ✅)
- [x] Student Home Dashboard
- [x] Student Vocabulary (list + detail + flashcards + quiz)
- [x] Student Attendance
- [x] Student Results
- [x] Student Progress
- [x] Student Leaderboard
- [x] Student Payments
- [x] Student Leave
- [x] Student Feedback
- [x] Student Notifications
- [x] Student Assignments
- [x] Student Books (stub with coming-soon)
- [x] Student Result Files
- [x] Profile Hub (shared)

### Stage 2: Staff MVP (DONE ✅)
- [x] Staff Home Dashboard
- [x] Staff Classes (group list)
- [x] Staff Attendance (take + update)
- [x] Staff Results (add + edit)
- [x] Staff Vocabulary Management (list + day detail + words)
- [x] Staff Assignments
- [x] Staff Leave
- [x] Staff Feedback
- [x] Messages (shared)

### Stage 3: Admin MVP (IN PROGRESS 🔧)
- [x] Admin Home Dashboard
- [x] Admin Students List
- [x] Admin Add Student
- [x] Admin Staff List
- [x] Admin Add Staff
- [x] Admin Groups List
- [x] Admin Courses CRUD
- [x] Admin Subjects CRUD
- [x] Admin Sessions CRUD
- [x] Admin Branches CRUD
- [x] Admin Leave Requests (approve/reject)
- [x] Admin Attendance Report
- [x] Admin Payments / Invoices
- [x] Admin Stories CRUD
- [x] Admin Leads
- [x] Admin Send Notification
- [ ] Admin Edit Student ← TO BUILD
- [ ] Admin Edit Staff ← TO BUILD
- [ ] Admin Group Detail (enrolled students) ← TO BUILD
- [ ] Admin Add/Edit Group ← TO BUILD
- [ ] Admin Enrollment Management ← TO BUILD
- [ ] Admin Manage Admins (super admin only) ← TO BUILD

### Stage 4: Superadmin & Analytics
- [ ] Superadmin Home improvements
- [ ] Superadmin Analytics screen
- [ ] Cross-branch comparison charts
- [ ] Admin management (create/edit admin accounts)

### Stage 5: Remaining Features
- [ ] Forgot password flow (needs backend REST endpoints)
- [ ] Push notifications (FCM integration)
- [ ] Library / Books (needs backend API)
- [ ] Chat (needs backend REST API for chat)
- [ ] Invoice generation (bulk)
- [ ] CSV export

### Stage 6: Polish & Production
- [ ] Dark mode testing
- [ ] Responsive testing on all breakpoints
- [ ] Error state testing for all screens
- [ ] Performance profiling (Flutter DevTools)
- [ ] Accessibility audit (VoiceOver / TalkBack)
- [ ] Production build with `--dart-define=API_BASE=https://...`

---

## 20. Testing Plan

### 20.1 What to Test

| Category | How | When |
|----------|-----|------|
| Auth flow | Manual: login as each role, verify redirect | Before each stage release |
| Role guard | Manual: try accessing wrong-role URL | Before each stage release |
| Branch IDOR | Manual: try editing IDs in URL / request | Before Stage 3 release |
| Form validation | Manual: submit empty forms, bad emails | After each form screen |
| API error handling | Manual: disconnect network, check error state | Before Stage 6 |
| Dark mode | Manual: toggle in profile hub, check all screens | Before Stage 6 |
| Mobile layout | Chrome DevTools device emulation | After each screen |
| Tablet layout | Resize browser to 768px | After each screen |
| Desktop layout | Full-width browser | After each screen |

### 20.2 Widget Tests (Optional but Recommended)

```dart
// Test that login screen shows error on bad credentials:
testWidgets('login screen shows error on 401', (tester) async {
  // Mock API to return 401
  // Pump LoginScreen
  // Tap submit
  // Expect error message widget
});
```

### 20.3 Manual QA Checklist (Per Screen)

- [ ] Page loads without error
- [ ] Loading state shown while fetching
- [ ] Data renders correctly
- [ ] Empty state shown when no data
- [ ] Error state shown on API failure with retry button
- [ ] All buttons are tappable (48dp minimum)
- [ ] Forms validate before submit
- [ ] Success toast after form submit
- [ ] Back navigation works
- [ ] Dark mode renders correctly
- [ ] Mobile (375px) layout is usable
- [ ] No overflow errors in debug mode

---

## 21. Risks & Things to Double-Check

### 21.1 Backend Gaps (HIGH RISK)

| Risk | Impact | Mitigation |
|------|--------|------------|
| Chat REST API does not exist | `MessagesScreen` has no real data | Build chat endpoints before Stage 5 |
| Password reset REST API missing | Forgot password flow broken | Build before Stage 5 |
| Group CRUD API missing (create/edit/delete) | Admin cannot manage groups | Build before Stage 3 completes |
| Admin management API missing | Cannot add/edit admin accounts | Build before Stage 4 |
| Library API missing | Books screen always "coming soon" | Build before Stage 5 |
| `PATCH /api/v1/attendance/` for update attendance | StaffUpdateAttendanceScreen has no save endpoint | Verify existing attendance POST handles updates, or add PATCH |

### 21.2 IDOR Checks (HIGH SECURITY RISK)

| Scenario | Status | Action required |
|----------|--------|----------------|
| Staff result edit — teacher can only edit own group's results | ⚠️ Needs verification | Add backend check in results PATCH view |
| Branch admin edit student from other branch | ✅ Verified in `delete_student` | Verify SAME check exists in `edit_student` API view |
| Student accessing another student's attendance via API | ⚠️ Needs verification | Check `AttendanceView` filters by `request.user.student` |
| Student accessing another student's invoices via API | ⚠️ Needs verification | Check `InvoiceView` filters by `request.user.student` |
| Chat: student reading another group's thread | ⚠️ Needs verification | When chat API is built, enforce enrollment check |

### 21.3 Data / Business Logic

| Risk | Notes |
|------|-------|
| UZS currency formatting | Must use `space` thousands separator, no decimals: `450 000 so'm`. Not `$` or `₹`. |
| Attendance P/L/A values | Backend expects exactly `'P'`, `'A'`, `'L'` — not `'present'` or `1`/`0` |
| Result scores | Test: 0–40, Exam: 0–60, Total: sum. Flutter must validate range, not just "positive number". |
| Login ID format | `IC{MMDD}{NN}` and `TC{MMDD}{NN}` — generated by backend. Flutter should NEVER generate these. |
| Date formats | Backend likely expects `YYYY-MM-DD` ISO. Flutter `DatePicker` returns `DateTime` — convert with `DateFormat('yyyy-MM-dd').format(date)`. |
| Vocab day `release_scope` | `'group'` = only teacher's group can see; `'all'` = any student can see. Flutter must not show locked days. |
| Super admin protection | Cannot delete last super admin — backend enforces `Admin.clean()`. Flutter should show error message from API if this happens, not crash. |

### 21.4 Flutter Web Specific

| Risk | Notes |
|------|-------|
| CanvasKit renderer | All UI is WebGL canvas. Cannot use native `<input>` or browser extensions. FilePicker uses invisible `<input type="file">` via dart:html bridge. |
| CORS | Backend must have `CORS_ALLOWED_ORIGINS` including the Flutter Web origin (or `CORS_ALLOW_ALL_ORIGINS=True` in dev). |
| `flutter_secure_storage` on Web | Falls back to localStorage (less secure than native). For prod: use `HttpOnly` cookie auth or accept the limitation. |
| Deep links | GoRouter handles navigation history correctly in web (browser back/forward works). Test this. |
| Initial load time | CanvasKit WASM download is ~2MB. Add loading screen / preload indicator on index.html. |
| File download | On web, `url_launcher` opens file URL in new tab. `dio.download()` does not work on web — must use `dart:html` `AnchorElement.click()` with `download` attribute. |

### 21.5 Design & UX Risks

| Risk | Notes |
|------|-------|
| Uzbek names with special characters | Names may contain `oʻ`, `gʻ` etc. Ensure `Inter` font renders these. Test with real names. |
| Right-to-left (RTL) | Not needed for English UI, but if Uzbek UI is added later, prepare with `Directionality` widget. |
| Long group names / student names | Cards must handle overflow with `TextOverflow.ellipsis`. Check all `Text` widgets. |
| `lime` on light backgrounds | `IceColors.lime = #DFFF2F` has VERY low contrast on white. Only use lime on dark (navy) backgrounds. |
| Story images failing to load | `Image.network` must have `errorBuilder` showing emoji fallback. |

---

*End of FLUTTER_APP_MIGRATION_PLAN.md*

**Document stats:**
- Screens documented: 60+
- API endpoints mapped: 70+
- Dart models defined: 15+
- Migration stages: 6
- Risk items: 20+

**Next recommended step before Flutter coding:**  
Complete Stage 3 (Admin screens) in this order:
1. Build `AdminEditStudentScreen` (route `/admin/students/:id/edit`)
2. Build `AdminEditStaffScreen` (route `/admin/staff/:id/edit`)
3. Add group CRUD backend endpoints (`POST/PATCH/DELETE /api/v1/admin/groups/`)
4. Build `AdminGroupDetailScreen` and `AdminAddGroupScreen`
5. Build `AdminEnrollmentScreen`
6. Build `AdminManageAdminsScreen` (with new backend endpoint)
