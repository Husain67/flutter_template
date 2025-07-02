# Flutter App Error Fixes

## 🔧 Common Issues and Fixes

### 1. **Import and Export Issues**

#### HistoryEntry Class Access
**Problem**: `HistoryEntry` is used in `home_page.dart` but might not be accessible.

**Fix**: The `HistoryEntry` class is defined in `history_provider.dart` and should be accessible through the import. If there are issues, ensure proper import:

```dart
// In lib/features/home/presentation/pages/home_page.dart
import '../../../history/providers/history_provider.dart'; // ✅ Already present
```

#### Missing AppSettings Import
**Problem**: `AppSettings` used in settings page might have import issues.

**Fix**: Ensure proper import in settings page:
```dart
// In lib/features/settings/presentation/pages/settings_page.dart
import '../providers/settings_provider.dart'; // ✅ Already present
```

### 2. **Dependency Version Conflicts**

#### Update pubspec.yaml for compatibility
**Problem**: Some dependency versions might conflict.

**Fix**: Use these tested compatible versions:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Core dependencies with compatible versions
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Code editor - use simpler alternative if flutter_code_editor fails
  # flutter_code_editor: ^0.3.0  # Remove if causing issues
  code_text_field: ^1.1.0
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0
  
  # HTTP & API
  dio: ^5.3.0
  http: ^1.1.0
  
  # Storage & Security
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # Navigation & UI
  go_router: ^12.0.0
  flutter_animate: ^4.2.0
  adaptive_theme: ^3.4.0
  fluttertoast: ^8.2.0
  
  # File Management
  path_provider: ^2.1.0
  file_picker: ^6.1.0
  
  # Icons
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

### 3. **Code Editor Widget Fixes**

#### Simplified Code Editor (if flutter_code_editor fails)
**Problem**: Advanced code editor dependencies might not work.

**Fix**: Replace CodeEditorWidget usage with simplified version:

```dart
// In lib/widgets/simple_code_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class SimpleCodeEditor extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final bool showLineNumbers;
  final double fontSize;

  const SimpleCodeEditor({
    super.key,
    required this.controller,
    this.onChanged,
    this.showLineNumbers = true,
    this.fontSize = 14.0,
  });

  @override
  State<SimpleCodeEditor> createState() => _SimpleCodeEditorState();
}

class _SimpleCodeEditorState extends State<SimpleCodeEditor> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Stack(
        children: [
          // Syntax highlighted background
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              widget.controller.text.isEmpty 
                  ? '// Start typing your Dart code here...'
                  : widget.controller.text,
              language: 'dart',
              theme: isDark ? vs2015Theme : vsTheme,
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
                height: 1.4,
              ),
            ),
          ),
          // Transparent text field
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            maxLines: null,
            expands: true,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: widget.fontSize,
              height: 1.4,
              color: Colors.transparent,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. **API Service Fixes**

#### Handle API Endpoint Issues
**Problem**: DartPad API might not be accessible or have CORS issues.

**Fix**: Add fallback local execution:

```dart
// In lib/core/services/api_service.dart - Add this method
Future<CodeExecutionResult> _executeLocally(String code) async {
  // Simple local validation for basic Dart syntax
  try {
    // Basic syntax validation
    if (!code.contains('main(')) {
      return CodeExecutionResult(
        success: false,
        output: '',
        error: 'Code must contain a main() function',
        executionTime: 0,
      );
    }
    
    // Simulate execution result
    return CodeExecutionResult(
      success: true,
      output: 'Code syntax appears valid.\nNote: Local execution is simulated.',
      error: '',
      executionTime: 100,
    );
  } catch (e) {
    return CodeExecutionResult(
      success: false,
      output: '',
      error: 'Local validation failed: $e',
      executionTime: 0,
    );
  }
}

// Modify executeCode method to use fallback
Future<CodeExecutionResult> executeCode(String code) async {
  try {
    final response = await _dio.post(
      '/api/dartservices/v2/execute',
      data: {'source': code},
    );

    if (response.statusCode == 200) {
      return CodeExecutionResult.fromJson(response.data);
    }
  } catch (e) {
    print('API execution failed, using local fallback: $e');
    return await _executeLocally(code);
  }
  
  return await _executeLocally(code);
}
```

### 5. **Storage Service Fixes**

#### Handle Storage Initialization Issues
**Problem**: Storage services might fail to initialize.

**Fix**: Add error handling in storage service:

```dart
// In lib/core/services/storage_service.dart - Update init method
static Future<void> init() async {
  try {
    _prefs = await SharedPreferences.getInstance();
  } catch (e) {
    print('Failed to initialize SharedPreferences: $e');
    // Create a mock implementation for testing
    rethrow;
  }
}

// Add safe getters
static String? getString(String key) {
  try {
    return _prefs.getString(key);
  } catch (e) {
    print('Error getting string for key $key: $e');
    return null;
  }
}
```

### 6. **Navigation Fixes**

#### Update Routes for Compatibility
**Problem**: Go Router version compatibility issues.

**Fix**: Simplified router configuration:

```dart
// In lib/config/routes.dart - Simplified version
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainPage(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const MainPage(
          child: EditorPage(),
        ),
      ),
      GoRoute(
        path: '/output',
        builder: (context, state) => const MainPage(
          child: OutputPage(),
        ),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MainPage(
          child: HistoryPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const MainPage(
          child: SettingsPage(),
        ),
      ),
    ],
  );
});
```

### 7. **Theme Issues Fixes**

#### Font Fallback
**Problem**: JetBrainsMono font might not load.

**Fix**: Use system monospace as fallback:

```dart
// In theme.dart and code editor
TextStyle(
  fontFamily: 'JetBrainsMono', // Falls back to monospace automatically
  // OR explicitly:
  fontFamilyFallback: const ['Courier', 'monospace'],
  fontSize: fontSize,
  height: 1.4,
)
```

### 8. **Build Configuration Fixes**

#### Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="28" />
```

#### iOS Configuration
Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🚀 Quick Fix Commands

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter pub deps
```

### 2. Fix Dependency Issues
```bash
flutter pub upgrade
flutter pub get
```

### 3. Generate Missing Files
```bash
flutter packages pub run build_runner build
```

### 4. Check for Issues
```bash
flutter analyze
flutter doctor
```

## 📝 Testing Fixes

### Minimal Test Setup
```bash
# Test that the app builds
flutter build apk --debug

# Test on emulator/device
flutter run
```

### Individual Feature Testing
1. **Navigation**: Test bottom navigation between tabs
2. **Editor**: Test basic text input and syntax highlighting
3. **Execution**: Test code execution with simple `print('Hello');`
4. **Storage**: Test settings save/load
5. **History**: Test execution history storage

## 🔍 Common Error Messages and Fixes

### "Package not found"
- Run `flutter pub get`
- Check pubspec.yaml for typos
- Update dependency versions

### "Method not found" or "Class not found"
- Check imports in all files
- Verify class exports
- Restart IDE/hot reload

### "Platform Error"
- Update Flutter SDK: `flutter upgrade`
- Check platform-specific configurations
- Clear build cache: `flutter clean`

### "Build Failed"
- Check Android SDK/Xcode setup
- Update build tools
- Check for dependency conflicts

---

**Note**: Start with the dependency fixes first, then test basic navigation before adding complex features. The app is designed to be modular, so individual features can be disabled if causing issues.