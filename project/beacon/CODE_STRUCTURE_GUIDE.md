# BEACON App - Code Structure & Main Functions Guide

## Overview
BEACON is a Flutter-based disaster response communication app that enables peer-to-peer (P2P) communication using WiFi Direct. The app follows the MVVM (Model-View-ViewModel) architecture pattern with provider-based state management.

---

## 📁 Project Architecture

### Directory Structure
```
lib/
├── main.dart                 # App entry point & root widget
├── pages/                    # UI pages (views)
├── presentation/             # ViewModels & UI logic
├── providers/                # State management providers
├── services/                 # Business logic services
└── data/                     # Data models & database
```

---

## 🚀 Main Entry Point: `main.dart`

### Key Functions

#### **`main()`**
- **Purpose**: Application entry point
- **Responsibilities**:
  - Initializes Flutter binding
  - Creates and runs the BeaconApp widget
- **Code**:
  ```dart
  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const BeaconApp());
  }
  ```

#### **`BeaconApp` Class (Stateless Widget)**
- **Purpose**: Root application widget defining theme, providers, and navigation
- **Key Features**:
  - **Multi-Provider Setup**: Uses `MultiProvider` to inject two main providers:
    - `BeaconProvider()`: Manages main app state
    - `PeerNotificationViewModel()`: Manages peer notifications
  - **Theme Configuration**:
    - Uses red color scheme (emergency/disaster response theme)
    - Material Design 3 enabled
    - Custom AppBar styling (centered titles, elevation)
  - **Navigation**: Starts with `LandingPage` as home route

#### **`_NotificationListener` Class (Stateful Widget)**
- **Purpose**: Global notification listener wrapper for peer events
- **Key Responsibilities**:
  - Listens for peer join/leave events globally
  - Shows snackbars when peers connect/disconnect
  - Sets up callbacks: `onPeerJoined()` and `onPeerLeft()`
- **Key Methods**:
  - `didChangeDependencies()`: Initializes notification callbacks
  - Logs events with emoji indicators for debugging

### 🔑 Key Features in main.dart
| Feature | Purpose |
|---------|---------|
| `MultiProvider` | Manages global state with multiple providers |
| `_NotificationListener` | Wraps app to show global notifications |
| `MaterialApp` | Defines app theme and home route |
| Red Color Scheme | Emphasizes emergency/disaster response nature |

---

## 🎛️ State Management: `providers/beacon_provider.dart`

### **`BeaconProvider` Class**
- **Purpose**: Central state holder connecting database, P2P service, and UI
- **Pattern**: `ChangeNotifier` with `WidgetsBindingObserver` mixin
- **Singleton Dependencies**:
  - `DatabaseService`: Encrypted local data storage
  - `P2PService`: Peer discovery and communication

### State Variables
```dart
bool _isLoading              // App initialization status
bool _isDatabaseLocked       // Database lock state
UserProfile? _userProfile    // Current user profile
List<ConnectedDevice> _connectedDevices  // Connected peers
List<NetworkActivity> _recentActivity    // Activity log
```

### Main Methods

#### **`initialize()`** ⭐ Critical
- **Purpose**: Bootstrap the app on startup
- **Steps**:
  1. Opens encrypted database
  2. Loads cached data from database
  3. Starts P2P peer discovery
  4. Subscribes to peer updates stream
  5. Sets `_isLoading = false` and notifies listeners
- **Called From**: `BeaconApp` provider initialization

#### **`refresh()`**
- Reloads data from database
- Guards against refreshing when database is locked
- Notifies listeners of state changes

#### **`saveProfile(UserProfile profile)`**
- Saves user profile to database
- Logs activity: `'profile_update'` event
- Triggers refresh to update UI

#### **`sendQuickMessage(String peerId, String message)`**
- Logs a message as `NetworkActivity` with event type `'message'`
- Records sender ID, message content, and timestamp
- Refreshes UI

#### **`removeDevice(String peerId)`**
- Removes a peer device from the network
- Triggers database update and UI refresh

#### **`lockDatabase() / unlockDatabase()`**
- Lock: Closes database and sets `_isDatabaseLocked = true`
- Unlock: Reopens database and reloads data
- **Used for**: App pause/resume lifecycle handling

#### **`didChangeAppLifecycleState(AppLifecycleState state)`**
- **Purpose**: Responds to app lifecycle events
- **Logic**:
  - **Paused/Inactive/Hidden**: Locks database and stops discovery
  - **Resumed**: Unlocks database and resumes discovery
