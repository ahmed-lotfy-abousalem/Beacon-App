# MVVM Architecture Diagram & Flow

## High-Level Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER (UI)                   │
│                                                                   │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Pages/Views (Widgets)                                   │  │
│   │  ┌─────────────────────────────────────────────────────┐│  │
│   │  │ ChatPageMVVM                    [Build UI Only]     ││  │
│   │  │ - Consumer<ChatViewModel>                            ││  │
│   │  │ - Renders messages                                  ││  │
│   │  │ - Calls ViewModel methods on user action           ││  │
│   │  └─────────────────────────────────────────────────────┘│  │
│   │                                                          │  │
│   │   Calls methods on ViewModel                            │  │
│   │   Listens to state changes                             │  │
│   └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
              ▲                                    ▼
              │                                    │
        State Changes            User Actions
        (notifyListeners)        (button taps)
              │                                    │
              └────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      VIEWMODEL LAYER (Logic)                     │
│                                                                   │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  ViewModels (extends BaseViewModel)                     │  │
│   │  ┌─────────────────────────────────────────────────────┐│  │
│   │  │ ChatViewModel extends BaseViewModel                 ││  │
│   │  │                                                      ││  │
│   │  │ State:                                              ││  │
│   │  │  - _isSocketConnected                               ││  │
│   │  │  - _isSpeechListening                               ││  │
│   │  │  - _messages                                        ││  │
│   │  │                                                      ││  │
│   │  │ Public Getters:                                     ││  │
│   │  │  - bool get isSocketConnected                       ││  │
│   │  │  - List<ChatMessage> get messages                  ││  │
│   │  │                                                      ││  │
│   │  │ Public Methods:                                     ││  │
│   │  │  - Future<void> initialize()                       ││  │
│   │  │  - Future<void> sendMessage()                      ││  │
│   │  │  - Future<void> speakMessage()                     ││  │
│   │  │  - void dispose()                                   ││  │
│   │  │                                                      ││  │
│   │  │ Internal Methods:                                   ││  │
│   │  │  - _initializeMessaging()                          ││  │
│   │  │  - _initializeSpeechToText()                       ││  │
│   │  │  - _handleSocketConnected()                        ││  │
│   │  └─────────────────────────────────────────────────────┘│  │
│   │                                                          │  │
│   │   Orchestrates Services, Manages State                 │  │
│   │   Handles Business Logic & Error Handling              │  │
│   └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
              ▲                                    ▼
              │                                    │
        Data Requests       Service Operations
        & State Updates     (initialize, send, speak)
              │                                    │
              └────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER (Operations)                  │
│                                                                   │
│   ┌──────────────────────┐  ┌──────────────────────┐            │
│   │ MessagingService     │  │ WiFiDirectService    │            │
│   │ ┌────────────────┐   │  │ ┌────────────────┐   │            │
│   │ │ sendMessage()  │   │  │ │ startDiscovery │   │            │
│   │ │ initialize()   │   │  │ │ getDevices()   │   │            │
│   │ │ messageStream  │   │  │ │ eventStream    │   │            │
│   │ └────────────────┘   │  │ └────────────────┘   │            │
│   └──────────────────────┘  └──────────────────────┘            │
│                                                                   │
│   ┌──────────────────────┐  ┌──────────────────────┐            │
│   │SpeechToTextService   │  │TextToSpeechService   │            │
│   │ ┌────────────────┐   │  │ ┌────────────────┐   │            │
│   │ │ startListening │   │  │ │ speak()        │   │            │
│   │ │ stopListening  │   │  │ │ stop()         │   │            │
│   │ │ onTextRecogniz │   │  │ │ initialize()   │   │            │
│   │ └────────────────┘   │  │ └────────────────┘   │            │
│   └──────────────────────┘  └──────────────────────┘            │
│                                                                   │
│   Handle Low-Level Operations, Platform Integration              │
│   Return Data & Emit Events                                     │
└─────────────────────────────────────────────────────────────────┘
              ▲                                    ▼
              │                                    │
           Read/Write            Native Platform APIs
           System Resources       (Android, iOS)
              │                                    │
              └────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       DATA LAYER (Storage)                        │
│                                                                   │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  DatabaseService / Repositories                         │  │
│   │  ┌─────────────────────────────────────────────────────┐│  │
│   │  │ - saveMessage()                                     ││  │
│   │  │ - getMessages()                                     ││  │
│   │  │ - saveUserProfile()                                 ││  │
│   │  │ - Models (ChatMessage, UserProfile, etc.)          ││  │
│   │  └─────────────────────────────────────────────────────┘│  │
│   │                                                          │  │
│   │   Abstracts Data Access, Provides Models               │  │
│   │   (Future: Add Repository pattern)                     │  │
│   └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
              ▲                                    ▼
              │                                    │
           Query/Update      Persist Data
           Data              (SQLite, Files, etc.)
              │                                    │
              └────────────────────────────────────┘
