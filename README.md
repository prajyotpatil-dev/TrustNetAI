#                                                              🚛 TrustNet AI 

### AI-Powered Trust & Intelligence Platform for Indian Logistics

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Dart-3.9-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Gemini_2.0_Flash-AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI" /></a>
  <a href="#"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge" alt="Platform" /></a>
</p>

<p align="center">
  <b>Built for the Google Developer Group (GDG) Solution Challenge — Build with AI Hackathon</b>
</p>

<br/>

## 📖 Overview

**TrustNet AI** is a Flutter-based logistics trust management platform built for the **Indian supply chain industry**.

It uses **Google Gemini 2.0 Flash** via **Firebase Cloud Functions** to deliver intelligent carrier trust scoring, real-time fraud detection, smart transporter-to-shipment assignment, and predictive delivery analytics — replacing gut-feel decisions with **data-driven intelligence**.

The platform serves two core user roles:
- **Business Owners** (shippers) — create shipments, track consignments, verify ePOD, review AI risk reports
- **Transporters** — accept shipments, update delivery status, upload proof of delivery, view trust scores

All AI calls are **server-side only** (no client-side API key exposure), with real-time Firestore synchronization and role-based access control.

<br/>

## ✨ Key Features

| Feature | Description |
|:---|:---|
| 🧠 **AI Trust Scoring** | Weighted score engine (0–100) — on-time delivery (40%), ePOD compliance (20%), GPS reliability (15%), cancellation rate (15%), and rating (10%). Auto-recalculated via Firestore triggers. |
| 🔍 **Fraud Detection** | GPS teleport detection, unrealistic speed checks (>120 km/h), route deviation monitoring, proof image reuse detection, and proof location validation. |
| 🤖 **Gemini AI Reports** | On-demand trust reports, fraud analysis, and delivery predictions via Gemini 2.0 Flash through secure Cloud Functions. |
| 🎯 **Smart Assignment** | Transporter ranking — 60% trust score + 40% proximity. Covers 15+ Indian cities with coordinate-based distance calculation. |
| ⏱️ **Predictive ETA** | Traffic-aware estimation with time-of-day multipliers, weekend adjustments, and rest period buffers for long-haul routes. |
| 📋 **LR Number Generation** | Atomic, collision-free Lorry Receipt generation via Firestore transactions. Format: `TN-TR-2026-000234`. |
| 📍 **Live GPS Tracking** | Real-time tracking on Google Maps with polyline routes, speed/heading data, and GPS drift filtering (≤20m accuracy). |
| 📸 **ePOD System** | Electronic Proof of Delivery — image capture, Firebase Storage upload, geo-tagged metadata, and business-side verification. |
| ✅ **GST Verification** | GSTIN format validation (regex + state code) with Firestore database lookup. Includes seed data for 10 Indian states. |
| ⚡ **Delay Detection** | Automated delay monitoring — auto-updates shipment status and applies trust score penalties. |
| 📊 **AI Dashboard Insights** | Real-time AI-generated insights summarizing shipment health, fraud alerts, and operational warnings. |
| 🔐 **Role-Based Access** | Separate flows for Business Owners and Transporters — enforced via Firebase Auth + Firestore Security Rules. |

<br/>

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐     │
│  │ Screens  │ │ Providers│ │ Services │ │ Repositories │     │
│  │  (UI)    ├─┤ (State)  ├─┤ (Logic)  ├─┤ (Firestore)  │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘     │
└─────────────────────────┬────────────────────────────────────┘
                          │
                 ┌────────▼────────┐
                 │   Firebase SDK  │
                 └────────┬────────┘
                          │
       ┌──────────────────┼──────────────────┐
       │                  │                  │
┌──────▼──────┐  ┌────────▼───────┐  ┌──────▼───────────┐
│  Firestore  │  │ Cloud Functions│  │ Firebase Storage │
│ (Database)  │  │  (Gemini AI)   │  │  (ePOD Images)   │
└─────────────┘  └────────┬───────┘  └──────────────────┘
                          │
                 ┌────────▼────────┐
                 │  Google Gemini  │
                 │  2.0 Flash API  │
                 └─────────────────┘
