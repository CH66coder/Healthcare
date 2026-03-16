# HealthCare Pro — Setup Guide
## Team Targaryens | ETE 6.0

---

## 📁 Project Structure

```
healthcare_project/
├── patient_app/          ← Patient's Flutter app (Android phone)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── screens/
│   │   │   ├── auth_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── chat_screen.dart          ← MediBot chatbot
│   │   │   ├── doctors_screen.dart       ← Reads 'doctors' collection
│   │   │   ├── appointment_booking_screen.dart
│   │   │   ├── appointments_screen.dart  ← Video call button here
│   │   │   ├── pharmacy_screen.dart      ← Reads 'medicines' collection
│   │   │   ├── lab_test_screen.dart
│   │   │   ├── health_records_screen.dart
│   │   │   └── video_call_screen.dart    ← Jitsi (patient side)
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   └── gemini_service.dart
│   │   ├── models/
│   │   │   └── message_model.dart
│   │   ├── widgets/
│   │   │   ├── text_message.dart
│   │   │   ├── action_buttons.dart
│   │   │   ├── checklist_widget.dart
│   │   │   └── pharmacy_selector.dart
│   │   └── utils/
│   │       └── constants.dart            ← Add Gemini API key here
│   └── pubspec.yaml
│
└── doctor_app/           ← Doctor's Flutter app (Windows laptop)
    ├── lib/
    │   ├── main.dart
    │   ├── firebase_options.dart
    │   ├── screens/
    │   │   ├── doctor_auth_screen.dart
    │   │   ├── doctor_home_screen.dart   ← Incoming call popup here
    │   │   ├── prescription_screen.dart  ← Searches 'medicines' collection
    │   │   └── video_call_screen_doctor.dart ← Jitsi (doctor side)
    │   └── services/
    │       └── doctor_firebase_service.dart
    └── pubspec.yaml

---

## 🔑 Step 1 — Add Your Gemini API Key

Open `patient_app/lib/utils/constants.dart` and replace:
```dart
static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

---

## 🔥 Step 2 — Enable Firebase Auth

1. Go to https://console.firebase.google.com
2. Open project: **healthcare-chatbot-ee6cc**
3. Click **Authentication** → **Get started**
4. Enable **Email/Password** provider
5. That's it — both apps share the same Firebase project

---

## 🔥 Step 3 — Firestore Security Rules

In Firebase Console → Firestore → Rules, paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Doctors & medicines — read by anyone logged in
    match /doctors/{doc} {
      allow read: if request.auth != null;
    }
    match /medicines/{doc} {
      allow read: if request.auth != null;
    }
    // Users — only themselves
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    // Appointments — patient or doctor can read/write
    match /appointments/{doc} {
      allow read, write: if request.auth != null;
    }
    // Prescriptions — patient reads, doctor writes
    match /prescriptions/{doc} {
      allow read, write: if request.auth != null;
    }
    // Video calls — both can read/write
    match /video_calls/{doc} {
      allow read, write: if request.auth != null;
    }
    // Orders, lab tests, chat history
    match /{collection}/{doc} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 📱 Step 4 — Run Patient App (Android)

```bash
cd patient_app
flutter pub get
flutter run
```

---

## 💻 Step 5 — Run Doctor App (Windows Laptop)

```bash
cd doctor_app
flutter pub get
flutter run -d windows
```

---

## 🎥 Video Call Flow (End-to-End)

```
1. Doctor confirms appointment in doctor_app
   → appointment status: 'confirmed'

2. Patient sees "Start Video Call" button in Appointments screen

3. Patient taps it
   → Firestore: video_calls/{appointmentId} = {status: 'waiting', roomName: '...'}

4. Doctor app gets real-time popup: "Incoming call from [Patient]"

5. Doctor taps "Accept"
   → Firestore: status → 'accepted'
   → Both join same Jitsi room: https://meet.jit.si/{roomName}

6. Call ends → status → 'ended'
```

---

## 💊 Prescription → Chatbot Integration

```
1. Doctor writes prescription with specialist referral
   (e.g. "refer to dermatologist")

2. This creates a 'referrals' document in Firestore

3. Patient opens their app → Health Records → Prescriptions
   → sees the prescription with medicines

4. Patient can tap the referral → opens ChatScreen 
   pre-filled with specialist + medicines
   → shows "Book dermatologist Appointment" button directly
```

---

## ❗ Firestore Field Names (exact match to your CSV)

**doctors collection:**
- `name` — doctor name
- `specialty` — lowercase with hyphens (e.g. "dermatologist")
- `experience_years` — number
- `consultation_fee` — number
- `rating` — number
- `bangalore_location` — string

**medicines collection:**
- `Name` — medicine name (capital N)
- `Category` — e.g. "Antifungal"
- `Dosage Form` — e.g. "Tablet"
- `Strength` — e.g. "500mg"
- `Manufacturer` — string
- `Indication` — string
- `Classification` — "Over-the-Counter" or "Prescription"

---

## 🆘 SOS
SOS is being handled separately by your teammate.
When ready, add a FloatingActionButton in `home_screen.dart`
that navigates to the SOS screen.
