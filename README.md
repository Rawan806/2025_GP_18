
# Wadi’ah: Smart Lost & Found (Al-Masjid Al-Haram)

## 1) Introduction

Wadi’ah is a smart lost-and-found system for Al-Masjid Al-Haram. It provides an AI-powered mobile app that helps pilgrims and staff report, track, and recover lost items quickly and securely, with bilingual (Arabic/English) support.

## 2) Goal 

The goal of Wadi’ah is to streamline the entire lost-and-found process by combining intelligent item matching, real-time status tracking, and secure verification into one integrated platform that improves efficiency for staff and enhances the experience for millions of visitors.


## 2) Technology

* **Mobile app:** Flutter (Dart) for Android & iOS, AR/EN localization with RTL/LTR support
* **AI (on device):** TensorFlow Lite with a lightweight backbone (e.g., MobileNetV3-Small) to extract embeddings; optional OCR for visible text on items
* **Cloud backend:** Firebase (Authentication, Cloud Firestore, Cloud Storage, Cloud Functions)
* **Notifications:** Licensed SMS gateway for candidate-match alerts (PDPL-aware consent/retention)
* **Security & audit:** Role-based access (visitor/staff), PIN-verified office handover, immutable audit logs
* **Prototyping/Dev:** Google Colab (model pipeline prototyping), Android Studio/Xcode, GitHub, Figma

## 3) Launching Instructions (brief)

1. **Prerequisites**

   * Install Flutter SDK and set up Android Studio and/or Xcode.
   * Create a Firebase project and register Android and iOS apps.
   * Obtain an SMS gateway account (API key and sender ID).
   * Prepare the TFLite model file and place it in the app assets.

2. **Configure the mobile app**

   * Add Firebase configuration files to the Android and iOS projects.
   * Register the model file in app assets and enable AR/EN with RTL/LTR in the app settings.
   * Install required Flutter packages and verify the app builds on both platforms.

3. **Configure Firebase services**

   * Enable Authentication (e.g., email/password or your chosen provider).
   * Create Cloud Firestore and define Security Rules for visitor/staff/admin roles.
   * Set up Cloud Storage buckets for item photos with aligned access rules.
   * Configure Cloud Functions environment variables for the SMS gateway and deploy Functions.

4. **Run and verify**

   * Launch the app on a device.
   * Sign in and validate the two flows:

     * Visitor: create a lost report with photos; observe status updates.
     * Staff: capture a found item; confirm that on-device feature extraction runs and records are created.
   * Trigger a test candidate match and confirm that a staff member’s approval sends a single SMS alert and updates the in-app status.

5. **Testing notes**

   * Use a non-production SMS sender ID or a mock mode during development to avoid sending real messages.
   * Confirm that audit logs record critical actions (intake, match review, handover) and that PDPL-aligned consent and retention are applied.


