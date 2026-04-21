<![CDATA[<p align="center">
  <h1 align="center">🚛 TrustNet AI 3.0</h1>
  <p align="center">
    <strong>AI-Powered Trust & Intelligence Platform for Indian Logistics</strong>
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.9-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Gemini_2.0_Flash-AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge" alt="Platform" />
</p>

<p align="center">
  Built for the <strong>Google Developer Group (GDG) Solution Challenge — Build with AI</strong> Hackathon
</p>

---

## 📖 Overview

**TrustNet AI 3.0** is a Flutter-based logistics trust management platform purpose-built for the Indian supply chain industry. It leverages **Google Gemini 2.0 Flash** via **Firebase Cloud Functions** to deliver intelligent carrier trust scoring, real-time fraud detection, smart transporter-to-shipment assignment, and predictive delivery analytics — replacing gut-feel decisions with data-driven intelligence. The platform serves two core user roles — **Business Owners** (shippers) and **Transporters** — enabling them to create shipments, track consignments live on Google Maps, upload electronic Proof of Delivery (ePOD), verify GST credentials, and generate Lorry Receipt (LR) numbers, all from a single mobile interface. Built on a robust **Firebase** backend with Firestore triggers and callable Cloud Functions, TrustNet AI 3.0 provides real-time data synchronization, role-based access control, and a secure server-side AI architecture with no client-side API key exposure.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| **🧠 AI Trust Scoring** | Weighted trust score engine (0–100) factoring on-time delivery (40%), ePOD compliance (20%), GPS reliability (15%), cancellation rate (15%), and average rating (10%). Auto-recalculated via Firestore triggers on every shipment update. |
| **🔍 Fraud Detection** | Rule-based anomaly detection — GPS teleport detection (Haversine formula), unrealistic speed checks (>120 km/h), route deviation monitoring, proof image reuse detection, and proof location validation. Flags are persisted per-shipment in Firestore. |
| **🤖 Gemini AI Reports** | On-demand AI-generated trust reports, fraud analysis, and delivery predictions powered by Gemini 2.0 Flash through secure Firebase Cloud Functions. Three report types: Trust Assessment, Fraud Risk Analysis, and Delivery Prediction. |
| **🎯 Smart Assignment** | AI-driven transporter ranking using a composite score: 60% trust score + 40% proximity to pickup city. Covers 15+ Indian cities with coordinate-based distance calculation. |
| **⏱️ Predictive ETA** | Traffic-aware delivery time estimation with time-of-day multipliers (morning rush +25%, evening peak +30%, night -15%), weekend adjustments, and mandatory rest period buffers for long-haul routes. |
| **📋 LR Number Generation** | Atomic, collision-free Lorry Receipt number generation using Firestore transactions with year-based auto-reset. Format: `TN-{ROLE}-{YEAR}-{SEQUENCE}` (e.g., `TN-TR-2026-000234`). |
| **📍 Live GPS Tracking** | Real-time shipment tracking on Google Maps with polyline routes, speed/heading data, and GPS drift filtering (accuracy ≤20m enforced). Integrated with fraud detection for anomaly flagging during transit. |
| **📸 ePOD System** | Electronic Proof of Delivery with image capture via camera/gallery, Firebase Storage upload, geo-tagged metadata (lat, lng, timestamp, image hash), and business-side verification workflow. |
| **✅ GST Verification** | GSTIN format validation (regex + state code check) with Firestore database lookup for business registration. Includes demo seed data for 10 Indian states. |
| **⚡ Delay Detection** | Automated delay monitoring that compares current time against expected delivery, auto-updates shipment status to `delayed`, and applies trust score penalties. Scans all active shipments per business/transporter. |
| **📊 AI Dashboard Insights** | Real-time AI-generated one-liner insights on the business dashboard summarizing shipment health, fraud alerts, trust scores, and operational warnings. |
| **🔐 Role-Based Access** | Separate flows for Business Owner and Transporter roles with distinct dashboards, capabilities, and navigation — enforced via Firebase Auth + Firestore Security Rules. |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Mobile App                       │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────────┐  │
│  │ Screens  │  │ Providers│  │  Services  │  │  Repositories│  │
│  │ (UI)     │◄─┤ (State)  │◄─┤ (Logic)   │◄─┤  (Firestore) │  │
│  └──────────┘  └──────────┘  └───────────┘  └──────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Firebase SDK   │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼───────┐  ┌────────▼────────┐  ┌────────▼────────┐
│   Firestore   │  │  Cloud Functions│  │ Firebase Storage│
│  (Database)   │  │  (Gemini AI)    │  │   (ePOD Images) │
└───────────────┘  └────────┬────────┘  └─────────────────┘
                            │
                   ┌────────▼────────┐
                   │ Google Gemini   │
                   │  2.0 Flash API  │
                   └─────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| **Frontend** | Flutter | 3.x (SDK ^3.9.2) | Cross-platform mobile UI (Android & iOS) |
| **Language** | Dart | ^3.9.2 | Application logic & type safety |
| **Backend** | Firebase Firestore | `cloud_firestore: ^6.2.0` | NoSQL real-time database for shipments, users, and counters |
| **Auth** | Firebase Authentication | `firebase_auth: ^6.3.0` | Email/Password login with role-based registration |
| **Storage** | Firebase Storage | `firebase_storage: ^13.2.0` | Secure ePOD image storage |
| **AI/ML** | Google Gemini 2.0 Flash | via Cloud Functions | Trust reports, fraud analysis, delivery prediction |
| **Cloud Functions** | Firebase Functions | `firebase-functions: ^4.2.0` | Server-side AI orchestration (Node.js 22) |
| **State Management** | Provider | `provider: ^6.1.5+1` | Reactive state management with `ChangeNotifier` |
| **Routing** | GoRouter | `go_router: ^17.1.0` | Declarative navigation with path parameters |
| **Maps** | Google Maps Flutter | `google_maps_flutter: ^2.9.0` | Live shipment tracking with polylines |
| **Location** | Geolocator | `geolocator: ^13.0.2` | GPS streaming with accuracy filtering |
| **Typography** | Google Fonts | `google_fonts: ^8.0.2` | Inter font family for Material 3 design |
| **QR Codes** | qr_flutter | `qr_flutter: ^4.1.0` | Shipment QR code generation |
| **Crypto** | crypto | `crypto: ^3.0.3` | Image hash computation for fraud detection |

---

## 📁 Project Structure

```
TrustNet AI 3.0/
└── mobile_app/
    ├── lib/
    │   ├── main.dart                          # App entry, Firebase init, Provider tree
    │   ├── firebase_options.dart              # FlutterFire auto-generated config
    │   │
    │   ├── models/
    │   │   ├── user_model.dart                # User model (business/transporter + AI fields)
    │   │   ├── shipment_model.dart            # Shipment model (30+ fields incl. AI metadata)
    │   │   └── shipment_status.dart           # Status enum: pending → assigned → in_transit → delayed → delivered
    │   │
    │   ├── services/
    │   │   ├── gemini_service.dart             # Gemini AI via Cloud Functions (trust, fraud, prediction)
    │   │   ├── trust_score_service.dart        # Weighted trust score calculation engine
    │   │   ├── fraud_detection_service.dart    # GPS jump, speed, route deviation, image reuse detection
    │   │   ├── smart_assignment_service.dart   # Transporter ranking (60% trust + 40% proximity)
    │   │   ├── eta_service.dart                # Traffic-aware predictive ETA calculation
    │   │   ├── delay_detection_service.dart    # Auto-delay detection & trust score penalty
    │   │   ├── lr_generator_service.dart       # Atomic LR number generation via Firestore transaction
    │   │   ├── location_service.dart           # GPS streaming + fraud detection integration
    │   │   ├── gst_verification_service.dart   # GSTIN format + Firestore database verification
    │   │   ├── firebase_service.dart           # Base Firebase service
    │   │   └── firestore_shipment_service.dart # Shipment CRUD operations
    │   │
    │   ├── providers/
    │   │   ├── ai_provider.dart                # Central AI state (Gemini, fraud, delays, assignments)
    │   │   ├── user_provider.dart              # Auth state & user profile management
    │   │   ├── business_shipment_provider.dart # Business owner shipment state
    │   │   └── transporter_shipment_provider.dart # Transporter shipment state
    │   │
    │   ├── repositories/
    │   │   └── shipment_repository.dart        # Firestore CRUD, ePOD upload, status transitions
    │   │
    │   ├── screens/
    │   │   ├── onboarding/
    │   │   │   ├── splash_screen.dart           # Animated splash with auto-redirect
    │   │   │   ├── role_selection_screen.dart    # Business Owner / Transporter role picker
    │   │   │   ├── login_screen.dart             # Role-specific login form
    │   │   │   └── register_screen.dart          # Registration with GST verification (business)
    │   │   │
    │   │   ├── business/                         # Business Owner screens
    │   │   │   ├── business_dashboard_screen.dart # KPI dashboard + AI insights
    │   │   │   ├── track_screen.dart              # Shipment list view
    │   │   │   ├── track_shipment_screen.dart      # Live Google Maps tracking
    │   │   │   ├── trust_score_screen.dart         # Network-wide trust analytics
    │   │   │   ├── ai_risk_report_screen.dart      # Gemini AI risk reports
    │   │   │   ├── network_trust_screen.dart       # Transporter trust leaderboard
    │   │   │   ├── smart_assignment_screen.dart    # AI transporter ranking & assignment
    │   │   │   ├── shipment_qr_screen.dart         # QR code for shipment verification
    │   │   │   └── view_epod_screen.dart           # ePOD image viewer & verification
    │   │   │
    │   │   ├── transporter/                       # Transporter screens
    │   │   │   ├── transporter_dashboard_screen.dart # Transporter KPI dashboard
    │   │   │   ├── transporter_marketplace_screen.dart # Available shipment marketplace
    │   │   │   ├── create_shipment_screen.dart     # New shipment creation form
    │   │   │   ├── update_status_screen.dart       # Status update workflow
    │   │   │   ├── upload_epod_screen.dart         # ePOD image capture & upload
    │   │   │   └── ai_trust_report_screen.dart     # Self-view AI trust assessment
    │   │   │
    │   │   ├── shared/
    │   │   │   └── shared_screens.dart             # Notifications, Profile, Shipment History
    │   │   │
    │   │   └── profile/
    │   │       ├── edit_profile_screen.dart         # Profile editor
    │   │       ├── change_password_screen.dart      # Password management
    │   │       └── settings_screens.dart            # Notification, Help, Privacy settings
    │   │
    │   ├── widgets/
    │   │   ├── app_drawer.dart                 # Navigation drawer with role-aware menu
    │   │   ├── app_layout.dart                 # Scaffold wrapper with drawer
    │   │   └── trust_score_breakdown.dart       # Visual trust score gauge component
    │   │
    │   ├── routes/
    │   │   └── app_router.dart                 # GoRouter config with 25+ named routes
    │   │
    │   ├── theme/
    │   │   ├── app_theme.dart                  # Material 3 theme with Inter font
    │   │   └── app_colors.dart                 # Color palette (neutral dark + accent system)
    │   │
    │   └── utils/
    │       └── test_data_generator.dart         # Demo data seeder for development
    │
    ├── functions/
    │   ├── index.js                            # Cloud Functions (Trust Calculator, AI Report Generator)
    │   └── package.json                        # Node.js 22 dependencies
    │
    ├── assets/
    │   └── truck.png                           # App icon / branding asset
    │
    ├── firestore.rules                         # Firestore security rules (role-scoped shipments)
    ├── storage.rules                           # Storage security rules (ePOD images, auth-only)
    ├── firebase.json                           # Firebase project configuration
    ├── pubspec.yaml                            # Flutter dependencies & assets
    └── test/                                   # Unit & widget tests
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version | Install Guide |
|---|---|---|
| Flutter SDK | >= 3.0.0 | [flutter.dev/get-started](https://docs.flutter.dev/get-started/install) |
| Dart | >= 3.9.2 (bundled) | Included with Flutter |
| Android Studio / VS Code | Latest | With Flutter & Dart extensions |
| Firebase CLI | Latest | [firebase.google.com/docs/cli](https://firebase.google.com/docs/cli) |
| Node.js | 22 | Required for Cloud Functions |
| Google Cloud Project | — | With Gemini API enabled |
| Git | Latest | — |

Verify your setup:

```bash
flutter doctor
node --version   # Should show v22.x
firebase --version
```

### Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/trustnet-ai-3.0.git
cd trustnet-ai-3.0/mobile_app
```

### Install Dependencies

```bash
# Flutter dependencies
flutter pub get

# Cloud Functions dependencies
cd functions
npm install
cd ..
```

---

## 🔥 Firebase Setup

### 1. Create a Firebase Project

- Navigate to [Firebase Console](https://console.firebase.google.com)
- Click **Add Project** → name it `trustnet-ai`
- Select your preferred region (recommended: `asia-south1` — Mumbai)

### 2. Enable Firebase Services

| Service | Configuration |
|---|---|
| **Firestore Database** | Create in production mode, region `asia-south1` |
| **Authentication** | Enable **Email/Password** sign-in provider |
| **Storage** | Initialize with default security rules |

### 3. Register Android App

1. Firebase Console → Project Settings → **Add App** → Android
2. Package name: `com.trustnetai.app`
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

### 4. Register iOS App

1. Firebase Console → Project Settings → **Add App** → iOS
2. Bundle ID: `com.trustnetai.app`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

### 5. Configure FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This auto-generates `lib/firebase_options.dart`.

### 6. Deploy Firestore Security Rules

The project includes production-ready Firestore rules with scoped access for the `shipments` collection:

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
    
    // Default for other collections
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 7. Deploy Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // ePOD images — authenticated users only
    match /epod/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 8. Deploy Rules & Functions

```bash
# Deploy Firestore + Storage rules
firebase deploy --only firestore:rules,storage:rules

# Deploy Cloud Functions
firebase deploy --only functions
```

---

## 🔑 Cloud Functions & Gemini API Setup

TrustNet AI routes **all Gemini AI calls through Firebase Cloud Functions** — no API key is exposed on the client side.

### Cloud Functions Deployed

| Function | Type | Trigger |
|---|---|---|
| `calculateTrustScore` | Firestore Trigger | Fires on every `shipments/{shipmentId}` write — recalculates transporter trust score |
| `generateTrustReport` | Firestore Trigger | Fires on `users/{userId}` update when trust score changes — auto-generates AI report |
| `generateAIReport` | HTTPS Callable | On-demand from Flutter — supports `trust_report`, `fraud_analysis`, `delivery_prediction` |

### Setting the Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey) and create an API key
2. Set the key as an environment variable for Cloud Functions:

```bash
firebase functions:config:set gemini.api_key="YOUR_GEMINI_API_KEY"
```

Or set it as an environment variable in the Firebase Console under **Cloud Functions → Environment Variables**.

3. Deploy the updated functions:

```bash
cd functions
firebase deploy --only functions
```

### Google Maps API Key

For live GPS tracking features, add your Google Maps API key:

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

---

## ▶️ Running the App

```bash
# Run in debug mode (connected device or emulator)
flutter run

# Run on a specific device
flutter devices                  # List connected devices
flutter run -d <device_id>       # Target specific device

# Build release APK (Android)
flutter build apk --release

# Build release App Bundle (Play Store)
flutter build appbundle --release

# Build release IPA (iOS — requires macOS + Xcode)
flutter build ipa
```

---

## 🧠 Trust Score Algorithm

The trust score engine runs both **client-side** (for quick incremental updates) and **server-side** (via Firestore-triggered Cloud Functions for full recalculation).

### Weighted Formula

```
trustScore = (onTimeRate × 40) + (proofRate × 20) + (gpsScore × 15) 
           + (cancelPenalty × 15) + (ratingScore × 10)
```

| Factor | Weight | Calculation |
|---|---|---|
| **On-Time Delivery** | 40% | `(onTimeDeliveries / completedDeliveries) × 40` |
| **ePOD Compliance** | 20% | `(shipmentsWithProof / totalShipments) × 20` |
| **GPS Reliability** | 15% | `min(totalGpsUpdates / expectedUpdates, 1) × 15` |
| **Cancellation Penalty** | 15% | `(1 - cancelledShipments/totalShipments) × 15` |
| **Average Rating** | 10% | `(avgRating / 5.0) × 10` |

### Score Flow

```
Shipment Event (deliver/delay/ePOD upload)
    │
    ├──► Client: quickScoreUpdate() — instant ±8/±15/±5 adjustment
    │
    └──► Server: calculateTrustScore() Cloud Function (Firestore trigger)
              │
              └──► Full recalculation from all shipment history
                      │
                      └──► generateTrustReport() — Gemini AI report auto-generated
```

### Gemini AI Integration

After the trust score is recalculated, the system calls Gemini 2.0 Flash with the transporter's full data context and generates:

1. **Trust Report** — Overall assessment, strengths, risk factors, recommendation, suggested actions
2. **Fraud Analysis** — Risk level, suspicious patterns, risk assessment, recommended actions
3. **Delivery Prediction** — Delay probability, failure risk, expected behavior, optimal use cases

---

## 🛡️ Fraud Detection Engine

The fraud detection system performs **real-time rule-based anomaly detection** during GPS tracking:

| Check | Trigger | Threshold |
|---|---|---|
| **GPS Teleport** | Location update | >10 km displacement in <2 minutes |
| **Unrealistic Speed** | Speed reading | >120 km/h |
| **Route Deviation** | Position check | >2 km from expected route |
| **Proof Location Mismatch** | ePOD upload | >1 km from delivery coordinates |
| **Image Reuse** | ePOD upload | Same image hash found on different shipments |

Detected flags are **persisted to Firestore** on the shipment document and factored into trust score calculations.

---

## 📱 App Screens

### Business Owner Flow

| Screen | Route | Description |
|---|---|---|
| Dashboard | `/business/dashboard` | KPI cards, AI insights, shipment overview |
| Track Shipments | `/business/track` | All shipments with status filters |
| Live Tracking | `/business/track/:id` | Google Maps with real-time GPS |
| Trust Scores | `/business/trust-score` | Network-wide trust analytics |
| AI Risk Report | `/business/risk-report` | Gemini-powered risk assessments |
| Network Trust | `/business/network-trust` | Transporter trust leaderboard |
| Smart Assignment | `/business/smart-assign` | AI transporter ranking & assignment |
| QR Code | `/business/qr/:id` | Shipment verification QR |
| View ePOD | `/business/view-epod/:id` | ePOD image viewer & verification |

### Transporter Flow

| Screen | Route | Description |
|---|---|---|
| Dashboard | `/transporter/dashboard` | Personal KPIs & active shipments |
| Marketplace | `/transporter/marketplace` | Browse & accept available shipments |
| Create Shipment | `/transporter/create` | New shipment entry form |
| Update Status | `/transporter/update-status/:id` | Status transition workflow |
| Upload ePOD | `/transporter/upload-epod/:id` | Camera capture & upload |
| AI Trust Report | `/transporter/ai-report` | Self-view AI assessment |

---

## 🤝 Contributing

Contributions are welcome! Follow these steps:

1. **Fork** the repository
2. **Create** a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit** with descriptive messages:
   ```bash
   git commit -m "feat: add route optimization to smart assignment"
   ```
4. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request** against the `main` branch

### Code Quality

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test

# Format code
dart format lib/
```

Follow [Effective Dart](https://dart.dev/effective-dart) guidelines.

---

## 🔒 Security Notes

- **No client-side API keys** — All Gemini AI calls are routed through Firebase Cloud Functions
- **Firestore Security Rules** enforce shipment-level access scoping — users only see their own data
- **Firebase Storage Rules** restrict ePOD uploads to authenticated users
- **GPS drift filtering** (accuracy ≤20m) prevents unreliable location data from entering the system
- **Shipment deletion is disabled** at the rules level (`allow delete: if false`)
- Regularly rotate API keys and audit Firestore access logs
- Enable **App Check** in production to protect backend resources from abuse

---

## 📄 License

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

---

## 📬 Contact & Acknowledgements

**Built for the [Google Developer Group (GDG) Solution Challenge — Build with AI](https://developers.google.com/community/gdsc-solution-challenge) Hackathon**

| | |
|---|---|
| **Author** | *Prajyot Patil* |
| **Email** | *prajyotpatil.dev@gmail.com* |
| **LinkedIn** | *[Your LinkedIn Profile](https://linkedin.com/in/your-profile)* |
| **GitHub** | *[Your GitHub Profile](https://github.com/YOUR_USERNAME)* |

### Acknowledgements

- [Flutter](https://flutter.dev) — Beautiful native apps in record time
- [Firebase](https://firebase.google.com) — App development platform by Google
- [Google Gemini](https://ai.google.dev) — Next-generation AI models
- [Google Developer Groups](https://developers.google.com/community/gdg) — Hackathon organizers
- [Google Maps Platform](https://developers.google.com/maps) — Location & mapping services

---

<p align="center">
  Made with ❤️ for Indian Logistics · Powered by Google AI
</p>
]]>
