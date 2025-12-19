# MVVM Architecture Implementation Guide for Beacon App

## Overview

MVVM (Model-View-ViewModel) is an architectural pattern that separates an application into three layers:

1. **Model** - Data layer (represents business data and logic)
2. **View** - Presentation layer (UI - Flutter widgets)
3. **ViewModel** - Logic layer (manages state and orchestrates between Model and View)

## Current Architecture Analysis

Your Beacon app currently has:
- ✅ **Data Layer**: Database, models (in `lib/data/`)
- ✅ **Services Layer**: Various services (messaging, WiFi Direct, speech-to-text, etc.)
- ✅ **State Management**: Already using Provider package
- ⚠️ **Views**: Currently mixing business logic with UI (stateful widgets managing too much)

## MVVM Architecture Structure for Beacon App

```
lib/
├── data/                          # Data Layer (Models, Repositories, Services)
│   ├── models.dart
│   ├── database_service.dart
│   └── repositories/              # NEW: Data access abstraction
│       ├── message_repository.dart
│       └── device_repository.dart
│
├── services/                      # Service Layer (existing)
│   ├── messaging_service.dart
│   ├── wifi_direct_service.dart
│   └── ...
│
├── presentation/                  # Presentation Layer (NEW)
│   ├── base_view_model.dart       # Base class for all ViewModels
│   ├── viewmodels/                # ViewModels (Business Logic)
│   │   ├── chat_view_model.dart
│   │   ├── profile_view_model.dart
│   │   ├── dashboard_view_model.dart
│   │   └── ...
│   └── pages/                     # Views (UI Only)
│       ├── chat_page_mvvm.dart
│       └── ...
│
├── providers/                     # Keep existing providers for now
│   └── beacon_provider.dart
│
└── main.dart                      # App entry point
```

## Layer Responsibilities

### 1. Model Layer (Data)
- Represents business data and entities
- Contains repositories that abstract data access
- No UI logic, no service orchestration

```dart
// Example Model
class ChatMessage {
  final String text;
  final String senderId;
  final DateTime timestamp;
  // ... properties
}
```

### 2. Service Layer (Existing)
- Handles low-level operations
- WiFi Direct communication
- Speech recognition/synthesis
- Database operations

```dart
// Service - Low-level operation
class MessagingService {
  Future<bool> sendMessage(String text) async { ... }
}
```

### 3. ViewModel Layer (NEW)
- **Inherits from BaseViewModel** for common functionality
- Manages state using Provider's ChangeNotifier
- Orchestrates services to fulfill business logic
- Exposes only necessary state and methods to UI
- Handles errors and loading states

```dart
// ViewModel - Business Logic
class ChatViewModel extends BaseViewModel {
  // Dependencies
  final _messagingService = MessagingService();
  
  // State
  bool _isLoading = false;
  
  // Business Logic
  Future<void> sendMessage(String text) async {
    await executeAsync(() => _messagingService.sendMessage(text));
  }
}
```

### 4. View Layer (UI)
- **Pure presentation logic only**
- Reads state from ViewModel using Consumer widgets
- Calls ViewModel methods on user actions
- No direct service interactions
- No complex state management logic

```dart
// View - UI Only
class ChatPage extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        return ListView(
          children: viewModel.messages.map((msg) {
            return ListTile(
              title: Text(msg.text),
              onTap: () => viewModel.handleMessageTap(msg),
            );
          }).toList(),
        );
      },
    );
  }
}
```

## Step-by-Step Migration Guide

### Step 1: Organize Your Project Structure

1. Create the new folder structure:
   ```
   mkdir -p lib/presentation/viewmodels
   mkdir -p lib/presentation/pages
   mkdir -p lib/data/repositories
   ```

2. Move BaseViewModel to `lib/presentation/base_view_model.dart`

### Step 2: Create a ViewModel for Each Feature

For each page/feature (Chat, Profile, Dashboard, etc.):

1. **Create the ViewModel** in `lib/presentation/viewmodels/{feature}_view_model.dart`:
   ```dart
   class ChatViewModel extends BaseViewModel {
     // Initialize services
     final MessagingService _messagingService = MessagingService();
     
     // State properties
     bool _isSpeaking = false;
     List<ChatMessage> _messages = [];
     
     // Public getters
     bool get isSpeaking => _isSpeaking;
     List<ChatMessage> get messages => _messages;
     
     // Public methods
     Future<void> sendMessage(String text) async { ... }
   }
   ```

2. **Refactor the Page** to use the ViewModel:
   - Extract all business logic to ViewModel
   - Keep only UI rendering in the page
   - Use Consumer<ViewModel> widgets to access state

### Step 3: Update the Page to Use ViewModel

**Before (Stateful with logic mixed in):**
```dart
class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late MessagingService _messagingService;
  List<ChatMessage> _messages = [];
  
  @override
  void initState() {
    _messagingService = MessagingService();
    _messagingService.initialize();
  }
  
  void sendMessage(String text) {
    _messages.add(...);
    setState(() { });
  }
}
```

**After (MVVM - Clean separation):**
```dart
class ChatPageMVVM extends StatefulWidget {
  @override
  State<ChatPageMVVM> createState() => _ChatPageMVVMState();
}

class _ChatPageMVVMState extends State<ChatPageMVVM> {
  late ChatViewModel _viewModel;
  
  @override
  void initState() {
    _viewModel = ChatViewModel();
    _viewModel.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, _) => ListView(
          children: viewModel.messages.map((msg) => 
            ListTile(
              title: Text(msg.text),
              onTap: () => viewModel.sendMessage(msg.text),
            )
          ).toList(),
        ),
      ),
    );
  }
}
```

