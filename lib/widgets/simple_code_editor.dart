import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class SimpleCodeEditor extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final double fontSize;
  final bool showLineNumbers;

  const SimpleCodeEditor({
    super.key,
    required this.controller,
    this.onChanged,
    this.fontSize = 14.0,
    this.showLineNumbers = true,
  });

  @override
  State<SimpleCodeEditor> createState() => _SimpleCodeEditorState();
}

class _SimpleCodeEditorState extends State<SimpleCodeEditor> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumbers) _buildLineNumbers(),
          Expanded(child: _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lineCount = widget.controller.text.split('\n').length;
    
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          lineCount,
          (index) => Container(
            height: widget.fontSize * 1.4,
            alignment: Alignment.centerRight,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.fontSize - 2,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Syntax highlighted background (if possible)
        if (widget.controller.text.isNotEmpty)
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: HighlightView(
              widget.controller.text,
              language: 'dart',
              theme: isDark ? vs2015Theme : vsTheme,
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: widget.fontSize,
                height: 1.4,
              ),
            ),
          ),
        // Text input field
        TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          scrollController: _scrollController,
          maxLines: null,
          expands: true,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: widget.fontSize,
            height: 1.4,
            color: widget.controller.text.isEmpty
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent, // Transparent when text exists for syntax highlighting
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            hintText: '// Start typing your Dart code here...\nvoid main() {\n  print(\'Hello, Dart!\');\n}',
          ),
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}

// Even simpler fallback editor without syntax highlighting
class BasicCodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final double fontSize;

  const BasicCodeEditor({
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
          hintText: '// Start typing your Dart code here...\nvoid main() {\n  print(\'Hello, Dart!\');\n}',
        ),
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}