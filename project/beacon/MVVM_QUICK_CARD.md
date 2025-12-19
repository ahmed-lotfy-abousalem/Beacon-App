# MVVM Quick Start Card (Print This!)

## 📋 What Is MVVM?

```
Model (Data)
   ↕
ViewModel (Logic) ← Your code goes here
   ↕
View (UI)         ← Only UI code here
```

## 🚀 5-Minute Overview

| Layer | What | File |
|-------|------|------|
| **ViewModel** | Business logic | `chat_view_model.dart` |
| **View** | UI only | `chat_page_mvvm.dart` |
| **Service** | Low-level ops | (existing files) |

## 📁 Files You Just Got

### Code (Ready to Use)
- ✅ `lib/presentation/base_view_model.dart` - Base class for all ViewModels
- ✅ `lib/presentation/viewmodels/chat_view_model.dart` - Example ViewModel
- ✅ `lib/presentation/viewmodels/profile_view_model.dart` - Another example
- ✅ `lib/presentation/pages/chat_page_mvvm.dart` - Refactored UI example

### Docs (Read These)
- 📖 `MVVM_ARCHITECTURE_GUIDE.md` - Complete reference
- 📖 `MVVM_BEFORE_AFTER.md` - Code examples
- 📖 `MVVM_QUICK_START.md` - Step-by-step checklist
- 📖 `MVVM_DIAGRAMS.md` - Visual diagrams
- 📖 `README_MVVM.md` - Master overview

## 🎯 Key Idea

### ❌ OLD (Mixed)
```dart
class ChatPageState {
  final _messagingService = MessagingService(); // Services here
  List<ChatMessage> _messages = [];              // State here
  
  void _sendMessage() {                          // Logic here
    _messagingService.sendMessage(text);
    setState(() { _messages.add(...); });
  }
  
  @override
  Widget build(BuildContext context) {           // UI here
    return ListView(children: _messages);
  }
}
```

### ✅ NEW (Separated)
```dart
// VIEWMODEL (Logic)
class ChatViewModel extends BaseViewModel {
  final _messagingService = MessagingService();
  List<ChatMessage> _messages = [];
  
  Future<void> sendMessage() async {
    await _messagingService.sendMessage(text);
    notifyListeners(); // Tell UI to rebuild
  }
}

// PAGE (UI Only)
class ChatPageState {
  late ChatViewModel _viewModel;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) =>
          ListView(children: vm.messages)
    );
  }
}
```

## 🔄 Data Flow

```
User Action
    ↓
Page calls: viewModel.sendMessage()
    ↓
ViewModel: Updates state, calls notifyListeners()
    ↓
Consumer: Rebuilds UI with new state
```

## 📝 ViewModel Template

```dart
class YourViewModel extends BaseViewModel {
  // 1. Services
  final _service = YourService();
  
  // 2. Private state
  List<Item> _items = [];
  
  // 3. Public getters
  List<Item> get items => _items;
  
  // 4. Initialize
  Future<void> initialize() async {
    await executeAsync(() async {
      _items = await _service.loadItems();
    });
  }
  
  // 5. Methods
  Future<void> doSomething() async {
    await executeAsync(() async {
      await _service.operation();
      _items = await _service.loadItems();
      notifyListeners();
    });
  }
  
  // 6. Cleanup
  @override
  void dispose() {
    // cleanup here
    super.dispose();
  }
}
```

## 📝 Page Template

```dart
class YourPageMVVM extends StatefulWidget {
  @override
  State<YourPageMVVM> createState() => _YourPageMVVMState();
}

class _YourPageMVVMState extends State<YourPageMVVM> {
  late YourViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = YourViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<YourViewModel>.value(
      value: _viewModel,
      child: Consumer<YourViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const CircularProgressIndicator();
          }
          return ListView(
            children: viewModel.items.map((item) =>
              ListTile(
                title: Text(item.name),
                onTap: () => viewModel.selectItem(item),
              )
            ).toList(),
          );
        },
      ),
    );
  }
}
```

## ✅ Quick Checklist

### Creating a ViewModel
- [ ] Extend `BaseViewModel`
- [ ] Add services as final fields
- [ ] Add private state variables
- [ ] Add public getters for state
- [ ] Create `initialize()` method
- [ ] Add public methods for actions
- [ ] Call `notifyListeners()` after state changes
- [ ] Override `dispose()` to cleanup

### Refactoring a Page
- [ ] Create the ViewModel first
- [ ] Copy the new Page template
- [ ] Replace build() with Consumer widget
- [ ] Call ViewModel methods instead of local functions
- [ ] Read state from ViewModel getters
- [ ] Remove service imports from page
- [ ] Test thoroughly

## 🔑 Key Methods

### In BaseViewModel
```dart
setLoading(bool)           // Update loading state
setError(String?)          // Set error message
clearError()               // Clear error
executeAsync<T>(() async)  // Wrapper for safe async
notifyListeners()          // Notify UI of changes
dispose()                  // Cleanup resources
```

### In Consumer
```dart
Consumer<ChatViewModel>(
  builder: (context, viewModel, _) {
    // viewModel is your ViewModel instance
    // Rebuilds when notifyListeners() called
  }
)
```

## 🚀 Implementation Order

1. **Week 1**: Chat Feature
   - Create ChatViewModel ✅
   - Create ChatPageMVVM ✅
   - Test & verify

2. **Week 2**: Profile Feature
   - Create ProfileViewModel ✅
   - Create ProfilePageMVVM
   - Test & verify

3. **Week 3-4**: Dashboard, Landing, Resources
   - Create ViewModels
   - Create Pages
   - Test each feature

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| State not updating | Call `notifyListeners()` after state change |
| Consumer not found | Use `ChangeNotifierProvider.value(_viewModel)` |
| Memory leak | Call `dispose()` in ViewModel and Page |
| Null pointer | Initialize ViewModel in `initState()` |
| Old code still running | Verify you're using new Page, not old one |

## 📚 Reading Order

1. Start: `README_MVVM.md` (this overview)
2. Theory: `MVVM_ARCHITECTURE_GUIDE.md`
3. Examples: `MVVM_BEFORE_AFTER.md`
4. Implement: `MVVM_QUICK_START.md`
5. Reference: Keep other docs handy

## 💡 Remember

- ✅ ViewModel = Business logic (no UI imports)
- ✅ Page = UI only (no service calls)
- ✅ Services = Low-level operations (unchanged)
- ✅ notifyListeners() = Tells UI to rebuild
- ✅ Consumer = Listens for rebuilds
- ✅ Provider = Connects ViewModel to UI

## 🎯 Next Step

1. Open `lib/presentation/viewmodels/chat_view_model.dart`
2. Compare with your `lib/pages/chat_page.dart`
3. Understand the differences
4. Read `MVVM_ARCHITECTURE_GUIDE.md`
5. Start implementing!

---

**You've got this! 🚀 Start with Chat, then repeat for other features.**
