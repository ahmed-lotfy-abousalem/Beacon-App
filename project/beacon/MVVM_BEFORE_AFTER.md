# MVVM Refactoring - Before & After Examples

## Example 1: Chat Feature

### ❌ BEFORE (Without MVVM - Mixed Concerns)

```dart
// lib/pages/chat_page.dart - Everything in one file
class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Service instances mixed with state
  final TextEditingController _messageController = TextEditingController();
  late final MessagingService _messagingService;
  late final WiFiDirectService _wifiDirectService;
  late final SpeechToTextService _speechToTextService;
  late final TextToSpeechService _textToSpeechService;
  
  // Multiple state variables scattered
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  bool _isConnected = false;
  bool _isSocketConnected = false;
  bool _isSpeechListening = false;
  bool _isTTSSpeaking = false;
  String _currentSpeakingMessageId = '';

  @override
  void initState() {
    super.initState();
    // Manual initialization of all services
    _messagingService = MessagingService();
    _wifiDirectService = WiFiDirectService();
    _speechToTextService = SpeechToTextService();
    _textToSpeechService = TextToSpeechService();
    _initializeMessaging();
    _initializeSpeechToText();
    _initializeTextToSpeech();
  }

  // Business logic scattered in multiple methods
  Future<void> _initializeMessaging() async {
    await _messagingService.initialize();
    _messageSubscription = _messagingService.messageStream.listen((message) {
      if (mounted) {
        setState(() { /* trigger rebuild */ });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    // ... more setup code
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _isConnected) {
      _messageController.clear();
      final success = await _messagingService.sendMessage(text);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageSubscription?.cancel();
    _socketEventSubscription?.cancel();
    _speechToTextService.dispose();
    _textToSpeechService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Chat')),
      body: Column(
        children: [
          // Status bar with hardcoded logic
          if (_isSocketConnected)
            Container(color: Colors.green, child: Text('Connected'))
          else
            Container(color: Colors.orange, child: Text('Waiting...')),
          
          // Messages list with inline logic
          Expanded(
            child: _messagingService.messages.isEmpty
                ? Center(child: Text('No messages'))
                : ListView.builder(
                    itemCount: _messagingService.messages.length,
                    itemBuilder: (context, index) {
                      final message = _messagingService.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          // Input area with mixed concerns
          Container(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: _isSpeechListening
                      ? _stopSpeechListening
                      : _startSpeechListening,
                  child: Icon(_isSpeechListening ? Icons.mic : Icons.mic_none),
                ),
                FloatingActionButton(
                  onPressed: _isSocketConnected ? _sendMessage : null,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UI and business logic mixed
  Widget _buildMessageBubble(ChatMessage message) {
    final userColor = _getUserColor(message.senderId);
    return Container(
      /* ... complex bubble building logic ... */
    );
  }

  // Problems with this approach:
  // ❌ Hard to test (needs full Flutter context)
  // ❌ Difficult to reuse logic in other pages
  // ❌ UI and logic tightly coupled
  // ❌ Multiple responsibilities in one class
  // ❌ State management scattered across multiple variables
  // ❌ Difficult to maintain and extend
}
```

### ✅ AFTER (With MVVM - Clean Separation)

#### Step 1: Business Logic in ViewModel

```dart
// lib/presentation/viewmodels/chat_view_model.dart
class ChatViewModel extends BaseViewModel {
  // Dependencies clearly declared
  final MessagingService _messagingService = MessagingService();
  final WiFiDirectService _wifiDirectService = WiFiDirectService();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  final TextToSpeechService _textToSpeechService = TextToSpeechService();
  
  // Subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  
  // State - all in one place
  bool _isSocketConnected = false;
  bool _isSpeechListening = false;
  bool _isTTSSpeaking = false;
  String _currentSpeakingMessageId = '';
  final TextEditingController messageController = TextEditingController();
  
  // Public getters - controlled access
  bool get isSocketConnected => _isSocketConnected;
  bool get isSpeechListening => _isSpeechListening;
  bool get isTTSSpeaking => _isTTSSpeaking;
  String get currentSpeakingMessageId => _currentSpeakingMessageId;
  List<ChatMessage> get messages => _messagingService.messages;
  
  // Business logic - all in methods
  Future<void> initialize() async {
    try {
      setLoading(true);
      await _initializeMessaging();
      await _initializeSpeechToText();
      await _initializeTextToSpeech();
      setLoading(false);
    } catch (e) {
      setError('Failed to initialize chat: $e');
    }
  }
  
  Future<void> _initializeMessaging() async {
    // Initialization logic
  }
  
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || !_isSocketConnected) {
      if (text.isEmpty) {
        onError?.call('Message cannot be empty');
      }
      return;
    }
    
    try {
      setLoading(true);
      messageController.clear();
      final success = await _messagingService.sendMessage(text);
      if (!success) {
        onError?.call('Failed to send message...');
      }
      setLoading(false);
    } catch (e) {
      onError?.call('Error: $e');
      setLoading(false);
    }
  }
  
  Future<void> speakMessage(ChatMessage message) async {
    await _textToSpeechService.speak(message.text);
  }
  
  @override
  void dispose() {
    messageController.dispose();
    _messageSubscription?.cancel();
    _socketEventSubscription?.cancel();
    super.dispose();
  }
}
```

#### Step 2: Pure UI in Page