- **Critical for**: Protecting sensitive data and resource cleanup

### 🔑 Key Patterns
| Pattern | Benefit |
|---------|---------|
| `ChangeNotifier` | Automatic UI updates on state change |
| `WidgetsBindingObserver` | Lifecycle-aware state management |
| Stream subscriptions | Real-time peer updates |

---

## 📡 Services Layer

### **`services/wifi_direct_service.dart`**

#### **`WiFiDirectService` Class**
- **Purpose**: Manages WiFi Direct communication via platform channels
- **Pattern**: Singleton (private constructor + factory)
- **Communication**: Uses `MethodChannel` to call native Android code

#### State Variables
```dart
bool _isInitialized          // Initialization status
bool _isDiscovering          // Discovery active state
bool _isSocketConnected      // Connection status
String? _uniqueDeviceId      // Persistent device identifier
String? _thisDeviceName      // Device name
```

#### Main Methods

##### **`initialize()`** ⭐ Critical
- **Purpose**: Initialize WiFi Direct service
- **Steps**:
  1. Check if already initialized (return early if true)
  2. Generate or load persistent device ID
  3. Set up method call handler for platform channel
  4. Invoke native 'initialize' method
- **Returns**: `Future<bool>` success status

##### **`_initializeDeviceId()`**
- Uses `SharedPreferences` for persistent storage
- Generates random 12-character hex ID if none exists
- Enables consistent device identification across app restarts

##### **`isSupported()`**
- Checks if device supports WiFi Direct
- Calls native platform code via method channel

##### **`startDiscovery() / stopDiscovery()`**
- **startDiscovery()**:
  - Auto-initializes if needed
  - Sets `_isDiscovering = true`
  - Invokes native discovery method
- **stopDiscovery()**:
  - Stops peer search
  - Sets flag to false

##### **Event Broadcasting**
- `StreamController<WiFiDirectEvent>` for real-time events
- Emits events: `'discoveredPeers'`, `'messageReceived'`, etc.
- Accessible via `eventStream` getter

---

### **`services/messaging_service.dart`**

#### **`MessagingService` Class**
- **Purpose**: Handles P2P messaging over WiFi Direct
- **Pattern**: Singleton with WiFiDirectService dependency
- **Key Feature**: Persistent message storage with JSON serialization

#### Main Methods

##### **`initialize()`** ⭐ Critical
- **Purpose**: Set up messaging service
- **Steps**:
  1. Initialize WiFi Direct service
  2. Subscribe to WiFi Direct event stream
  3. Parse incoming messages (JSON or plain text)
  4. Add messages to internal list
  5. Broadcast via `_messageController` stream
- **Parsing Logic**:
  - Tries JSON deserialization first
  - Falls back to plain text if JSON fails
  - Determines sender ID to set `isFromCurrentUser` flag

##### **`sendMessage(String text, ...)`**
- **Purpose**: Send message to connected peers
- **Process**:
  1. Initialize if needed
  2. Create JSON envelope with sender ID, timestamp, text
  3. Transmit via WiFi Direct service
  4. Add message to local history
  5. Emit via stream controller

#### Message Structure
```dart
class ChatMessage {
  final String text;              // Message content
  final String senderId;          // Sender's device ID
  final String senderName;        // Sender's display name
  final DateTime timestamp;       // When message was sent
  final bool isFromCurrentUser;   // Is this device the sender?
}
```

---

## 📄 Pages/UI Layer

### **`pages/landing_page.dart`**
- **Purpose**: First screen user sees on app launch
- Entry point for navigation to other pages

### **`pages/network_dashboard_page.dart`**
- **Purpose**: Display connected devices and network status
- Shows peer discovery and connection information

### **`pages/chat_page.dart`**
- **Purpose**: P2P messaging interface
- Displays chat history and message input
- Integrates with `MessagingService`

### **`pages/profile_page.dart`**
- **Purpose**: User profile creation/editing
- Integrates with `BeaconProvider` for profile persistence

### **`pages/resource_page.dart`**
- **Purpose**: Resource sharing and availability
- Displays disaster response resources

---

## 🔐 Data Layer

### **`data/database_service.dart`**
- **Purpose**: Encrypted local data persistence
- Uses SQLCipher for encryption
- Manages:
  - User profiles
  - Device information
  - Network activity logs

