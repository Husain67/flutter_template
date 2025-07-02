import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../../core/models/code_file.dart';
import '../../../core/models/code_execution_result.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../history/providers/history_provider.dart';

class EditorState {
  final String currentCode;
  final CodeFile? currentFile;
  final List<CodeFile> files;
  final bool isExecuting;
  final bool hasUnsavedChanges;
  final CodeExecutionResult? lastExecutionResult;

  const EditorState({
    this.currentCode = '',
    this.currentFile,
    this.files = const [],
    this.isExecuting = false,
    this.hasUnsavedChanges = false,
    this.lastExecutionResult,
  });

  EditorState copyWith({
    String? currentCode,
    CodeFile? currentFile,
    List<CodeFile>? files,
    bool? isExecuting,
    bool? hasUnsavedChanges,
    CodeExecutionResult? lastExecutionResult,
  }) {
    return EditorState(
      currentCode: currentCode ?? this.currentCode,
      currentFile: currentFile ?? this.currentFile,
      files: files ?? this.files,
      isExecuting: isExecuting ?? this.isExecuting,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastExecutionResult: lastExecutionResult ?? this.lastExecutionResult,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  final ApiService _apiService;
  final Ref _ref;

  EditorNotifier(this._apiService, this._ref) : super(const EditorState()) {
    _loadFiles();
  }

  void updateCode(String code) {
    state = state.copyWith(
      currentCode: code,
      hasUnsavedChanges: true,
    );
    _autoSave();
  }

  Future<void> loadLastCode() async {
    final lastCode = StorageService.getString(StorageService.lastCodeKey);
    if (lastCode != null && lastCode.isNotEmpty) {
      state = state.copyWith(currentCode: lastCode);
    } else {
      // Load default template
      _loadDefaultTemplate();
    }
  }

  void _loadDefaultTemplate() {
    const defaultCode = '''void main() {
  print('Hello, Dart!');
  
  // Write your Dart code here
  var name = 'Flutter Developer';
  print('Welcome, \$name');
  
  // Example: Creating a list
  var fruits = ['apple', 'banana', 'orange'];
  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''';
    
    state = state.copyWith(currentCode: defaultCode);
  }

  Future<CodeExecutionResult?> executeCode() async {
    if (state.currentCode.isEmpty) return null;
    
    state = state.copyWith(isExecuting: true);
    
    try {
      final result = await _apiService.executeCode(state.currentCode);
      state = state.copyWith(
        isExecuting: false,
        lastExecutionResult: result,
      );
      
      // Add to history
      await _ref.read(historyProvider.notifier).addExecutionEntry(
        code: state.currentCode,
        success: result.success,
        output: result.output,
        error: result.error,
      );
      
      return result;
    } catch (e) {
      final errorResult = CodeExecutionResult(
        success: false,
        output: '',
        error: 'Execution failed: $e',
        executionTime: 0,
      );
      
      state = state.copyWith(
        isExecuting: false,
        lastExecutionResult: errorResult,
      );
      
      // Add error to history
      await _ref.read(historyProvider.notifier).addExecutionEntry(
        code: state.currentCode,
        success: false,
        error: 'Execution failed: $e',
      );
      
      return errorResult;
    }
  }

  Future<void> formatCode() async {
    if (state.currentCode.isEmpty) return;
    
    try {
      final response = await _apiService.formatCode(state.currentCode);
      if (response.isSuccess && response.data != null) {
        state = state.copyWith(
          currentCode: response.data!,
          hasUnsavedChanges: true,
        );
      }
    } catch (e) {
      print('Format code error: $e');
    }
  }

  Future<void> saveCurrentFile() async {
    if (state.currentCode.isEmpty) return;
    
    final file = state.currentFile?.updateContent(state.currentCode) ??
        CodeFile.create(
          name: 'main.dart',
          content: state.currentCode,
        );
    
    final updatedFiles = [...state.files];
    final existingIndex = updatedFiles.indexWhere((f) => f.id == file.id);
    
    if (existingIndex >= 0) {
      updatedFiles[existingIndex] = file;
    } else {
      updatedFiles.add(file);
    }
    
    state = state.copyWith(
      currentFile: file,
      files: updatedFiles,
      hasUnsavedChanges: false,
    );
    
    await _saveFiles();
    await _autoSave();
  }

  Future<void> exportCurrentFile() async {
    if (state.currentCode.isEmpty) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = state.currentFile?.name ?? 'main.dart';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(state.currentCode);
    } catch (e) {
      print('Export error: $e');
    }
  }

  void clearCode() {
    state = state.copyWith(
      currentCode: '',
      hasUnsavedChanges: false,
      currentFile: null,
    );
  }

  Future<void> createNewFile(String name) async {
    final file = CodeFile.create(
      name: name.endsWith('.dart') ? name : '$name.dart',
      content: '',
    );
    
    state = state.copyWith(
      currentFile: file,
      currentCode: '',
      files: [...state.files, file],
      hasUnsavedChanges: false,
    );
    
    await _saveFiles();
  }

  Future<void> loadFile(CodeFile file) async {
    state = state.copyWith(
      currentFile: file,
      currentCode: file.content,
      hasUnsavedChanges: false,
    );
  }

  Future<void> deleteFile(String fileId) async {
    final updatedFiles = state.files.where((f) => f.id != fileId).toList();
    
    state = state.copyWith(files: updatedFiles);
    
    if (state.currentFile?.id == fileId) {
      state = state.copyWith(
        currentFile: null,
        currentCode: '',
        hasUnsavedChanges: false,
      );
    }
    
    await _saveFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final filesJson = StorageService.getStringList('saved_files') ?? [];
      final files = filesJson
          .map((json) => CodeFile.fromJson(jsonDecode(json)))
          .toList();
      
      state = state.copyWith(files: files);
    } catch (e) {
      print('Load files error: $e');
    }
  }

  Future<void> _saveFiles() async {
    try {
      final filesJson = state.files
          .map((file) => jsonEncode(file.toJson()))
          .toList();
      
      await StorageService.setStringList('saved_files', filesJson);
    } catch (e) {
      print('Save files error: $e');
    }
  }

  Future<void> _autoSave() async {
    await StorageService.setString(StorageService.lastCodeKey, state.currentCode);
  }


}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EditorNotifier(apiService, ref);
});