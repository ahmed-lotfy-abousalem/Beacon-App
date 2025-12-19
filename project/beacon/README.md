# BEACON - Disaster Response Communication App

## 📱 Overview
BEACON is a Flutter-based disaster response communication app designed to help people stay connected during emergencies. The app provides essential communication tools, resource sharing capabilities, and emergency contact management using WiFi Direct P2P networking.

## 🏗️ Project Architecture
This project uses **MVVM (Model-View-ViewModel)** architecture pattern for clean code separation and scalability.

### Architecture Layers
```
Presentation Layer (MVVM)
├── Views (UI) → lib/presentation/pages/
└── ViewModels (Logic) → lib/presentation/viewmodels/

Service Layer
└── Services → lib/services/

Data Layer
└── Database & Models → lib/data/
```

## 📚 Documentation

### Quick Start
- **[README_MVVM.md](README_MVVM.md)** - MVVM implementation overview and getting started
- **[MVVM_QUICK_CARD.md](MVVM_QUICK_CARD.md)** - One-page quick reference (print this!)

### Detailed Guides
- **[MVVM_ARCHITECTURE_GUIDE.md](MVVM_ARCHITECTURE_GUIDE.md)** - Complete MVVM theory and concepts
- **[MVVM_BEFORE_AFTER.md](MVVM_BEFORE_AFTER.md)** - Code examples showing refactoring benefits
- **[MVVM_QUICK_START.md](MVVM_QUICK_START.md)** - Week-by-week implementation checklist
- **[MVVM_DIAGRAMS.md](MVVM_DIAGRAMS.md)** - Visual architecture and data flow diagrams
- **[MVVM_IMPLEMENTATION_GUIDE.md](MVVM_IMPLEMENTATION_GUIDE.md)** - Complete implementation reference

### Setup & Installation
- **[INSTALL_ANDROID.md](INSTALL_ANDROID.md)** - Android setup instructions
- **[WIFI_DIRECT_SETUP.md](WIFI_DIRECT_SETUP.md)** - WiFi Direct configuration guide

## 🎯 Features

### 🏠 Landing Page
- Join existing emergency networks
- Create new emergency networks
- Emergency-themed red color scheme

### 📊 Network Dashboard
- View connected devices and teams
- Signal strength indicators
- Last seen timestamps
- Action buttons for device management

### 💬 Chat Page
- Real-time messaging over WiFi Direct
- Speech-to-text input (voice recognition)
- Text-to-speech output (hear messages aloud)
- Socket connection status indicator
- User avatars and message timestamps

### 👤 Profile Page
- User profile management
- Emergency contact information
- Device identification

### 📦 Resource Page
- Share emergency resources
- Resource availability tracking
- Community resource network

## 🛠️ Technology Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Provider (ChangeNotifier)
- **Database**: SQLite with SQLCipher (encrypted)
- **Networking**: WiFi Direct (P2P)
- **Speech**: Speech-to-Text & Text-to-Speech
- **Storage**: Flutter Secure Storage

## 📁 Project Structure

```
lib/
├── main.dart                           # App entry point
├── data/                               # Data Layer
│   ├── models.dart                     # Data models
│   └── database_service.dart           # Database operations
├── services/                           # Service Layer
│   ├── messaging_service.dart          # Chat messaging
│   ├── wifi_direct_service.dart        # WiFi Direct P2P
│   ├── speech_to_text_service.dart     # Voice recognition
│   └── text_to_speech_service.dart     # Voice synthesis
├── presentation/                       # Presentation Layer (MVVM)
│   ├── base_view_model.dart            # Base ViewModel class
│   ├── viewmodels/                     # Business logic
│   │   ├── chat_view_model.dart
│   │   └── profile_view_model.dart
│   └── pages/                          # UI Views
│       └── chat_page_mvvm.dart
├── pages/                              # Original pages (legacy)
│   ├── chat_page.dart
│   ├── profile_page.dart
│   ├── landing_page.dart
│   ├── network_dashboard_page.dart
│   └── resource_page.dart
└── providers/                          # App-level state
    └── beacon_provider.dart

test/                                   # Unit and widget tests
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android SDK 23+
- iOS 12+

### Installation
```bash
# Clone the repository
git clone <repository-url>

# Navigate to project
cd Beacon-App/project/beacon

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### MVVM Migration
The project is undergoing MVVM architecture migration. See [README_MVVM.md](README_MVVM.md) for:
- ✅ Complete MVVM foundation with working examples
- ✅ BaseViewModel infrastructure
- ✅ ChatViewModel + ChatPageMVVM examples
- ✅ ProfileViewModel for reference
- ✅ Week-by-week migration guide
- ✅ Comprehensive documentation (6+ guides)

## 🔧 Development

### Architecture Pattern
This project uses **MVVM (Model-View-ViewModel)**:
- **Model**: Data models in `lib/data/`
- **View**: UI in `lib/presentation/pages/`
- **ViewModel**: Business logic in `lib/presentation/viewmodels/`

### Adding New Features
1. Create a ViewModel extending `BaseViewModel`
2. Create a Page widget using `Consumer<YourViewModel>`
3. Follow the patterns in [ChatViewModel](lib/presentation/viewmodels/chat_view_model.dart) and [ChatPageMVVM](lib/presentation/pages/chat_page_mvvm.dart)

## 📝 Available Commands

```bash
# Run the app
flutter run

# Run with specific device
flutter run -d <device-id>

# Build release APK
flutter build apk

# Build iOS app
flutter build ios

# Run tests
flutter test

# Check code quality
flutter analyze

# Format code
flutter format lib/
```

## 🐛 Known Issues & Limitations
- WiFi Direct connection requires both devices on same network
- Some speech recognition features may vary by device
- Text-to-speech requires internet on some devices

## 📞 Support & Documentation
For detailed implementation information, see the MVVM documentation in the root directory:
- Architecture questions? → [MVVM_ARCHITECTURE_GUIDE.md](MVVM_ARCHITECTURE_GUIDE.md)
- Implementation help? → [MVVM_QUICK_START.md](MVVM_QUICK_START.md)
- Need code examples? → [MVVM_BEFORE_AFTER.md](MVVM_BEFORE_AFTER.md)
- Visual learner? → [MVVM_DIAGRAMS.md](MVVM_DIAGRAMS.md)

## 📄 License
This project is licensed under the MIT License - see LICENSE file for details.

## 👥 Contributors
- Development Team

---

**Last Updated**: December 19, 2025
**Architecture**: MVVM Pattern
**Status**: Active Development