### **`data/models.dart`**
- Defines data classes:
  - `UserProfile`: User information
  - `ConnectedDevice`: Peer device metadata
  - `NetworkActivity`: Event logging
  - `ChatMessage`: Message data structure

---

## 🔄 Data Flow Diagram

```
User Interaction (UI)
        ↓
    [Page Widget]
        ↓
  Consumes [Provider]
        ↓
[BeaconProvider / ViewModel]
        ↓
    [Services Layer]
   ├── WiFiDirectService (P2P communication)
   ├── MessagingService (Chat messaging)
   └── DatabaseService (Data persistence)
        ↓
  [Platform Channels / Native Android]
        ↓
    [Device WiFi Direct Hardware]
```

---

## 🚀 Initialization Flow

### On App Start:
1. **main()** → Creates BeaconApp
2. **BeaconApp.build()** → Sets up MultiProvider with:
   - `BeaconProvider()..initialize()`
   - `PeerNotificationViewModel()..initialize()`
3. **BeaconProvider.initialize()** → Performs:
   - Database.open()
   - Load cached data
   - Start P2P discovery
   - Subscribe to peer updates
4. **App displays LandingPage** with initialized state

### On App Pause/Inactive:
- **BeaconProvider.didChangeAppLifecycleState()** triggers:
  - `lockDatabase()` → Closes DB
  - `stopDiscovery()` → Stops peer search
- **Protects sensitive data from exposure**

### On App Resume:
- **BeaconProvider.didChangeAppLifecycleState()** triggers:
  - `unlockDatabase()` → Reopens DB
  - Restart discovery
- **Resumes normal operation**

---

## 🔑 Key Design Patterns

| Pattern | Implementation | Benefit |
|---------|----------------|---------|
| **MVVM** | ViewModels in presentation/ | Separation of concerns |
| **Provider Pattern** | ChangeNotifier + Provider | Reactive state management |
| **Singleton** | WiFiDirectService, MessagingService | Single instance, resource efficiency |
| **Observer** | WidgetsBindingObserver | Lifecycle-aware logic |
| **Stream/Event Bus** | Stream<WiFiDirectEvent>, messageStream | Real-time updates |
| **Repository** | DatabaseService abstraction | Data access centralization |

---

## ⚠️ Critical Functions Summary

| Function | File | Purpose | Criticality |
|----------|------|---------|------------|
| `main()` | main.dart | App bootstrap | 🔴 Critical |
| `BeaconProvider.initialize()` | beacon_provider.dart | State initialization | 🔴 Critical |
| `WiFiDirectService.initialize()` | wifi_direct_service.dart | P2P setup | 🔴 Critical |
| `MessagingService.initialize()` | messaging_service.dart | Messaging setup | 🔴 Critical |
| `BeaconApp.build()` | main.dart | Root UI | 🟡 Important |
| `didChangeAppLifecycleState()` | beacon_provider.dart | Lifecycle handling | 🟡 Important |
| `startDiscovery()` | wifi_direct_service.dart | Peer search | 🟡 Important |

---

## 🛠️ Building & Running

### Initialize App:
- All `initialize()` methods must be called in sequence
- Provider setup handles this automatically

### Message Flow:
1. User types message → calls `sendMessage()`
2. Message serialized to JSON
3. Sent via WiFi Direct
4. Received by peer → `MessagingService` parses it
5. Emitted via stream → UI updates

### Peer Discovery:
1. `startDiscovery()` called
2. WiFi Direct scans for nearby devices
3. Each peer found → event emitted
4. `BeaconProvider` receives update
5. UI notified of new device

---

## 📋 Notes for Developers

1. **Always initialize before use**: Services depend on proper initialization order
2. **Handle lifecycle events**: Database must be locked when app is not active
3. **Check device ID**: WiFi Direct uses unique device ID for identification
4. **JSON message format**: Messages should follow standard envelope with sender/timestamp
5. **Error handling**: Network operations may fail; always check return values
6. **Logging**: App uses emoji-based logging for easy debugging (🌐, ✅, 🔔, 📥, etc.)
7. **Cleanup on exit**: Subscriptions and services are properly disposed

---

## 📚 Related Documentation
- [MVVM_GUIDE.md](MVVM_GUIDE.md) - Architecture patterns
- [NOTIFICATION_SYSTEM.md](NOTIFICATION_SYSTEM.md) - Notification handling
- [WIFI_DIRECT_SETUP.md](WIFI_DIRECT_SETUP.md) - WiFi Direct configuration
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Test structure
