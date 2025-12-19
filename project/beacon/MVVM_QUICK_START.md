# MVVM Refactoring Quick Start Checklist

## Week 1: Foundation Setup

### ✅ Create Project Structure
```bash
mkdir -p lib/presentation/viewmodels
mkdir -p lib/presentation/pages
mkdir -p lib/data/repositories
```

### ✅ Create Base Classes
- [ ] Create `lib/presentation/base_view_model.dart`
  - [ ] Extends `ChangeNotifier`
  - [ ] Provides `setLoading()`, `setError()`, `clearError()`
  - [ ] Has `executeAsync()` helper method
  - [ ] Has `dispose()` method

---

## Week 2: Refactor Chat Feature (Proof of Concept)

### ✅ Create ChatViewModel
- [ ] File: `lib/presentation/viewmodels/chat_view_model.dart`
- [ ] Extends `BaseViewModel`
- [ ] Move all services from ChatPage state to here:
  - [ ] `MessagingService`
  - [ ] `WiFiDirectService`
  - [ ] `SpeechToTextService`
  - [ ] `TextToSpeechService`
- [ ] Expose only public getters for state
- [ ] Implement these methods:
  - [ ] `initialize()`
  - [ ] `sendMessage()`
  - [ ] `startSpeechListening()`
  - [ ] `stopSpeechListening()`
  - [ ] `speakMessage()`
  - [ ] `dispose()`

### ✅ Refactor ChatPage
- [ ] Create new file: `lib/presentation/pages/chat_page_mvvm.dart`
- [ ] Create simple State class that only manages ViewModel
- [ ] Use `ChangeNotifierProvider.value()` to provide ViewModel
- [ ] Use `Consumer<ChatViewModel>` only for UI rendering
- [ ] Remove all direct service calls from page
- [ ] Keep original `chat_page.dart` unchanged (for now)

### ✅ Test
- [ ] Run the app with new `ChatPageMVVM`
- [ ] Test all features work:
  - [ ] Sending messages
  - [ ] Speech-to-text
  - [ ] Text-to-speech
  - [ ] Connection status updates

---

## Week 3: Create Profile ViewModel

### ✅ Create ProfileViewModel
- [ ] File: `lib/presentation/viewmodels/profile_view_model.dart`
- [ ] Implement:
  - [ ] State management (profile data, editing mode)
  - [ ] Form controllers
  - [ ] `loadProfile()`
  - [ ] `toggleEditing()`
  - [ ] `saveProfile()`
  - [ ] Validation logic

### ✅ Refactor ProfilePage
- [ ] Create: `lib/presentation/pages/profile_page_mvvm.dart`
- [ ] Follow same pattern as ChatPageMVVM
- [ ] Use Consumer widgets only for rendering
- [ ] Test all profile features

---

## Week 4: Refactor Remaining Features

### ✅ Create ViewModels
- [ ] `NetworkDashboardViewModel` for dashboard_page
  - [ ] State: connected devices, network status, activity
  - [ ] Methods: refresh data, filter devices
- [ ] `LandingViewModel` for landing_page
  - [ ] State: app initialization status
  - [ ] Methods: initialize app, handle navigation
- [ ] `ResourceViewModel` for resource_page
  - [ ] State: resources list, filters
  - [ ] Methods: load resources, search

### ✅ Refactor Pages
- [ ] Create MVVM versions of all pages
- [ ] Test each thoroughly
- [ ] Document any custom patterns used

---

## Testing Checklist

### ✅ Unit Tests
- [ ] Create `test/viewmodels/chat_view_model_test.dart`
  ```dart
  void main() {
    test('ChatViewModel initializes', () async {
      final vm = ChatViewModel();
      await vm.initialize();
      expect(vm.isLoading, false);
    });
    
    test('sendMessage validates input', () async {
      final vm = ChatViewModel();
      vm.messageController.text = '';
      // Should not send empty message
    });
  }
  ```
- [ ] Create `test/viewmodels/profile_view_model_test.dart`
- [ ] Create tests for other ViewModels

### ✅ Widget Tests
- [ ] Test ChatPageMVVM renders correctly
- [ ] Test ProfilePageMVVM renders correctly
- [ ] Test error states display properly

### ✅ Integration Tests
- [ ] Test full chat flow with ViewModel
- [ ] Test profile save/load flow
- [ ] Test navigation between MVVM pages

---

## Code Quality Checklist

### ✅ Code Review Points
- [ ] ViewModel has no UI imports
- [ ] ViewModel has no BuildContext dependencies
- [ ] Page only uses Consumer for state reading
- [ ] No direct service calls in pages
- [ ] All business logic is in ViewModel
- [ ] Error handling is consistent
- [ ] Loading states are handled
- [ ] All resources are disposed

### ✅ Documentation
- [ ] Add doc comments to all ViewModels
- [ ] Document public methods
- [ ] Add examples of usage
- [ ] Document state properties

---

## Migration Steps (Do This Last)

### ✅ Update main.dart
Option 1 (Keep both for testing):
```dart
// Let user choose which version to use
// home: ChatPageMVVM(), // New MVVM version
// home: ChatPage(), // Old version
```

