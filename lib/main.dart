//程序的主入口
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await StorageService.init();
  
  // Get saved theme mode
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  
  runApp(
    ProviderScope(
      child: MyApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final AdaptiveThemeMode? savedThemeMode;
  
  const MyApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return AdaptiveTheme(
      light: AppTheme.lightTheme,
      dark: AppTheme.darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp.router(
        title: 'Dart Code Editor',
        theme: theme,
        darkTheme: darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}








