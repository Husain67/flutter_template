# Quick Error Fixes - Immediate Solutions

## 🚀 Most Common Issues and Fast Fixes

### 1. **Immediate Dependency Fix**

If you encounter dependency issues, replace the pubspec.yaml with this simplified version:

```yaml
name: dart_code_editor
description: A Flutter mobile app for writing and running Dart code.

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Essential dependencies only
  flutter_riverpod: ^2.4.0
  flutter_highlight: ^0.7.0
  highlight: ^0.7.0
  dio: ^5.3.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  go_router: ^12.0.0
  adaptive_theme: ^3.4.0
  fluttertoast: ^8.2.0
  path_provider: ^2.1.0
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

### 2. **Simplified Code Editor Widget**

Replace the complex CodeEditorWidget with this simple version:

```dart
// lib/widgets/simple_code_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class SimpleCodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final double fontSize;

  const SimpleCodeEditor({
    super.key,
    required this.controller,
    this.onChanged,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          height: 1.4,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          hintText: '// Start typing your Dart code here...',
        ),
      ),
    );
  }
}
```

### 3. **Fix Editor Page Import**

Update the editor page to use the simple editor:

```dart
// In lib/features/editor/presentation/pages/editor_page.dart
// Replace the import:
import '../../../../widgets/simple_code_editor.dart';

// Replace the _buildEditor method:
Widget _buildEditor() {
  return SimpleCodeEditor(
    controller: _controller,
    onChanged: (value) {
      ref.read(editorProvider.notifier).updateCode(value);
    },
    fontSize: 14.0,
  );
}
```

### 4. **Simplified API Service**

For immediate testing, use this mock API service:

```dart
// In lib/core/services/api_service.dart - replace executeCode method:
Future<CodeExecutionResult> executeCode(String code) async {
  // Simulate API delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Basic validation
  if (code.trim().isEmpty) {
    return CodeExecutionResult(
      success: false,
      output: '',
      error: 'Code cannot be empty',
      executionTime: 0,
    );
  }
  
  if (!code.contains('main(')) {
    return CodeExecutionResult(
      success: false,
      output: '',
      error: 'Code must contain a main() function',
      executionTime: 0,
    );
  }
  
  // Mock successful execution
  return CodeExecutionResult(
    success: true,
    output: 'Hello, Dart!\nCode executed successfully!\n\nNote: This is a simulated execution.',
    error: '',
    executionTime: 123,
  );
}
```

### 5. **Remove Complex Dependencies**

If flutter_animate or other packages cause issues, remove them:

```dart
// Remove these imports from files:
// import 'package:flutter_animate/flutter_animate.dart';

// Remove .animate() calls:
// Change this:
return Card().animate().fadeIn();
// To this:
return Card();
```

### 6. **Simplified Navigation**

Replace the complex router with simple navigation:

```dart
// lib/config/simple_routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/pages/main_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/editor/presentation/pages/editor_page.dart';
import '../features/output/presentation/pages/output_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainPage(child: HomePage()),
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const MainPage(child: EditorPage()),
      ),
      GoRoute(
        path: '/output',
        builder: (context, state) => const MainPage(child: OutputPage()),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MainPage(child: HistoryPage()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const MainPage(child: SettingsPage()),
      ),
    ],
  );
});
```

### 7. **Emergency Build Commands**

Run these commands in order if you have build issues:

```bash
# 1. Clean everything
flutter clean
rm -rf .dart_tool
rm pubspec.lock

# 2. Get dependencies
flutter pub get

# 3. Try building
flutter build apk --debug

# 4. If still failing, try:
flutter pub deps
flutter doctor -v
```

### 8. **Minimal Working Main.dart**

If all else fails, use this minimal main.dart:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart Code Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dart Code Editor'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Dart Code Editor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Mobile code editor for Dart programming'),
          ],
        ),
      ),
    );
  }
}
```

## ⚡ Emergency Steps

If the app won't build at all:

1. **Copy this minimal pubspec.yaml**:
```yaml
name: dart_code_editor
description: A Flutter app for Dart coding.
version: 1.0.0+1
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
```

2. **Run**: `flutter clean && flutter pub get`

3. **Use the minimal main.dart** above

4. **Test build**: `flutter run`

5. **Gradually add features** one by one

## 🔧 Build Issues Troubleshooting

### Android Issues
- Update Android SDK
- Check `android/app/build.gradle` for correct minSdkVersion (21+)
- Ensure Java 17+ is installed

### iOS Issues  
- Update Xcode to latest version
- Run `cd ios && pod install`
- Check iOS deployment target (12.0+)

### General Issues
- Update Flutter: `flutter upgrade`
- Check `flutter doctor`
- Restart IDE/VS Code
- Delete `.dart_tool` and `build` folders

---

**Quick Start**: Use the minimal versions above to get the app running, then gradually add advanced features back one by one.