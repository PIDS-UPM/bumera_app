
---

# **BUMERA Demo Application**  

## **Overview**  
The **BUMERA Demo Application** is a mobile app designed to address and manage bullying incidents in a school environment. It integrates Firebase for authentication, notifications, and analytics to provide a seamless and secure user experience.  

## **Features**  
- **Authentication:** User login and registration using Firebase Auth.  
- **Notification System:** Real-time notifications for bullying incidents using Firebase Cloud Messaging (FCM).  
- **Incident Reporting:** A platform to report and monitor bullying incidents.  
- **User Roles:** Separate views and functionalities for students, teachers, and administrators.  
- **Firebase Analytics:** Track user interactions for better insights.  

## **Directory Structure**  

```plaintext
lib
├── firebase_options.dart
├── main.dart
├── screens
│   ├── add_incidence.dart
│   ├── bullying_history.dart
│   ├── detailed_class_statistics.dart
│   ├── detailed_emotions.dart
│   ├── detailed_incidence.dart
│   ├── home_page.dart
│   ├── profile_page.dart
│   ├── sign_in_page.dart
│   └── students_emotions.dart
├── services
│   ├── auth_service.dart
│   └── notification_service.dart
├── theme
│   └── app_theme.dart
└── widgets
    ├── custom_drawer.dart
    └── notification_dialog.dart
```

## **Setup and Installation**  

### Prerequisites  
- Flutter 3.24.5 or later installed  
- Android Studio / Xcode for emulation and development  
- Firebase project configured with necessary services (Auth, Firestore, FCM)  

### Steps  
1. Clone the repository:  
   ```bash
   git clone https://github.com/your-username/bumera-demo-app.git
   cd bumera-demo-app
   ```
2. Install dependencies:  
   ```bash
   flutter pub get
   ```
3. Configure Firebase:  
   - Add the `google-services.json` file to the `android/app` directory.   

4. Run the app:  
   ```bash
   flutter run
   ```

## **Dependencies**  
The project uses the following key packages:  
- `firebase_core`  
- `firebase_auth`  
- `firebase_messaging`  
- `firebase_analytics`  
- `flutter_local_notifications`  

For a full list, refer to the [`pubspec.yaml`](pubspec.yaml) file.  

## **Usage**  
1. Launch the app.  
2. Sign in or create an account.  
3. Access the dashboard to report or view bullying incidents.  
4. Administrators and teachers can monitor incidents in real time.  

