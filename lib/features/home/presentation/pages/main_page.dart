import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

final currentIndexProvider = StateProvider<int>((ref) => 0);

class MainPage extends ConsumerWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(context, ref, index),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.code_outlined),
              activeIcon: Icon(Icons.code),
              label: 'Editor',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.terminal_outlined),
              activeIcon: Icon(Icons.terminal),
              label: 'Output',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ).animate().slideY(
          begin: 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    ref.read(currentIndexProvider.notifier).state = index;
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/editor');
        break;
      case 2:
        context.go('/output');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}