import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/editor_provider.dart';
import '../../../../core/models/code_file.dart';
import '../../../../widgets/code_editor_widget.dart';

class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late TextEditingController _controller;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    // Load last saved code
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).loadLastCode();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);

    // Update controller when code changes
    if (_controller.text != editorState.currentCode) {
      _controller.text = editorState.currentCode;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: editorState.currentCode.length),
      );
    }

    return Scaffold(
      appBar: _isFullscreen ? null : AppBar(
        title: Text(editorState.currentFile?.name ?? 'Dart Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: editorState.isExecuting ? null : () => _executeCode(),
            tooltip: 'Run Code',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            onPressed: () => _formatCode(),
            tooltip: 'Format Code',
          ),
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () => _toggleFullscreen(),
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new', child: Text('New File')),
              const PopupMenuItem(value: 'save', child: Text('Save')),
              const PopupMenuItem(value: 'load', child: Text('Load File')),
              const PopupMenuItem(value: 'export', child: Text('Export')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: Text('Clear')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isFullscreen) _buildToolbar(),
          Expanded(
            child: _buildEditor(),
          ),
          if (!_isFullscreen && editorState.isExecuting) _buildExecutionIndicator(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.content_copy,
            tooltip: 'Copy All',
            onPressed: () => _copyToClipboard(),
          ),
          _buildToolbarButton(
            icon: Icons.content_paste,
            tooltip: 'Paste',
            onPressed: () => _pasteFromClipboard(),
          ),
          _buildToolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: () => _undo(),
          ),
          _buildToolbarButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: () => _redo(),
          ),
          const Spacer(),
          _buildToolbarButton(
            icon: Icons.search,
            tooltip: 'Find & Replace',
            onPressed: () => _showFindDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final isDarkMode = AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      child: CodeEditorWidget(
        controller: _controller,
        onChanged: (value) {
          ref.read(editorProvider.notifier).updateCode(value);
        },
        language: 'dart',
        theme: isDarkMode ? vs2015Theme : vsTheme,
        showLineNumbers: true,
        readOnly: false,
      ),
    );
  }

  Widget _buildExecutionIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Executing code...'),
        ],
      ),
    );
  }

  void _executeCode() async {
    final result = await ref.read(editorProvider.notifier).executeCode();
    if (result != null) {
      if (result.success) {
        Fluttertoast.showToast(
          msg: 'Code executed successfully',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Execution failed: ${result.error}',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _formatCode() async {
    await ref.read(editorProvider.notifier).formatCode();
    Fluttertoast.showToast(msg: 'Code formatted');
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _handleMenuAction(String action) {
    final notifier = ref.read(editorProvider.notifier);
    
    switch (action) {
      case 'new':
        _showNewFileDialog();
        break;
      case 'save':
        notifier.saveCurrentFile();
        Fluttertoast.showToast(msg: 'File saved');
        break;
      case 'load':
        _showLoadFileDialog();
        break;
      case 'export':
        notifier.exportCurrentFile();
        Fluttertoast.showToast(msg: 'File exported');
        break;
      case 'clear':
        _showClearDialog();
        break;
    }
  }

  void _showNewFileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'File Name',
            hintText: 'example.dart',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement new file creation
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showLoadFileDialog() {
    // TODO: Implement file loading dialog
    Fluttertoast.showToast(msg: 'Load file dialog');
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Editor'),
        content: const Text('Are you sure you want to clear all code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(editorProvider.notifier).clearCode();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    Fluttertoast.showToast(msg: 'Copied to clipboard');
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _controller.text = data!.text!;
      ref.read(editorProvider.notifier).updateCode(data.text!);
    }
  }

  void _undo() {
    // TODO: Implement undo functionality
    Fluttertoast.showToast(msg: 'Undo');
  }

  void _redo() {
    // TODO: Implement redo functionality
    Fluttertoast.showToast(msg: 'Redo');
  }

  void _showFindDialog() {
    // TODO: Implement find and replace dialog
    Fluttertoast.showToast(msg: 'Find & Replace');
  }
}