### Step 4: Create Repository Layer (Optional but Recommended)

Create repositories to abstract data access:

```dart
// lib/data/repositories/message_repository.dart
abstract class MessageRepository {
  Future<List<ChatMessage>> getMessages();
  Future<bool> saveMessage(ChatMessage message);
  Stream<ChatMessage> get messageStream;
}

// Implementation
class MessageRepositoryImpl implements MessageRepository {
  final MessagingService _service = MessagingService();
  
  @override
  Future<List<ChatMessage>> getMessages() async {
    return _service.messages;
  }
  
  @override
  Stream<ChatMessage> get messageStream => _service.messageStream;
}
```

## Best Practices for MVVM in Flutter

### 1. ViewModel Responsibilities ✅
- Initialize and manage services
- Transform data for UI consumption
- Validate user input
- Handle business logic
- Manage loading/error states
- Expose state via getters only

### 2. View Responsibilities ✅
- Render UI based on ViewModel state
- Respond to user interactions
- Show dialogs/snackbars via ViewModel callbacks
- Listen to ViewModel state changes via Consumer
- Never call services directly

### 3. Testing Benefits 🧪
```dart
// Easy to test - no Flutter dependencies in ViewModel
test('ChatViewModel sends message correctly', () async {
  final viewModel = ChatViewModel();
  
  await viewModel.sendMessage('Hello');
  
  expect(viewModel.messages.length, 1);
  expect(viewModel.messages[0].text, 'Hello');
});
```

## File Templates

### ViewModel Template
```dart
import 'package:flutter/material.dart';
import '../base_view_model.dart';

class {Feature}ViewModel extends BaseViewModel {
  // Services
  // final {Service} _{service} = {Service}();
  
  // State properties
  // bool _isLoading = false;
  
  // Getters
  // bool get isLoading => _isLoading;
  
  // Initialization
  Future<void> initialize() async {
    try {
      setLoading(true);
      // Initialize services and load data
      setLoading(false);
    } catch (e) {
      setError('Failed to initialize: $e');
    }
  }
  
  // Business logic methods
  
  // Cleanup
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
```

### Page Template
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/{feature}_view_model.dart';

class {Feature}Page extends StatefulWidget {
  const {Feature}Page({super.key});

  @override
  State<{Feature}Page> createState() => _{Feature}PageState();
}

class _{Feature}PageState extends State<{Feature}Page> {
  late {Feature}ViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = {Feature}ViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<{Feature}ViewModel>.value(
      value: _viewModel,
      child: Consumer<{Feature}ViewModel>(
        builder: (context, viewModel, _) {
          // UI code here
          return Scaffold(
            appBar: AppBar(title: const Text('{Feature}')),
            body: Center(
              child: Text(viewModel.toString()),
            ),
          );
        },
      ),
    );
  }
}
```

## Migration Checklist

- [ ] Create `lib/presentation/` folder structure
- [ ] Create `BaseViewModel` in `lib/presentation/base_view_model.dart`
- [ ] Create ViewModel for **Chat** feature (`ChatViewModel`)
- [ ] Refactor **ChatPage** to use `ChatViewModel` (create `ChatPageMVVM`)
- [ ] Test Chat feature with new MVVM architecture
- [ ] Create ViewModel for **Profile** feature
- [ ] Refactor **ProfilePage** to use ViewModel
- [ ] Create ViewModel for **Dashboard** feature
- [ ] Refactor **DashboardPage** to use ViewModel
- [ ] Create ViewModel for **Landing** feature
- [ ] Refactor **LandingPage** to use ViewModel
- [ ] Create ViewModel for **Resources** feature
- [ ] Refactor **ResourcePage** to use ViewModel
- [ ] Update `main.dart` to use new MVVM pages (optional - keep both for gradual migration)
- [ ] Create repository layer for data abstraction (optional)
- [ ] Add unit tests for ViewModels
- [ ] Document custom ViewModels in code

## Gradual Migration Strategy

You don't need to refactor everything at once! Use this strategy:

1. **Phase 1**: Implement MVVM for one feature (Chat) as a proof of concept
2. **Phase 2**: Use this as a template for other features
3. **Phase 3**: Keep old pages and new MVVM pages side-by-side temporarily
4. **Phase 4**: Gradually replace old pages with MVVM versions
5. **Phase 5**: Remove old code once all features migrated

This allows testing and validation at each step.

## Additional Resources

### Provider Package Best Practices
- Use `ChangeNotifierProvider.value()` for existing instances
- Use `Consumer<ViewModel>` only where state is used
- Use `select()` to listen only to specific properties

### Testing ViewModels
```dart
// test/viewmodels/chat_view_model_test.dart
void main() {
  test('ChatViewModel initializes correctly', () async {
    final viewModel = ChatViewModel();
    await viewModel.initialize();
    
    expect(viewModel.isLoading, false);
    expect(viewModel.messages.isNotEmpty, true);
  });
}
```

## Summary

MVVM architecture in Flutter provides:
- ✅ **Better Code Organization** - Clear separation of concerns
- ✅ **Easier Testing** - Logic is testable without UI
- ✅ **Reusability** - ViewModels can be shared across different UIs
- ✅ **Maintainability** - Changes in one layer don't affect others
- ✅ **Scalability** - Easy to add new features following the pattern

Start with the Chat feature, and gradually migrate other features following the same pattern!