```

<br/>

## 🛠️ Tech Stack

| Layer | Technology | Version | Purpose |
|:---|:---|:---|:---|
| Frontend | Flutter | 3.x (SDK ^3.9.2) | Cross-platform mobile UI |
| Language | Dart | ^3.9.2 | Application logic & type safety |
| Backend | Firebase Firestore | ^6.2.0 | Real-time NoSQL database |
| Auth | Firebase Authentication | ^6.3.0 | Email/Password + role-based registration |
| Storage | Firebase Storage | ^13.2.0 | Secure ePOD image storage |
| AI/ML | Google Gemini 2.0 Flash | via Cloud Functions | Trust reports, fraud analysis, predictions |
| Cloud Functions | Firebase Functions | ^4.2.0 | Server-side AI orchestration (Node.js 22) |
| State | Provider | ^6.1.5 | Reactive state management |
| Routing | GoRouter | ^17.1.0 | Declarative navigation |
| Maps | Google Maps Flutter | ^2.9.0 | Live shipment tracking |
| Location | Geolocator | ^13.0.2 | GPS streaming with accuracy filtering |
| Typography | Google Fonts (Inter) | ^8.0.2 | Material 3 design system |
| QR | qr_flutter | ^4.1.0 | Shipment QR code generation |
| Crypto | crypto | ^3.0.3 | Image hash for fraud detection |

<br/>

## 📁 Project Structure

```
TrustNet AI 3.0/
└── mobile_app/
    ├── lib/
    │   ├── main.dart                       # App entry, Firebase init, Provider tree
    │   ├── firebase_options.dart           # FlutterFire auto-generated config
    │   │
    │   ├── models/
    │   │   ├── user_model.dart             # User model (business/transporter + AI fields)
    │   │   ├── shipment_model.dart         # Shipment model (30+ fields incl. AI metadata)
    │   │   └── shipment_status.dart        # Status enum: pending → assigned → in_transit → delayed → delivered
    │   │
    │   ├── services/
    │   │   ├── gemini_service.dart          # Gemini AI via Cloud Functions
    │   │   ├── trust_score_service.dart     # Weighted trust score engine
    │   │   ├── fraud_detection_service.dart # GPS jump, speed, route deviation detection
    │   │   ├── smart_assignment_service.dart# Transporter ranking algorithm
    │   │   ├── eta_service.dart             # Traffic-aware predictive ETA
    │   │   ├── delay_detection_service.dart # Auto-delay detection & penalties
    │   │   ├── lr_generator_service.dart    # Atomic LR number generation
    │   │   ├── location_service.dart        # GPS streaming + fraud integration
    │   │   ├── gst_verification_service.dart# GSTIN validation + Firestore lookup
    │   │   ├── firebase_service.dart        # Base Firebase service
    │   │   └── firestore_shipment_service.dart # Shipment CRUD
    │   │
    │   ├── providers/
    │   │   ├── ai_provider.dart             # Central AI state manager
    │   │   ├── user_provider.dart           # Auth & profile management
    │   │   ├── business_shipment_provider.dart
    │   │   └── transporter_shipment_provider.dart
    │   │
    │   ├── repositories/
    │   │   └── shipment_repository.dart     # Firestore CRUD, ePOD upload, status transitions
    │   │
    │   ├── screens/
    │   │   ├── onboarding/                  # Splash, role selection, login, register
    │   │   ├── business/                    # Dashboard, tracking, trust scores, AI reports
    │   │   ├── transporter/                 # Dashboard, marketplace, ePOD upload, AI reports
    │   │   ├── shared/                      # Notifications, profile, shipment history
    │   │   └── profile/                     # Edit profile, settings, password
    │   │
    │   ├── widgets/                         # App drawer, layout wrapper, trust gauge
    │   ├── routes/app_router.dart           # GoRouter config (25+ routes)
    │   ├── theme/                           # Material 3 theme + color palette
    │   └── utils/                           # Test data generator
    │
    ├── functions/
    │   ├── index.js                         # Cloud Functions (trust calc + AI reports)
    │   └── package.json                     # Node.js 22 dependencies
    │
    ├── firestore.rules                      # Firestore security rules
    ├── storage.rules                        # Storage security rules
    ├── firebase.json                        # Firebase project config
    └── pubspec.yaml                         # Flutter dependencies