```dart
// lib/presentation/pages/chat_page_mvvm.dart
class ChatPageMVVM extends StatefulWidget {
  @override
  State<ChatPageMVVM> createState() => _ChatPageMVVMState();
}

class _ChatPageMVVMState extends State<ChatPageMVVM> {
  late ChatViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(title: const Text('Emergency Chat')),
        body: Column(
          children: [
            // Status bar - pure UI reading from ViewModel
            Consumer<ChatViewModel>(
              builder: (context, viewModel, _) => Container(
                color: viewModel.isSocketConnected 
                    ? Colors.green 
                    : Colors.orange,
                child: Text(
                  viewModel.isSocketConnected 
                      ? 'Connected' 
                      : 'Waiting...',
                ),
              ),
            ),
            
            // Messages list - pure UI
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, viewModel, _) =>
                    viewModel.messages.isEmpty
                        ? const Center(child: Text('No messages'))
                        : ListView.builder(
                            itemCount: viewModel.messages.length,
                            itemBuilder: (context, index) {
                              final message = viewModel.messages[index];
                              return _buildMessageBubble(
                                message,
                                viewModel,
                              );
                            },
                          ),
              ),
            ),
            
            // Input area - pure UI
            Consumer<ChatViewModel>(
              builder: (context, viewModel, _) => Container(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: viewModel.messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: viewModel.isSpeechListening
                          ? () => viewModel.stopSpeechListening()
                          : () => viewModel.startSpeechListening(),
                      child: Icon(
                        viewModel.isSpeechListening
                            ? Icons.mic
                            : Icons.mic_none,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: viewModel.isSocketConnected
                          ? () => viewModel.sendMessage()
                          : null,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    ChatViewModel viewModel,
  ) {
    return Container(
      /* ... UI only - no logic ... */
    );
  }
}
```

### Benefits of MVVM Refactoring

| Aspect | Before (Mixed) | After (MVVM) |
|--------|---|---|
| **Lines in State class** | 400+ lines | 150 lines (pure UI) |
| **Testability** | Hard (needs Flutter) | Easy (test ViewModel without UI) |
| **Code Reusability** | No | Yes (ViewModel can be reused) |
| **Maintainability** | Hard | Easy (clear responsibilities) |
| **Debugging** | Hard (mixed logic) | Easy (separate concerns) |
| **Adding Features** | Complex (affects whole class) | Simple (add to ViewModel) |

---

## Example 2: Profile Feature

### ❌ BEFORE

```dart
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mixed state
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _error;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  void _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // Business logic mixed with setState
      final profile = await _fetchProfile();
      setState(() {
        _userProfile = profile;
        _nameController.text = profile.name;
        _bioController.text = profile.bio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _saveProfile() async {
    // Validation mixed with UI update logic
    if (_nameController.text.isEmpty) {
      setState(() => _error = 'Name required');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _updateProfile(UserProfile(
        name: _nameController.text,
        bio: _bioController.text,
      ));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved!')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!_isEditing)
              Text(_userProfile?.name ?? 'No name')
            else
              TextField(controller: _nameController),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isEditing ? _saveProfile : () {
                setState(() => _isEditing = true);
              },
              child: Text(_isEditing ? 'Save' : 'Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### ✅ AFTER

```dart
// ViewModel - All business logic
class ProfileViewModel extends BaseViewModel {
  UserProfile? _userProfile;
  bool _isEditing = false;
  String? _validationError;
  
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  
  UserProfile? get userProfile => _userProfile;
  bool get isEditing => _isEditing;
  String? get validationError => _validationError;
  
  Future<void> initialize() async {
    setLoading(true);
    await loadProfile();
    setLoading(false);
  }
  
  Future<void> loadProfile() async {
    // Business logic
    _userProfile = await _fetchProfile();
    nameController.text = _userProfile?.name ?? '';
    bioController.text = _userProfile?.bio ?? '';
    notifyListeners();
  }
  
  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  bool _validateProfile() {
    if (nameController.text.isEmpty) {
      _validationError = 'Name required';
      notifyListeners();
      return false;
    }
    _validationError = null;
    return true;
  }
  
  Future<void> saveProfile() async {
    if (!_validateProfile()) return;
    
    setLoading(true);
    try {
      await _updateProfile(UserProfile(
        name: nameController.text,
        bio: bioController.text,
      ));
      _isEditing = false;
      notifyListeners();
    } catch (e) {
      setError('Failed: $e');
    }
    setLoading(false);
  }
}

// Page - Pure UI
class ProfilePageMVVM extends StatefulWidget {
  @override
  State<ProfilePageMVVM> createState() => _ProfilePageMVVMState();
}

class _ProfilePageMVVMState extends State<ProfilePageMVVM> {
  late ProfileViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.initialize();
  }
  
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileViewModel>.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  if (!viewModel.isEditing)
                    Text(viewModel.userProfile?.name ?? 'No name')
                  else
                    TextField(controller: viewModel.nameController),
                  if (viewModel.validationError != null)
                    Text(
                      viewModel.validationError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ElevatedButton(
                    onPressed: viewModel.isEditing
                        ? () => viewModel.saveProfile()
                        : () => viewModel.toggleEditing(),
                    child: Text(viewModel.isEditing ? 'Save' : 'Edit'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Key Differences Summary

### Architecture
| | Before | After |
|---|---|---|
| **Separation** | Mixed | Clear layers |
| **Testing** | Difficult | Easy |
| **Reusability** | Low | High |
| **Scalability** | Poor | Excellent |
| **Maintenance** | Hard | Easy |

### Code Quality
- **Before**: Many `setState()` calls, business logic scattered
- **After**: Single `notifyListeners()` per state change, organized logic

### Testing
- **Before**: Need full Flutter environment
- **After**: Can test pure Dart logic

```dart
// Easy to test ViewModel
test('ChatViewModel sends message', () async {
  final viewModel = ChatViewModel();
  await viewModel.initialize();
  
  await viewModel.sendMessage();
  
  expect(viewModel.messages.isNotEmpty, true);
});
```

Start refactoring gradually, one feature at a time!
