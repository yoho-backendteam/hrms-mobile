# HRMS Enterprise Mobile Application

A production-ready Flutter mobile application for Enterprise Human Resource Management, Employee Self-Service, and Facial Recognition Biometric Attendance.

---

## 🚀 Key Features

1. **Enterprise Multi-Tenant Authentication**:
   - Secure login with tenant resolution (`x-tenant: <subdomain>`).
   - Hardware-backed encrypted token storage (`FlutterSecureStorage`).
   - Silent 401 JWT refresh queue & automatic request retry.

2. **Facial Recognition Attendance**:
   - Live camera viewfinder & landmark extraction.
   - GPS perimeter capture & geofencing verification.
   - Attendance state machine: `Clock In` ➔ `Break In` ➔ `Break Out` ➔ `Clock Out`.
   - Biometric profile enrollment, re-registration, and revocation.

3. **Role & Permission-Driven Dashboards**:
   - **Employee Self-Service**: Live punch card, leave quotas, task list, assigned assets, and today's shift.
   - **HR Command Center**: Real-time workforce metrics, pending leave approvals queue, employee directory, and interview schedules.

4. **Pure Enterprise Light Design System**:
   - Strict Light Mode only (Material 3, `#E1533E` primary brand coral, clean slate neutrals).
   - Zero dark mode toggles or settings.

5. **Complete HR Feature Modules**:
   - **Employee Management**: Directory search, department filters, BFF aggregated profile.
   - **Leave Management**: Quota cards, bottom-sheet application, approval workflows.
   - **Payroll & Payslips**: Confidential salary breakdown, earnings/deductions, PDF downloads.
   - **Shift & Rostering**: Assigned shift details, weekly schedule, grace period info.
   - **Tasks & Asset Tracking**: Assigned IT assets, deliverable checklists.
   - **Notifications & Settings**: Biometric controls, session sign-out.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter (Dart 3.x)
- **State Management**: `flutter_riverpod`
- **Routing**: `go_router` (with auth redirect & shell navigation)
- **Networking**: `dio` (with `TenantInterceptor`, `AuthInterceptor`, `ErrorInterceptor`)
- **Storage**: `flutter_secure_storage`
- **Sensors**: `camera`, `geolocator`

---

## 📦 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 3. Run on Device / Emulator
```bash
# Android Emulator (uses 10.0.2.2:3000 to connect to host API Gateway)
flutter run

# iOS Simulator (uses 127.0.0.1:3000)
flutter run -d iOS

# Custom API Gateway Base URL
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
```
