import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/history_provider.dart';
import '../../../editor/providers/editor_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final filteredHistory = _filterHistory(historyState.history);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: historyState.history.isNotEmpty
                ? () => _showClearHistoryDialog()
                : null,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(filteredHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search code history...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No code history yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Execute some code to see it appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildHistoryList(List<HistoryEntry> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _buildHistoryItem(entry, index);
      },
    );
  }

  Widget _buildHistoryItem(HistoryEntry entry, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _loadCodeFromHistory(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.code,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(entry.timestamp),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleHistoryAction(value, entry),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'load',
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, size: 20),
                            SizedBox(width: 8),
                            Text('Load in Editor'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Copy Code'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  _truncateCode(entry.code),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMetadataChip('${entry.lineCount} lines'),
                  const SizedBox(width: 8),
                  _buildMetadataChip('${entry.characterCount} chars'),
                  if (entry.executionSuccess != null) ...[
                    const SizedBox(width: 8),
                    _buildStatusChip(entry.executionSuccess!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildMetadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool success) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            size: 10,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            success ? 'Success' : 'Error',
            style: TextStyle(
              fontSize: 10,
              color: success ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<HistoryEntry> _filterHistory(List<HistoryEntry> history) {
    if (_searchQuery.isEmpty) return history;
    
    return history.where((entry) {
      return entry.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _truncateCode(String code) {
    const maxLength = 200;
    if (code.length <= maxLength) return code;
    return '${code.substring(0, maxLength)}...';
  }

  void _loadCodeFromHistory(HistoryEntry entry) {
    ref.read(editorProvider.notifier).updateCode(entry.code);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code loaded in editor')),
    );
  }

  void _handleHistoryAction(String action, HistoryEntry entry) {
    switch (action) {
      case 'load':
        _loadCodeFromHistory(entry);
        break;
      case 'copy':
        Clipboard.setData(ClipboardData(text: entry.code));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code copied to clipboard')),
        );
        break;
      case 'delete':
        ref.read(historyProvider.notifier).deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History entry deleted')),
        );
        break;
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all code history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}