```

---

## Data Flow Diagram

### Scenario: User sends a message

```
1. USER INTERACTION (View Layer)
   ┌─────────────────────────────────┐
   │ User taps Send Button            │
   └──────────────┬──────────────────┘
                  │
                  ▼
2. PAGE CALLS VIEWMODEL METHOD (UI Layer → Logic Layer)
   ┌─────────────────────────────────┐
   │ page.onPressed(() =>            │
   │   viewModel.sendMessage()        │
   │ )                               │
   └──────────────┬──────────────────┘
                  │
                  ▼
3. VIEWMODEL VALIDATES & CALLS SERVICE (Logic Layer → Service Layer)
   ┌─────────────────────────────────┐
   │ ChatViewModel.sendMessage()      │
   │ - Validates text not empty       │
   │ - Calls                          │
   │   _messagingService.sendMessage()│
   │ - Manages loading state          │
   └──────────────┬──────────────────┘
                  │
                  ▼
4. SERVICE EXECUTES OPERATION (Service Layer → Platform)
   ┌─────────────────────────────────┐
   │ MessagingService.sendMessage()   │
   │ - Serializes message             │
   │ - Sends via WiFi Direct          │
   │ - Returns success/failure        │
   └──────────────┬──────────────────┘
                  │
                  ▼
5. VIEWMODEL UPDATES STATE (Logic Layer)
   ┌─────────────────────────────────┐
   │ ChatViewModel                    │
   │ - Clear message input            │
   │ - Update state                   │
   │ - notifyListeners()              │
   │   (triggers rebuild)             │
   └──────────────┬──────────────────┘
                  │
                  ▼
6. UI REBUILDS (View Layer)
   ┌─────────────────────────────────┐
   │ Consumer<ChatViewModel>          │
   │ - Reads updated state            │
   │ - Rebuilds widget tree           │
   │ - Shows new message in list      │
   └─────────────────────────────────┘
```

---

## State Management Flow

### BaseViewModel Hierarchy

```
        ChangeNotifier (Provider)
              ▲
              │ extends
              │
        ┌─────┴─────────────────┐
        │                       │
    BaseViewModel            (You could also extend ChangeNotifier directly)
        ▲
        │ extends
        │
   ┌────┴────────────────┬─────────────────┬──────────────────┐
   │                     │                 │                  │
ChatViewModel    ProfileViewModel    DashboardViewModel    ...More
```

### State Update Mechanism

```
1. User Action
        │
        ▼
2. ViewModel Method Called
        │
        ▼
3. Update Internal State
   _state = newValue
        │
        ▼
4. Call notifyListeners()
        │
        ▼
5. Provider Notifies All Listeners
        │
        ▼
6. Consumer Widgets Rebuild
        │
        ▼
7. UI Displays New State
```

---

## Consumer Subscription Pattern

### How Consumer Knows When to Rebuild

```
┌─────────────────────────────────────────┐
│ ViewModel (extends ChangeNotifier)      │
│                                         │
│ void updateState() {                    │
│   _state = newValue;                    │
│   notifyListeners(); ◄─┐               │
│ }                      │               │
└────────────────────────┼─────────────────┘
                         │ triggers
                         │
┌────────────────────────┼─────────────────┐
│ Consumer<ViewModel>    │                 │
│                        ▼                 │
│ Listens for changes    (rebuilds widget) │
│                                         │
│ Widget build() {                        │
│   return Consumer<ViewModel>(           │
│     builder: (context, vm, _) {        │
│       // This code runs when notified  │
│       return Text(vm.state);           │
│     }                                   │
│   );                                    │
│ }                                       │
└─────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌──────────────────────────────────────┐
│ ViewModel.executeAsync(() async {    │
│   await operation();                 │
│ })                                   │
│                                      │
│ Automatically handles:               │
│  ├─ setLoading(true)                │
│  ├─ clearError()                    │
│  ├─ Try/catch operation             │
│  ├─ setError(message) on error      │
│  └─ setLoading(false)               │
│                                      │
│ notifyListeners() called             │
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ Page                                 │
│                                      │
│ if (viewModel.hasError) {            │
│   showErrorDialog(                   │
│     viewModel.errorMessage           │
│   );                                 │
│ }                                    │
└──────────────────────────────────────┘
```

---

## Class Relationship Diagram

```
┌────────────────────────────────────────────────────────────┐
│                  BASE INFRASTRUCTURE                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ BaseViewModel extends ChangeNotifier                │ │
│  │                                                      │ │
│  │ Properties:                                         │ │
│  │  - _isLoading: bool                                │ │
│  │  - _errorMessage: String?                          │ │
│  │                                                      │ │
│  │ Methods:                                            │ │
│  │  + isLoading: bool (getter)                        │ │
│  │  + hasError: bool (getter)                         │ │
│  │  + errorMessage: String? (getter)                  │ │
│  │  # setLoading(bool)                                │ │
│  │  # setError(String?)                               │ │
│  │  # clearError()                                    │ │
│  │  # executeAsync<T>(() async)                       │ │
│  │  + dispose()                                        │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
        ▲           ▲           ▲           ▲
        │           │           │           │ extends
        │           │           │           │
   ChatVM    ProfileVM    DashboardVM    ResourceVM