```

<br/>

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|:---|:---|
| Flutter SDK | >= 3.0.0 |
| Dart | >= 3.9.2 (bundled) |
| Android Studio / VS Code | Latest, with Flutter & Dart extensions |
| Firebase CLI | Latest |
| Node.js | 22 (for Cloud Functions) |
| Google Cloud Project | With Gemini API enabled |

```bash
# Verify setup
flutter doctor
node --version        # v22.x
firebase --version
```

### Installation

```bash
# Clone
git clone https://github.com/prajyotpatil-dev/TrustNetAI.git
cd TrustNetAI/mobile_app

# Flutter dependencies
flutter pub get

# Cloud Functions dependencies
cd functions && npm install && cd ..
```

<br/>

## 🔥 Firebase Setup

**1. Create Project** — Go to [Firebase Console](https://console.firebase.google.com), create `trustnet-ai` (region: `asia-south1`)

**2. Enable Services:**

| Service | Configuration |
|:---|:---|
| Firestore Database | Production mode, `asia-south1` |
| Authentication | Email/Password provider |
| Storage | Default security rules |

**3. Register Apps:**
- **Android** — Package name: `com.trustnetai.app` → download `google-services.json` → place in `android/app/`
- **iOS** — Bundle ID: `com.trustnetai.app` → download `GoogleService-Info.plist` → place in `ios/Runner/`

**4. Configure FlutterFire:**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**5. Deploy Rules & Functions:**

```bash
firebase deploy --only firestore:rules,storage:rules
firebase deploy --only functions
```

<details>
<summary><b>📄 Firestore Security Rules</b></summary>

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /shipments/{shipmentId} {
      allow read: if request.auth != null && (
        resource.data.businessId == request.auth.uid ||
        resource.data.transporterId == request.auth.uid ||
        resource.data.transporterId == "" ||
        resource.data.transporterId == null
      );

      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if false;
    }

    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

</details>

<details>
<summary><b>📄 Storage Security Rules</b></summary>

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /epod/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

</details>

<br/>

## 🔑 Cloud Functions & Gemini API

All Gemini AI calls are routed through **Firebase Cloud Functions** — zero client-side API key exposure.

### Deployed Functions

| Function | Type | Description |
|:---|:---|:---|
| `calculateTrustScore` | Firestore Trigger | Fires on `shipments` write — recalculates transporter trust score |
| `generateTrustReport` | Firestore Trigger | Fires on `users` update — auto-generates AI report on score change |
| `generateAIReport` | HTTPS Callable | On-demand from Flutter — `trust_report`, `fraud_analysis`, `delivery_prediction` |

### Gemini API Key

```bash
# Set API key for Cloud Functions
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY"

# Deploy
firebase deploy --only functions
```

### Google Maps API Key

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_MAPS_API_KEY"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_MAPS_API_KEY")
```

<br/>

## ▶️ Running the App

```bash
flutter run                          # Debug mode
flutter run -d <device_id>           # Specific device

flutter build apk --release          # Release APK
flutter build appbundle --release     # Play Store bundle
flutter build ipa                     # iOS (macOS + Xcode required)
```

<br/>

## 🧠 Trust Score Algorithm

The trust engine runs **client-side** (quick incremental updates) and **server-side** (Firestore-triggered full recalculation).

### Weighted Formula

```
trustScore = (onTimeRate × 40) + (proofRate × 20) + (gpsScore × 15)
           + (cancelPenalty × 15) + (ratingScore × 10)
```

| Factor | Weight | Calculation |
|:---|:---:|:---|
| On-Time Delivery | 40% | `onTimeDeliveries / completedDeliveries × 40` |
| ePOD Compliance | 20% | `shipmentsWithProof / totalShipments × 20` |
| GPS Reliability | 15% | `min(gpsUpdates / expectedUpdates, 1) × 15` |
| Cancellation Penalty | 15% | `(1 - cancelled/total) × 15` |
| Average Rating | 10% | `(avgRating / 5.0) × 10` |

### Score Flow

```
Shipment Event (deliver / delay / ePOD upload)
    │
    ├──► Client: quickScoreUpdate() — instant ±8 / ±15 / ±5 adjustment
    │
    └──► Server: calculateTrustScore() — full recalculation (Firestore trigger)
              │
              └──► generateTrustReport() — Gemini AI report auto-generated
```

### Gemini AI Report Types

