# HRMS Mobile API Integration Guide

This document outlines the communication flow between the Flutter mobile application and the HRMS microservices through the API Gateway and BFF layer.

---

## 1. Network Routing Flow

```
Flutter Mobile App (Dio)
       │
       │ HTTP/JSON
       │ Headers:
       │   - Authorization: Bearer <accessToken>
       │   - x-tenant: <subdomain> (e.g. csktech)
       │   - x-tenant-id: <uuid>
       ▼
API Gateway (:3000)
       │
       ├── /api/auth/* ─────────────► Auth Service (:3003)
       ├── /api/attendance/* ───────► Attendance Service (:3002)
       ├── /api/employee/* ─────────► Employee Service (:3001)
       ├── /api/leave/* ────────────► Leave Service (:3004)
       ├── /api/payroll/* ──────────► Payroll Service (:3005)
       ├── /api/shift/* ────────────► Shift Service (:3009)
       ├── /api/task/* ─────────────► Task Service (:3012)
       ├── /api/asset/* ────────────► Asset Service (:3013)
       ├── /api/notification/* ─────► Notification Service (:3008)
       └── /api/bff/employee-profile/* ► API Gateway BFF Aggregation Controller
```

---

## 2. Face Recognition & Biometric Attendance Endpoints

### Biometric Status
- **Method**: `GET`
- **Endpoint**: `/api/attendance/face/status`
- **Response**:
```json
{
  "isEnrolled": true,
  "status": "ACTIVE",
  "enrolledAt": "2026-08-28T10:00:00Z",
  "lastVerifiedAt": "2026-08-29T09:15:00Z",
  "modelName": "mediapipe-tasks-vision"
}
```

### Face Enrollment / Registration
- **Method**: `POST`
- **Endpoint**: `/api/attendance/face/register`
- **Body**:
```json
{
  "template": [0.035, 0.12, ...],
  "modelName": "mediapipe-tasks-vision",
  "modelVersion": "0.10.x",
  "consent": true
}
```

### Face Verification & Clock-In
- **Method**: `POST`
- **Endpoint**: `/api/attendance/clock-in`
- **Body**:
```json
{
  "method": "face",
  "faceTemplate": [0.035, 0.12, ...],
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "accuracy": 12.4
  }
}
```