Option 2 (Replace one at a time):
```dart
// When ready, replace old with new
home: ChatPageMVVM(),
```

### ✅ Update Navigation
- [ ] Update all `Navigator.push()` calls to new MVVM pages
- [ ] Update route definitions if using named routes

### ✅ Update State Management in Existing Providers
- [ ] If keeping `BeaconProvider`, consider refactoring to use pattern
- [ ] Or create coordinator ViewModels for app-level state

### ✅ Cleanup
- [ ] Remove old page files once verified MVVM works
- [ ] Remove old-style stateful widgets
- [ ] Keep services - they're still needed

---

## Common Patterns to Implement

### ✅ Loading State Pattern
```dart
class YourViewModel extends BaseViewModel {
  Future<void> loadData() async {
    await executeAsync(() async {
      // Your async code here
      // Loading and error states handled automatically
    });
  }
}

// In UI
Consumer<YourViewModel>(
  builder: (context, vm, _) {
    if (vm.isLoading) return CircularProgressIndicator();
    if (vm.hasError) return Text('Error: ${vm.errorMessage}');
    return YourContent();
  },
)
```

### ✅ Error Handling Pattern
```dart
class YourViewModel extends BaseViewModel {
  Function(String)? onError; // Callback for snackbars/dialogs
  
  Future<void> doSomething() async {
    try {
      await someOperation();
    } catch (e) {
      onError?.call('Operation failed: $e');
    }
  }
}

// In UI
_viewModel.onError = (error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error)),
  );
};
```

### ✅ Form Validation Pattern
```dart
class FormViewModel extends BaseViewModel {
  String? _validationError;
  String? get validationError => _validationError;
  
  bool validate() {
    if (inputIsInvalid()) {
      _validationError = 'Error message';
      notifyListeners();
      return false;
    }
    _validationError = null;
    return true;
  }
  
  Future<void> submit() async {
    if (!validate()) return;
    // Proceed with submission
  }
}
```

### ✅ List with Filtering Pattern
```dart
class ListViewModel extends BaseViewModel {
  List<Item> _allItems = [];
  String _filter = '';
  
  List<Item> get filteredItems => _allItems
    .where((item) => item.name.contains(_filter))
    .toList();
  
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }
}
```

---

## Performance Tips

### ✅ Optimize Consumers
Use `select()` to listen to specific properties:
```dart
// ❌ Rebuilds whole widget tree when any property changes
Consumer<ChatViewModel>(
  builder: (context, vm, _) => Text(vm.message),
)

// ✅ Rebuilds only when message changes
Selector<ChatViewModel, String>(
  selector: (context, vm) => vm.message,
  builder: (context, message, _) => Text(message),
)
```

### ✅ Avoid Unnecessary Notifies
```dart
// ❌ Notifies even if value hasn't changed
void setCount(int value) {
  _count = value;
  notifyListeners(); // Called every time
}

// ✅ Only notify if actually changed
void setCount(int value) {
  if (_count != value) {
    _count = value;
    notifyListeners();
  }
}
```

### ✅ Dispose Resources Properly
```dart
@override
void dispose() {
  _subscription?.cancel();
  _controller?.dispose();
  _timer?.cancel();
  super.dispose();
}
```

---

## Troubleshooting

### Issue: "ViewModel not available in Consumer"
**Solution**: Make sure you're using `ChangeNotifierProvider.value()` and passing the ViewModel instance.

### Issue: "State not updating when expected"
**Solution**: Make sure you call `notifyListeners()` after state changes.

### Issue: "Getting null pointer in UI"
**Solution**: Check that ViewModel is fully initialized before accessing properties.

### Issue: "Memory leak - resources not cleaning up"
**Solution**: Ensure all subscriptions and controllers are disposed in ViewModel's `dispose()`.

---

## Success Criteria

### ✅ Chat Feature is Refactored
- [ ] ChatViewModel created and working
- [ ] ChatPageMVVM created and working
- [ ] All tests pass
- [ ] No performance issues

### ✅ All Features Refactored
- [ ] Profile ViewModel & Page done
- [ ] Dashboard ViewModel & Page done
- [ ] Landing ViewModel & Page done
- [ ] Resources ViewModel & Page done

### ✅ Code Quality
- [ ] Clear separation of concerns
- [ ] Testable business logic
- [ ] Consistent error handling
- [ ] Proper resource disposal
- [ ] Well-documented code

### ✅ Testing
- [ ] Unit tests for ViewModels
- [ ] Widget tests for Pages
- [ ] All features work correctly
- [ ] No regressions

---

## Next Steps After MVVM

Once MVVM is implemented, consider:
1. **Repository Pattern** - Abstract data access further
2. **Dependency Injection** - Use GetIt or similar for service injection
3. **State Management Upgrade** - Consider Riverpod or Bloc if needed
4. **Testing Coverage** - Add comprehensive unit and widget tests
5. **Code Generation** - Use Freezed or similar for immutable models

---

**Remember**: Start small with Chat feature, validate the pattern works, then apply to other features!