1. **Trust Report** — Assessment, strengths, risk factors, recommendation, suggested actions
2. **Fraud Analysis** — Risk level, suspicious patterns, detailed assessment, recommended actions
3. **Delivery Prediction** — Delay probability, failure risk, expected behavior, optimal use cases

<br/>

## 🛡️ Fraud Detection Engine

Real-time rule-based anomaly detection during GPS tracking:

| Check | Threshold |
|:---|:---|
| **GPS Teleport** | >10 km displacement in <2 minutes |
| **Unrealistic Speed** | >120 km/h |
| **Route Deviation** | >2 km from expected route |
| **Proof Location Mismatch** | >1 km from delivery coordinates |
| **Image Reuse** | Same image hash on different shipments |

All flags are persisted to Firestore and factored into trust score calculations.

<br/>

## 📱 App Screens

<details>
<summary><b>Business Owner Flow (9 screens)</b></summary>

| Screen | Route | Description |
|:---|:---|:---|
| Dashboard | `/business/dashboard` | KPI cards, AI insights, shipment overview |
| Track Shipments | `/business/track` | All shipments with status filters |
| Live Tracking | `/business/track/:id` | Google Maps with real-time GPS |
| Trust Scores | `/business/trust-score` | Network-wide trust analytics |
| AI Risk Report | `/business/risk-report` | Gemini-powered risk assessments |
| Network Trust | `/business/network-trust` | Transporter trust leaderboard |
| Smart Assignment | `/business/smart-assign` | AI transporter ranking & assignment |
| QR Code | `/business/qr/:id` | Shipment verification QR |
| View ePOD | `/business/view-epod/:id` | ePOD viewer & verification |

</details>

<details>
<summary><b>Transporter Flow (6 screens)</b></summary>

| Screen | Route | Description |
|:---|:---|:---|
| Dashboard | `/transporter/dashboard` | Personal KPIs & active shipments |
| Marketplace | `/transporter/marketplace` | Browse & accept available shipments |
| Create Shipment | `/transporter/create` | New shipment entry form |
| Update Status | `/transporter/update-status/:id` | Status transition workflow |
| Upload ePOD | `/transporter/upload-epod/:id` | Camera capture & upload |
| AI Trust Report | `/transporter/ai-report` | Self-view AI assessment |

</details>

<br/>

## 🔒 Security

- **No client-side API keys** — All Gemini calls routed through Cloud Functions
- **Firestore Rules** — Shipment-level access scoping (users only see their own data)
- **Storage Rules** — ePOD uploads restricted to authenticated users
- **GPS drift filtering** — Accuracy ≤20m enforced, unreliable data rejected
- **Deletion disabled** — `allow delete: if false` at the rules level
- **Recommended** — Enable Firebase App Check for production

<br/>

## 🤝 Contributing

```bash
# Fork → Clone → Branch
git checkout -b feature/your-feature-name

# Develop → Commit
git commit -m "feat: add route optimization to smart assignment"

# Push → Open PR
git push origin feature/your-feature-name
```

**Code quality:**

```bash
flutter analyze          # Static analysis
flutter test             # Run tests
dart format lib/         # Format code
```

<br/>

## 📄 License

This project is licensed under the **MIT License** — see below.

<details>
<summary>View full license text</summary>

```
MIT License

Copyright (c) 2026 TrustNet AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

</details>

<br/>

## 📬 Contact

**Built for the [GDG Solution Challenge — Build with AI](https://developers.google.com/community/gdsc-solution-challenge) Hackathon**

| | |
|:---|:---|
| **Author** | Prajyot Patil |
| **Email** | prajyotpatil.dev@gmail.com |
| **LinkedIn** | [linkedin.com/in/your-profile](https://linkedin.com/in/your-profile) |
| **GitHub** | [github.com/prajyotpatil-dev](https://github.com/prajyotpatil-dev) |

### Acknowledgements

- [Flutter](https://flutter.dev) — Cross-platform mobile framework
- [Firebase](https://firebase.google.com) — Backend-as-a-Service by Google
- [Google Gemini](https://ai.google.dev) — Next-generation AI models
- [Google Developer Groups](https://developers.google.com/community/gdg) — Hackathon organizers
- [Google Maps Platform](https://developers.google.com/maps) — Location & mapping services

---

<p align="center">
  Made with ❤️ for Indian Logistics · Powered by Google AI
</p>
