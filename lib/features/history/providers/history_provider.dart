import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/services/storage_service.dart';

class HistoryEntry {
  final String id;
  final String code;
  final DateTime timestamp;
  final int lineCount;
  final int characterCount;
  final bool? executionSuccess;
  final String? output;
  final String? error;

  const HistoryEntry({
    required this.id,
    required this.code,
    required this.timestamp,
    required this.lineCount,
    required this.characterCount,
    this.executionSuccess,
    this.output,
    this.error,
  });

  factory HistoryEntry.create({
    required String code,
    bool? executionSuccess,
    String? output,
    String? error,
  }) {
    return HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      timestamp: DateTime.now(),
      lineCount: code.split('\n').length,
      characterCount: code.length,
      executionSuccess: executionSuccess,
      output: output,
      error: error,
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      lineCount: json['lineCount'] ?? 0,
      characterCount: json['characterCount'] ?? 0,
      executionSuccess: json['executionSuccess'],
      output: json['output'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
      'lineCount': lineCount,
      'characterCount': characterCount,
      'executionSuccess': executionSuccess,
      'output': output,
      'error': error,
    };
  }

  HistoryEntry copyWith({
    String? id,
    String? code,
    DateTime? timestamp,
    int? lineCount,
    int? characterCount,
    bool? executionSuccess,
    String? output,
    String? error,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      code: code ?? this.code,
      timestamp: timestamp ?? this.timestamp,
      lineCount: lineCount ?? this.lineCount,
      characterCount: characterCount ?? this.characterCount,
      executionSuccess: executionSuccess ?? this.executionSuccess,
      output: output ?? this.output,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryEntry &&
        other.id == id &&
        other.code == code &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, code, timestamp);
  }
}

class HistoryState {
  final List<HistoryEntry> history;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<HistoryEntry>? history,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState());

  static const String _historyKey = 'execution_history';
  static const int _maxHistoryEntries = 100;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final historyJson = StorageService.getStringList(_historyKey) ?? [];
      final history = historyJson
          .map((json) => HistoryEntry.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort by timestamp (most recent first)
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load history: $e',
      );
    }
  }

  Future<void> addEntry(HistoryEntry entry) async {
    try {
      final updatedHistory = [entry, ...state.history];
      
      // Remove duplicates (same code)
      final uniqueHistory = <HistoryEntry>[];
      final seenCodes = <String>{};
      
      for (final historyEntry in updatedHistory) {
        if (!seenCodes.contains(historyEntry.code)) {
          uniqueHistory.add(historyEntry);
          seenCodes.add(historyEntry.code);
        }
      }
      
      // Limit to max entries
      final limitedHistory = uniqueHistory.take(_maxHistoryEntries).toList();
      
      state = state.copyWith(history: limitedHistory);
      await _saveHistory();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add history entry: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final updatedHistory = state.history.where((entry) => entry.id != id).toList();
      state = state.copyWith(history: updatedHistory);
      await _saveHistory();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete history entry: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      state = state.copyWith(history: []);
      await StorageService.remove(_historyKey);
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear history: $e');
    }
  }

  Future<void> addExecutionEntry({
    required String code,
    required bool success,
    String? output,
    String? error,
  }) async {
    if (code.trim().isEmpty) return;
    
    final entry = HistoryEntry.create(
      code: code,
      executionSuccess: success,
      output: output,
      error: error,
    );
    
    await addEntry(entry);
  }

  Future<void> _saveHistory() async {
    try {
      final historyJson = state.history
          .map((entry) => jsonEncode(entry.toJson()))
          .toList();
      
      await StorageService.setStringList(_historyKey, historyJson);
    } catch (e) {
      print('Failed to save history: $e');
    }
  }

  List<HistoryEntry> getRecentEntries(int count) {
    return state.history.take(count).toList();
  }

  List<HistoryEntry> getSuccessfulEntries() {
    return state.history
        .where((entry) => entry.executionSuccess == true)
        .toList();
  }

  List<HistoryEntry> getFailedEntries() {
    return state.history
        .where((entry) => entry.executionSuccess == false)
        .toList();
  }

  int get totalEntries => state.history.length;
  int get successfulEntries => getSuccessfulEntries().length;
  int get failedEntries => getFailedEntries().length;
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});