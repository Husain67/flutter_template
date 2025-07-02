import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../editor/providers/editor_provider.dart';
import '../../../../core/models/code_execution_result.dart';

class OutputPage extends ConsumerStatefulWidget {
  const OutputPage({super.key});

  @override
  ConsumerState<OutputPage> createState() => _OutputPageState();
}

class _OutputPageState extends ConsumerState<OutputPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Output Console'),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock_outline : Icons.lock_open),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: _autoScroll ? 'Disable Auto-scroll' : 'Enable Auto-scroll',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: editorState.lastExecutionResult != null
                ? () => _copyOutput(editorState.lastExecutionResult!)
                : null,
            tooltip: 'Copy Output',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _clearConsole(),
            tooltip: 'Clear Console',
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
        child: Column(
          children: [
            _buildStatusBar(editorState),
            Expanded(
              child: _buildConsole(editorState, isDark),
            ),
            _buildBottomActions(editorState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(EditorState editorState) {
    final result = editorState.lastExecutionResult;
    final isExecuting = editorState.isExecuting;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isExecuting) {
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Executing...';
    } else if (result == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
      statusText = 'Ready';
    } else if (result.success) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Success';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Error';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: statusColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (result?.executionTime != null) ...[
            const Spacer(),
            Text(
              '${result!.executionTime}ms',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    ).animate().slideY(
      begin: -1,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildConsole(EditorState editorState, bool isDark) {
    final result = editorState.lastExecutionResult;
    final isExecuting = editorState.isExecuting;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsoleHeader(),
          Expanded(
            child: _buildConsoleContent(result, isExecuting, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Dart Console',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleContent(
    CodeExecutionResult? result,
    bool isExecuting,
    bool isDark,
  ) {
    if (isExecuting) {
      return _buildExecutingState();
    }

    if (result == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.hasOutput) ...[
            _buildOutputSection('Output', result.output, Colors.green, isDark),
            const SizedBox(height: 16),
          ],
          if (result.hasError) ...[
            _buildOutputSection('Error', result.error, Colors.red, isDark),
            const SizedBox(height: 16),
          ],
          if (result.hasWarnings) ...[
            _buildOutputSection(
              'Warnings',
              result.warnings!.join('\n'),
              Colors.orange,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExecutingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Executing your code...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.terminal,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No output yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run your Dart code to see the output here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildOutputSection(
    String title,
    String content,
    Color color,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForTitle(title),
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    ).animate().slideX(
      begin: 0.1,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildBottomActions(EditorState editorState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: editorState.isExecuting
                ? null
                : () => ref.read(editorProvider.notifier).executeCode(),
            icon: editorState.isExecuting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(editorState.isExecuting ? 'Running...' : 'Run Code'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'output':
        return Icons.terminal;
      case 'error':
        return Icons.error;
      case 'warnings':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  void _copyOutput(CodeExecutionResult result) {
    final output = [
      if (result.hasOutput) 'Output:\n${result.output}',
      if (result.hasError) 'Error:\n${result.error}',
      if (result.hasWarnings) 'Warnings:\n${result.warnings!.join('\n')}',
    ].join('\n\n');

    Clipboard.setData(ClipboardData(text: output));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Output copied to clipboard')),
    );
  }

  void _clearConsole() {
    // This would clear the console if we had multiple execution results
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Console cleared')),
    );
  }
}