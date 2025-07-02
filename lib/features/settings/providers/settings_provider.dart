import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/services/storage_service.dart';

class AppSettings {
  final double fontSize;
  final bool autoSave;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool autoIndent;
  final int executionTimeout;
  final bool autoRun;
  final String apiEndpoint;

  const AppSettings({
    this.fontSize = 14.0,
    this.autoSave = true,
    this.showLineNumbers = true,
    this.wordWrap = false,
    this.autoIndent = true,
    this.executionTimeout = 30,
    this.autoRun = false,
    this.apiEndpoint = 'https://api.dartpad.dev',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      autoSave: json['autoSave'] ?? true,
      showLineNumbers: json['showLineNumbers'] ?? true,
      wordWrap: json['wordWrap'] ?? false,
      autoIndent: json['autoIndent'] ?? true,
      executionTimeout: json['executionTimeout'] ?? 30,
      autoRun: json['autoRun'] ?? false,
      apiEndpoint: json['apiEndpoint'] ?? 'https://api.dartpad.dev',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'autoSave': autoSave,
      'showLineNumbers': showLineNumbers,
      'wordWrap': wordWrap,
      'autoIndent': autoIndent,
      'executionTimeout': executionTimeout,
      'autoRun': autoRun,
      'apiEndpoint': apiEndpoint,
    };
  }

  AppSettings copyWith({
    double? fontSize,
    bool? autoSave,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? autoIndent,
    int? executionTimeout,
    bool? autoRun,
    String? apiEndpoint,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      autoSave: autoSave ?? this.autoSave,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      autoIndent: autoIndent ?? this.autoIndent,
      executionTimeout: executionTimeout ?? this.executionTimeout,
      autoRun: autoRun ?? this.autoRun,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.fontSize == fontSize &&
        other.autoSave == autoSave &&
        other.showLineNumbers == showLineNumbers &&
        other.wordWrap == wordWrap &&
        other.autoIndent == autoIndent &&
        other.executionTimeout == executionTimeout &&
        other.autoRun == autoRun &&
        other.apiEndpoint == apiEndpoint;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      autoSave,
      showLineNumbers,
      wordWrap,
      autoIndent,
      executionTimeout,
      autoRun,
      apiEndpoint,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _settingsKey = 'app_settings';

  Future<void> _loadSettings() async {
    try {
      final settingsJson = StorageService.getString(_settingsKey);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final settings = AppSettings.fromJson(jsonDecode(settingsJson));
        state = settings;
      }
    } catch (e) {
      print('Failed to load settings: $e');
      // Keep default settings
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settingsJson = jsonEncode(state.toJson());
      await StorageService.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  Future<void> updateFontSize(double fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveSettings();
  }

  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);
    await _saveSettings();
  }

  Future<void> updateShowLineNumbers(bool showLineNumbers) async {
    state = state.copyWith(showLineNumbers: showLineNumbers);
    await _saveSettings();
  }

  Future<void> updateWordWrap(bool wordWrap) async {
    state = state.copyWith(wordWrap: wordWrap);
    await _saveSettings();
  }

  Future<void> updateAutoIndent(bool autoIndent) async {
    state = state.copyWith(autoIndent: autoIndent);
    await _saveSettings();
  }

  Future<void> updateExecutionTimeout(int timeout) async {
    state = state.copyWith(executionTimeout: timeout);
    await _saveSettings();
  }

  Future<void> updateAutoRun(bool autoRun) async {
    state = state.copyWith(autoRun: autoRun);
    await _saveSettings();
  }

  Future<void> updateApiEndpoint(String endpoint) async {
    state = state.copyWith(apiEndpoint: endpoint);
    await _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }

  Future<void> importSettings(Map<String, dynamic> settingsData) async {
    try {
      state = AppSettings.fromJson(settingsData);
      await _saveSettings();
    } catch (e) {
      print('Failed to import settings: $e');
      throw Exception('Invalid settings format');
    }
  }

  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});