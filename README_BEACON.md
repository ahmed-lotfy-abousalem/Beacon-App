# BEACON - Disaster Response Communication App

## Overview
BEACON is a Flutter-based disaster response communication app designed to help people stay connected during emergencies. The app provides essential communication tools, resource sharing capabilities, and emergency contact management.

## Features

### 🏠 Landing Page
- **Two main entry points:**
  - "Join Emergency Communication" - Connect to existing emergency networks
  - "Start New Communication" - Create new emergency communication networks
- Clean, intuitive design with emergency-themed red color scheme

### 📊 Network Dashboard
- **Connected devices list** with mock data showing:
  - Emergency teams (Alpha, Bravo, Charlie)
  - Civilian groups and volunteer teams
  - Signal strength indicators
  - Last seen timestamps
- **Action buttons:**
  - "Send Predefined Message" - Quick emergency messages
  - "Start Private Chat" - Direct communication
- **Voice command buttons** (UI ready for implementation)

### 💬 Chat Page
- **Real-time messaging interface** with:
  - Message bubbles for different users
  - System messages for network updates
  - Timestamp display
  - Voice command integration
- **Mock conversation** showing emergency scenario
- **Auto-responses** to simulate real emergency communication

### 📦 Resource Page
- **Resource categories:**
  - Medical Supplies
  - Shelter
  - Food
  - Transportation
  - Communication Equipment
  - Tools & Equipment
- **Resource management:**
  - Available vs. requested counts
  - Share resources functionality
  - Request resources functionality
- **Statistics display** for each resource type

### 👤 Profile Page
- **User profile management:**
  - Personal information display
  - Profile editing capabilities
  - Role-based identification (Civilian, Emergency Team, etc.)
- **Emergency contacts:**
  - Primary and secondary contacts
  - Contact management (add, edit, delete)
  - Relationship tracking
- **Emergency settings:**
  - Location sharing preferences
  - Alert notification settings
  - Voice command toggles
  - Medical information sharing options

## Navigation Structure

```
Landing Page
    ↓ (Both buttons)
Main Navigation (Bottom Navigation Bar)
    ├── Dashboard (Network Dashboard Page)
    │   └── Chat Page (via "Start Private Chat")
    ├── Resources (Resource Page)
    └── Profile (Profile Page)
```

## Technical Implementation

### Architecture
- **Main App Structure:** `main.dart` contains the app entry point and main navigation
- **Page Separation:** Each page is in its own file under `lib/pages/`
- **State Management:** Uses `setState` for simple state management
- **Navigation:** Uses Flutter's built-in navigation with `Navigator.push` and `Navigator.pushReplacement`

### Key Components
- **Scaffold:** Base structure for all pages
- **AppBar:** Consistent red-themed app bars with voice command buttons
- **BottomNavigationBar:** Three-tab navigation between main sections
- **Cards:** Material Design cards for content organization
- **ListViews:** For displaying dynamic content (devices, messages, resources)
- **Dialogs:** For user interactions and settings

### Mock Data
- **Connected Devices:** 5 mock devices with different roles and statuses
- **Chat Messages:** Pre-populated emergency conversation
- **Resources:** 6 resource categories with availability statistics
- **Emergency Contacts:** 3 sample contacts including primary contact

### Voice Command Integration
- **UI Ready:** Voice command buttons throughout the app
- **Placeholder Dialogs:** Explain functionality without implementation
- **Accessibility Focus:** Designed for hands-free emergency use

## Getting Started

1. **Prerequisites:**
   - Flutter SDK installed
   - Android Studio or VS Code with Flutter extensions

2. **Running the App:**
   ```bash
   cd beacon
   flutter run
   ```

3. **Navigation Flow:**
   - Start at Landing Page
   - Choose either option to enter main app
   - Use bottom navigation to switch between sections
   - Tap devices in dashboard to start chat
   - Use resource page to share/request supplies
   - Manage profile and emergency contacts

## Educational Value

This app demonstrates:
- **Flutter Basics:** Scaffold, AppBar, Navigation, State Management
- **Material Design:** Cards, Buttons, Dialogs, Lists
- **App Architecture:** Page separation, navigation patterns
- **UI/UX Design:** Emergency-themed design, accessibility considerations
- **Real-world Application:** Practical emergency communication features

## Future Enhancements

- **Backend Integration:** Real-time messaging and data persistence
- **Voice Commands:** Actual voice recognition implementation
- **Location Services:** GPS integration for emergency location sharing
- **Push Notifications:** Emergency alert system
- **Offline Support:** Local data storage for offline emergency use
- **Multi-language Support:** International emergency communication

## Code Comments

Every file includes comprehensive comments explaining:
- Widget purposes and functionality
- State management patterns
- Navigation flows
- Mock data structures
- Future implementation notes

This makes the codebase perfect for learning Flutter development while understanding real-world emergency communication app requirements.