```

---

## Dependency Injection Pattern (Current)

```
ChatPageMVVM
    │
    ├─ initState()
    │   └─ _viewModel = ChatViewModel()
    │       └─ services initialized here
    │
    ├─ ChangeNotifierProvider(value: _viewModel)
    │   └─ Consumer<ChatViewModel>()
    │       └─ calls viewModel methods
    │
    └─ dispose()
        └─ _viewModel.dispose()
           └─ cleans up resources
```

### Future: Better Dependency Injection (Optional)

```
// Could upgrade to GetIt or Riverpod later
void setupServiceLocator() {
  getIt.registerSingleton<MessagingService>(MessagingService());
  getIt.registerSingleton<WiFiDirectService>(WiFiDirectService());
  getIt.registerSingleton<ChatRepository>(ChatRepositoryImpl());
  getIt.registerSingleton<ChatViewModel>(ChatViewModel(
    getIt.get<ChatRepository>(),
  ));
}

// Then inject dependencies
class ChatViewModel extends BaseViewModel {
  final ChatRepository _repository;
  
  ChatViewModel(this._repository);
  
  Future<void> initialize() async {
    // Use injected repository
  }
}
```

---

## Message Flow During Chat

```
SENDER SIDE:
User Types Message
        │
        ▼
User Clicks Send Button
        │
        ▼
ChatPage.onPressed()
        │
        ▼
ChatViewModel.sendMessage()
        │
        ▼
MessagingService.sendMessage(text)
        │
        ▼
Send via WiFi Direct Socket
        │
        ▼
Update local message list
        │
        ▼
notifyListeners()
        │
        ▼
Consumer rebuilds
        │
        ▼
Message appears in local chat

RECEIVER SIDE:
Receive message from WiFi Socket
        │
        ▼
MessagingService emits via messageStream
        │
        ▼
ChatViewModel listens to messageStream
        │
        ▼
notifyListeners()
        │
        ▼
Consumer rebuilds
        │
        ▼
Message appears in remote peer's chat
        │
        ▼
TextToSpeech button available
        │
        ▼
User can click to hear message
```

---

## Lifecycle: Page Creation to Disposal

```
1. USER NAVIGATES TO CHAT PAGE
   ChatPageMVVM widget created

2. initState() RUNS
   └─ _viewModel = ChatViewModel()
   └─ _viewModel.initialize()
      ├─ Initializes all services
      ├─ Sets up stream subscriptions
      ├─ Loads initial data
      └─ Calls notifyListeners()

3. build() RUNS
   └─ ChangeNotifierProvider.value(_viewModel)
   └─ Consumer<ChatViewModel>(
      ├─ Connects to ViewModel
      ├─ Builds initial UI
      └─ Subscribes to changes

4. USER INTERACTS
   ├─ Taps button
   │  └─ Calls viewModel.method()
   │     ├─ Updates state
   │     └─ Calls notifyListeners()
   │        └─ Consumer rebuilds
   │
   ├─ Message received
   │  └─ Service emits event
   │     └─ ViewModel listens
   │        ├─ Updates state
   │        └─ Calls notifyListeners()
   │           └─ Consumer rebuilds

5. USER NAVIGATES AWAY / PAGE DISPOSED
   dispose() RUNS
   └─ _viewModel.dispose()
      ├─ Cancels subscriptions
      ├─ Disposes controllers
      ├─ Stops services
      └─ Cleans up resources

6. GC COLLECTS OBJECTS
   Memory freed
```

---

## Summary: What Happens Where

| Action | Layer | Component | How |
|--------|-------|-----------|-----|
| **Display Data** | View | ChatPage | Consumer reads viewModel.messages |
| **Store Data** | ViewModel | ChatViewModel | _messages list |
| **Fetch Data** | Service | MessagingService | Loads from socket |
| **Persist Data** | Data | DatabaseService | Saves to SQLite |
| **User Taps Button** | View | ChatPage | Calls viewModel.sendMessage() |
| **Validate Input** | ViewModel | ChatViewModel | Check if text not empty |
| **Send Message** | Service | MessagingService | Uses WiFi Direct |
| **Handle Error** | ViewModel | BaseViewModel | setError() method |
| **Show Error** | View | ChatPage | Displays errorMessage in dialog |
| **Cleanup** | All | All | dispose() methods |

This architecture ensures each layer has clear responsibility and can be tested independently!
