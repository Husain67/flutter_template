import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String language;
  final Map<String, TextStyle>? theme;
  final bool showLineNumbers;
  final bool readOnly;
  final double fontSize;
  final String? placeholder;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.language = 'dart',
    this.theme,
    this.showLineNumbers = true,
    this.readOnly = false,
    this.fontSize = 14.0,
    this.placeholder,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  
  final FocusNode _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _setupScrollSynchronization();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _lineNumberScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupScrollSynchronization() {
    _verticalScrollController.addListener(() {
      if (_lineNumberScrollController.hasClients) {
        _lineNumberScrollController.jumpTo(_verticalScrollController.offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? 
        (Theme.of(context).brightness == Brightness.dark ? vs2015Theme : vsTheme);
    
    return Container(
      decoration: BoxDecoration(
        color: theme['root']?.backgroundColor ?? 
            (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1E1E1E) 
                : Colors.white),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumbers) _buildLineNumbers(),
          Expanded(child: _buildEditor(theme)),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lineCount = widget.controller.text.split('\n').length;
    final textStyle = TextStyle(
      fontFamily: 'JetBrainsMono',
      fontSize: widget.fontSize,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      height: 1.4,
    );

    return Container(
      width: 60,
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
      child: Scrollbar(
        controller: _lineNumberScrollController,
        child: SingleChildScrollView(
          controller: _lineNumberScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              lineCount,
              (index) => Container(
                height: widget.fontSize * 1.4,
                alignment: Alignment.centerRight,
                child: Text(
                  '${index + 1}',
                  style: textStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(Map<String, TextStyle> theme) {
    return Stack(
      children: [
        // Syntax highlighted code (display only)
        Positioned.fill(
          child: _buildHighlightedCode(theme),
        ),
        // Transparent text field for input
        _buildTextInput(),
      ],
    );
  }

  Widget _buildHighlightedCode(Map<String, TextStyle> theme) {
    return Scrollbar(
      controller: _verticalScrollController,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: HighlightView(
                widget.controller.text.isEmpty 
                    ? (widget.placeholder ?? '// Start typing your Dart code here...')
                    : widget.controller.text,
                language: widget.language,
                theme: theme,
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: widget.fontSize,
                  height: 1.4,
                  color: widget.controller.text.isEmpty
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: widget.fontSize,
          height: 1.4,
          color: Colors.transparent, // Make text transparent
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        scrollController: _verticalScrollController,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        inputFormatters: [
          _CodeInputFormatter(),
        ],
        onTap: () {
          _focusNode.requestFocus();
        },
      ),
    );
  }
}

class _CodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Handle auto-indentation
    if (newValue.text.length > oldValue.text.length) {
      final newChar = newValue.text[newValue.selection.baseOffset - 1];
      
      if (newChar == '\n') {
        return _handleNewLine(oldValue, newValue);
      }
      
      if (newChar == '{') {
        return _handleOpenBrace(newValue);
      }
      
      if (newChar == '}') {
        return _handleCloseBrace(newValue);
      }
    }
    
    return newValue;
  }

  TextEditingValue _handleNewLine(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lines = oldValue.text.split('\n');
    final currentLineIndex = _getCurrentLineIndex(oldValue);
    
    if (currentLineIndex < lines.length) {
      final currentLine = lines[currentLineIndex];
      final leadingWhitespace = _getLeadingWhitespace(currentLine);
      
      // Add extra indentation if previous line ends with {
      String indentation = leadingWhitespace;
      if (currentLine.trimRight().endsWith('{')) {
        indentation += '  ';
      }
      
      final newText = newValue.text + indentation;
      final newSelection = newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset + indentation.length,
        extentOffset: newValue.selection.extentOffset + indentation.length,
      );
      
      return newValue.copyWith(
        text: newText,
        selection: newSelection,
      );
    }
    
    return newValue;
  }

  TextEditingValue _handleOpenBrace(TextEditingValue newValue) {
    // Auto-close braces
    final newText = newValue.text.substring(0, newValue.selection.baseOffset) +
        '}' +
        newValue.text.substring(newValue.selection.baseOffset);
    
    return newValue.copyWith(
      text: newText,
      selection: newValue.selection,
    );
  }

  TextEditingValue _handleCloseBrace(TextEditingValue newValue) {
    // Smart closing brace - remove extra indentation
    final lines = newValue.text.split('\n');
    final currentLineIndex = _getCurrentLineIndex(newValue);
    
    if (currentLineIndex < lines.length) {
      final currentLine = lines[currentLineIndex];
      final trimmedLine = currentLine.trimLeft();
      
      if (trimmedLine == '}' && currentLine.startsWith('  ')) {
        // Remove 2 spaces of indentation
        final newLine = currentLine.substring(2);
        lines[currentLineIndex] = newLine;
        
        final newText = lines.join('\n');
        final adjustment = -2;
        
        return newValue.copyWith(
          text: newText,
          selection: newValue.selection.copyWith(
            baseOffset: newValue.selection.baseOffset + adjustment,
            extentOffset: newValue.selection.extentOffset + adjustment,
          ),
        );
      }
    }
    
    return newValue;
  }

  int _getCurrentLineIndex(TextEditingValue value) {
    return value.text.substring(0, value.selection.baseOffset).split('\n').length - 1;
  }

  String _getLeadingWhitespace(String line) {
    final match = RegExp(r'^[ \t]*').firstMatch(line);
    return match?.group(0) ?? '';
  }
}