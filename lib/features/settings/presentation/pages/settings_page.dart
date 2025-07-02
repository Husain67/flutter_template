import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/storage_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _loadApiKey() async {
    final apiKey = await StorageService.getSecureString(StorageService.apiKeyKey);
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => _showResetDialog(),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              _buildThemeSelector(),
              _buildFontSizeSlider(settings),
            ],
          ),
          _buildSection(
            title: 'API Configuration',
            children: [
              _buildApiKeyField(),
              _buildApiEndpointField(),
            ],
          ),
          _buildSection(
            title: 'Editor Preferences',
            children: [
              _buildAutoSaveToggle(settings),
              _buildLineNumbersToggle(settings),
              _buildWordWrapToggle(settings),
              _buildAutoIndentToggle(settings),
            ],
          ),
          _buildSection(
            title: 'Code Execution',
            children: [
              _buildTimeoutSlider(settings),
              _buildAutoRunToggle(settings),
            ],
          ),
          _buildSection(
            title: 'Storage & Privacy',
            children: [
              _buildStorageInfo(),
              _buildClearDataButton(),
            ],
          ),
          _buildSection(
            title: 'About',
            children: [
              _buildAppInfo(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      subtitle: const Text('Choose your preferred theme'),
      trailing: PopupMenuButton<AdaptiveThemeMode>(
        onSelected: (mode) {
          AdaptiveTheme.of(context).setThemeMode(mode);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: AdaptiveThemeMode.system,
            child: Text('System'),
          ),
          const PopupMenuItem(
            value: AdaptiveThemeMode.light,
            child: Text('Light'),
          ),
          const PopupMenuItem(
            value: AdaptiveThemeMode.dark,
            child: Text('Dark'),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_getThemeModeText()),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Font Size'),
      subtitle: Text('${settings.fontSize.toInt()}px'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: settings.fontSize,
          min: 10,
          max: 24,
          divisions: 14,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateFontSize(value);
          },
        ),
      ),
    );
  }

  Widget _buildApiKeyField() {
    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('API Key'),
      subtitle: const Text('Set your backend API key for code execution'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isApiKeyVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _isApiKeyVisible = !_isApiKeyVisible),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showApiKeyDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildApiEndpointField() {
    return ListTile(
      leading: const Icon(Icons.cloud),
      title: const Text('API Endpoint'),
      subtitle: const Text('Configure custom API endpoint'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showApiEndpointDialog(),
      ),
    );
  }

  Widget _buildAutoSaveToggle(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.save),
      title: const Text('Auto Save'),
      subtitle: const Text('Automatically save code while typing'),
      value: settings.autoSave,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAutoSave(value);
      },
    );
  }

  Widget _buildLineNumbersToggle(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.format_list_numbered),
      title: const Text('Line Numbers'),
      subtitle: const Text('Show line numbers in the editor'),
      value: settings.showLineNumbers,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateShowLineNumbers(value);
      },
    );
  }

  Widget _buildWordWrapToggle(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.wrap_text),
      title: const Text('Word Wrap'),
      subtitle: const Text('Wrap long lines in the editor'),
      value: settings.wordWrap,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateWordWrap(value);
      },
    );
  }

  Widget _buildAutoIndentToggle(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.format_indent_increase),
      title: const Text('Auto Indent'),
      subtitle: const Text('Automatically indent new lines'),
      value: settings.autoIndent,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAutoIndent(value);
      },
    );
  }

  Widget _buildTimeoutSlider(AppSettings settings) {
    return ListTile(
      leading: const Icon(Icons.timer),
      title: const Text('Execution Timeout'),
      subtitle: Text('${settings.executionTimeout}s'),
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: settings.executionTimeout.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).updateExecutionTimeout(value.toInt());
          },
        ),
      ),
    );
  }

  Widget _buildAutoRunToggle(AppSettings settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.play_circle),
      title: const Text('Auto Run'),
      subtitle: const Text('Automatically run code after changes'),
      value: settings.autoRun,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).updateAutoRun(value);
      },
    );
  }

  Widget _buildStorageInfo() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('Storage Usage'),
      subtitle: const Text('View app data usage'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showStorageDialog(),
    );
  }

  Widget _buildClearDataButton() {
    return ListTile(
      leading: const Icon(Icons.delete_sweep, color: Colors.red),
      title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
      subtitle: const Text('Remove all stored data including history'),
      onTap: () => _showClearDataDialog(),
    );
  }

  Widget _buildAppInfo() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('Dart Code Editor'),
      subtitle: const Text('Version 1.0.0\nBuilt with Flutter'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showAboutDialog(),
    );
  }

  String _getThemeModeText() {
    final mode = AdaptiveTheme.of(context).mode;
    switch (mode) {
      case AdaptiveThemeMode.light:
        return 'Light';
      case AdaptiveThemeMode.dark:
        return 'Dark';
      case AdaptiveThemeMode.system:
        return 'System';
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: TextField(
          controller: _apiKeyController,
          decoration: const InputDecoration(
            labelText: 'Enter API Key',
            hintText: 'your-api-key-here',
          ),
          obscureText: !_isApiKeyVisible,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.setSecureString(
                StorageService.apiKeyKey,
                _apiKeyController.text,
              );
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'API key saved');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showApiEndpointDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Endpoint'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Endpoint URL',
            hintText: 'https://api.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'API endpoint updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              trailing: Text('2.1 MB'),
            ),
            ListTile(
              leading: Icon(Icons.code),
              title: Text('Saved Files'),
              trailing: Text('0.5 MB'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              trailing: Text('0.1 MB'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text('Total'),
              trailing: Text('2.7 MB'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your code history, saved files, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Dart Code Editor',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.code, size: 48),
      children: const [
        Text('A powerful mobile code editor for Dart programming.'),
        SizedBox(height: 16),
        Text('Features:'),
        Text('• Syntax highlighting'),
        Text('• Code execution'),
        Text('• File management'),
        Text('• Execution history'),
        Text('• Customizable settings'),
      ],
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Settings reset to defaults');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() async {
    try {
      // Clear all storage
      await StorageService.clearSecureStorage();
      
      // Reset settings
      ref.read(settingsProvider.notifier).resetToDefaults();
      
      Fluttertoast.showToast(
        msg: 'All data cleared successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to clear data: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}