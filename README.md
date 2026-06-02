# Ruang IT - Frontend Application

![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.10.7-blue.svg)
![GetX](https://img.shields.io/badge/GetX-%5E4.6.6-purple.svg)

A modern, responsive Flutter application for **Ruang IT**, designed for reading, exploring, and engaging with IT-related articles.

## 🚀 Features

*   **Authentication**: Secure login and registration.
*   **Personalization**: Interest selection and intelligent topic recommendations tailored to users.
*   **Article Reading & Management**: Read, explore, and search for IT articles. Features rich text support.
*   **User Profiles**: Manage your personal profile and view author profiles.
*   **Dashboard & Explore**: Discover new, trending, and relevant content easily.
*   **Notifications**: Stay updated with the latest activities and platform updates.
*   **Onboarding**: Smooth introduction flow for new users.

## 🛠️ Tech Stack & Architecture

This project is built using the **GetX Pattern** to maintain a clean and scalable architecture, keeping UI, Business Logic, and Data layers separated.

*   **State Management & Routing**: [GetX](https://pub.dev/packages/get)
*   **Networking**: [Dio](https://pub.dev/packages/dio) with `dio_smart_retry`
*   **Local Storage**: [GetStorage](https://pub.dev/packages/get_storage) & [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
*   **UI/UX**: 
    *   [Google Fonts](https://pub.dev/packages/google_fonts)
    *   [Iconly](https://pub.dev/packages/iconly) & Cupertino Icons
    *   [Cached Network Image](https://pub.dev/packages/cached_network_image)
*   **Rich Text**: [Flutter Widget from HTML](https://pub.dev/packages/flutter_widget_from_html) & [Flutter Quill](https://pub.dev/packages/flutter_quill)

## 📁 Project Structure

```text
lib/
├── app/
│   ├── controllers/    # Global controllers
│   ├── data/           # Providers, models, and services (API, local DB)
│   ├── modules/        # Feature modules (Views, Bindings, and local Controllers)
│   ├── routes/         # Application routing definitions
│   └── widgets/        # Reusable global UI components
└── main.dart           # Application entry point
```

## 💻 Getting Started

To run this project locally, ensure you have Flutter installed on your machine.

### Prerequisites

*   Flutter SDK: `>=3.10.7`
*   Dart SDK
*   Android Studio / VS Code with Flutter extensions

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/Hanifun2310/front_and_ruang_it.git
    cd front_and_ruang_it
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the application:**

    ```bash
    flutter run
    ```

## 📦 App Modules (Features)

The app is modularized by feature within the `lib/app/modules/` directory:
*   `splash` - App initialization and splash screen.
*   `onboarding_finish` - Post-registration flow.
*   `auth` - Login, Signup, Password Recovery.
*   `interest_selection` & `topic_recommendation` - User content personalization.
*   `dashboard` - Main feed and user dashboard.
*   `explore` & `search` - Content discovery and global search.
*   `article` & `category_detail` - Core reading experience and category browsing.
*   `profile` & `author_profile` - User identity and author details.
*   `notifications` - In-app alerts and updates.
*   `guidelines` - App terms and operational guidelines.
