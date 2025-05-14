import 'package:flutter/material.dart';
import '../state/voice_assistant_state.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/voice_command.dart';
import '../../core/services/history_service.dart';
import 'dart:convert';

class ResponseDisplay extends StatelessWidget {
  const ResponseDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<VoiceAssistantState>(context);
    final command = state.command;
    final recognizedText = state.recognizedText;
    final originalText = state.originalText;
    final translatedText = state.translatedText;
    final partialText = state.partialText;
    final speechLanguage = state.speechLanguage;
    final responseMessage = state.responseMessage;
    final isListening = state.isListening;
    final isProcessing = state.isProcessing;
    final commandMode = state.commandMode;
    final items = state.generatedItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode toggle button
          Center(
            child: _buildModeToggleButton(context, state),
          ),
          // Accuracy mode toggle
          Center(
            child: _buildAccuracyToggle(context, state),
          ),

          const SizedBox(height: 20),

          // Placeholder text when not listening
          if (!isListening && !isProcessing && recognizedText.isEmpty &&
              responseMessage.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    _getIconForMode(commandMode),
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.currentPlaceholder,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Listening state UI
          if (isListening && partialText.isEmpty)
            _buildListeningState(context),

          // Real-time speech display
          if (isListening && partialText.isNotEmpty)
            _buildRealtimeSpeechDisplay(context, partialText, speechLanguage),

          // Processing state UI
          if (isProcessing)
            _buildProcessingState(context),

          // Original and translated text UI
          if (originalText.isNotEmpty && !isProcessing) ...[
            _buildRecognizedTextCard(context, originalText, translatedText),
          ],

          // Response message UI
          if (responseMessage.isNotEmpty && !isProcessing)
            _buildResponseCard(context, responseMessage, command),

          // List items UI
          if (items.isNotEmpty && !isProcessing)
            _buildItemsList(context, items),

          // JSON output UI
          if (command != null && !isProcessing)
            _buildJsonOutput(context, command),
        ],
      ),
    );
  }

  IconData _getIconForMode(CommandMode mode) {
    switch (mode) {
      case CommandMode.transaction:
        return Icons.payments;
      case CommandMode.appQuery:
        return Icons.help_outline;
      case CommandMode.listGeneration:
        return Icons.format_list_bulleted;
      default:
        return Icons.mic;
    }
  }

  Widget _buildModeToggleButton(BuildContext context,
      VoiceAssistantState state) {
    final CommandMode mode = state.commandMode;

    return GestureDetector(
      onTap: () {
        state.toggleCommandMode();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .colorScheme
              .primaryContainer,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForMode(mode),
              color: Theme
                  .of(context)
                  .colorScheme
                  .onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getLabelForMode(mode),
              style: TextStyle(
                color: Theme
                    .of(context)
                    .colorScheme
                    .onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.swap_horiz,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onPrimaryContainer,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelForMode(CommandMode mode) {
    switch (mode) {
      case CommandMode.transaction:
        return 'Transaction';
      case CommandMode.appQuery:
        return 'Help';
      case CommandMode.listGeneration:
        return 'Lists';
      default:
        return 'Voice';
    }
  }

  Widget _buildListeningState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sound wave animation
          SizedBox(
            height: 120,
            child: _buildSoundWaveAnimation(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Listening...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
            (index) => _buildAnimatedBar(index),
      ),
    );
  }

  Widget _buildAnimatedBar(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 0.9),
        duration: Duration(milliseconds: 600 + (index * 100)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            width: 8,
            height: 60 * value,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
        onEnd: () {},
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing your request...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedTextCard(BuildContext context, String originalText,
      String translatedText) {
    final bool isTranslated = originalText != translatedText &&
        translatedText.isNotEmpty;
    final state = Provider.of<VoiceAssistantState>(context, listen: false);
    final String languageCode = state.command?.language ?? 'unknown';
    final String languageName = _getLanguageName(languageCode);
    final bool isTamilText = languageCode == 'ta';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, size: 16,
                    color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getLanguageColor(languageCode).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getLanguageColor(languageCode).withOpacity(0.5),
                        width: 1),
                  ),
                  child: Text(
                    languageCode == 'unknown'
                        ? 'Original Voice Input'
                        : languageName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getLanguageColor(languageCode),
                    ),
                  ),
                ),
                const Spacer(),
                if (state.isAccuracyMode)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'AI enhanced',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getLanguageColor(languageCode).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getLanguageColor(languageCode).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                originalText,
                style: TextStyle(
                  fontSize: isTamilText ? 20 : 18,
                  fontWeight: FontWeight.w500,
                  color: _getLanguageTextColor(languageCode),
                  fontFamily: isTamilText ? 'NotoSansTamil' : null,
                ),
              ),
            ),

            // Show translation if available
            if (isTranslated) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.translate, size: 16, color: Theme
                      .of(context)
                      .colorScheme
                      .primary),
                  const SizedBox(width: 8),
                  Text(
                    'Translated to English:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translatedText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onBackground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Gemini Translation',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyToggle(BuildContext context, VoiceAssistantState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: () {
          state.toggleAccuracyMode();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: state.isAccuracyMode
                ? Colors.green.withOpacity(0.15)
                : Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: state.isAccuracyMode
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isAccuracyMode
                    ? Icons.auto_fix_high
                    : Icons.auto_fix_off,
                size: 16,
                color: state.isAccuracyMode
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                state.isAccuracyMode
                    ? "AI Accuracy Enhancement: ON"
                    : "AI Accuracy Enhancement: OFF",
                style: TextStyle(
                  fontSize: 12,
                  color: state.isAccuracyMode
                      ? Colors.green
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    final languageNames = {
      'en': 'English',
      'ta': 'Tamil',
      'te': 'Telugu',
      'ml': 'Malayalam',
      'hi': 'Hindi',
      'bn': 'Bengali',
      'kn': 'Kannada',
      'mr': 'Marathi',
      'pa': 'Punjabi',
      'gu': 'Gujarati',
      'or': 'Odia',
      'ur': 'Urdu',
      'fr': 'French',
      'es': 'Spanish',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'id': 'Indonesian',
      'ms': 'Malay',
      'tr': 'Turkish',
      'nl': 'Dutch',
    };

    return languageNames[code] ?? code.toUpperCase();
  }

  Color _getLanguageColor(String code) {
    final languageColors = {
      'en': const Color(0xFF2196F3), // Blue
      'ta': const Color(0xFF9C27B0), // Purple
      'te': const Color(0xFF4CAF50), // Green
      'ml': const Color(0xFFFF9800), // Orange
      'hi': const Color(0xFFF44336), // Red
      'bn': const Color(0xFF3F51B5), // Indigo
      'kn': const Color(0xFF009688), // Teal
      'mr': const Color(0xFFFFC107), // Amber
      'pa': const Color(0xFFFF5722), // Deep Orange
      'gu': const Color(0xFFCDDC39), // Lime
      'or': const Color(0xFF00BCD4), // Cyan
      'ur': const Color(0xFFE91E63), // Pink
      'unknown': const Color(0xFF9E9E9E), // Grey
    };

    return languageColors[code] ?? Colors.grey;
  }

  Color _getLanguageTextColor(String code) {
    final languageTextColors = {
      'en': const Color(0xFF0D47A1), // Blue 900
      'ta': const Color(0xFF4A148C), // Purple 900
      'te': const Color(0xFF1B5E20), // Green 900
      'ml': const Color(0xFFE65100), // Orange 900
      'hi': const Color(0xFFB71C1C), // Red 900
      'bn': const Color(0xFF1A237E), // Indigo 900
      'kn': const Color(0xFF004D40), // Teal 900
      'mr': const Color(0xFFFF6F00), // Amber 900
      'pa': const Color(0xFFBF360C), // Deep Orange 900
      'gu': const Color(0xFF827717), // Lime 900
      'or': const Color(0xFF006064), // Cyan 900
      'ur': const Color(0xFF880E4F), // Pink 900
      'unknown': const Color(0xFF212121), // Grey 900
    };

    return languageTextColors[code] ?? const Color(0xFF424242); // Grey 800
  }

  bool _isTamilText(String text, VoiceCommand? command) {
    if (command?.language == 'ta') {
      return true;
    }

    // Check for common Tamil text patterns
    return text.contains('பதிவு') ||
        text.contains('சேர்க்கப்பட்டது') ||
        text.contains('பொருட்களுடன்') ||
        text.contains('கேள்வி');
  }

  Widget _buildResponseCard(BuildContext context, String text,
      VoiceCommand? command) {
    final commandMode = Provider
        .of<VoiceAssistantState>(context)
        .commandMode;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Theme
          .of(context)
          .colorScheme
          .secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForMode(commandMode),
                  size: 20,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _getLabelForMode(commandMode),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontFamily: _isTamilText(text, command)
                    ? 'NotoSansTamil'
                    : null,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_list_bulleted,
                  size: 20,
                  color: Theme
                      .of(context)
                      .primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Generated List',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme
                        .of(context)
                        .primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16,
                          color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonOutput(BuildContext context, VoiceCommand command) {
    // Convert command to JSON
    final jsonData = {
      'action': command.action,
      if (command.location != null) 'location': command.location,
      if (command.amount != null) 'amount': command.amount,
      if (command.category != null) 'category': command.category,
      if (command.date != null) 'date': command.date,
      if (command.query != null) 'query': command.query,
      if (command.listDescription != null) 'list_description': command
          .listDescription,
      if (command.items != null && command.items!.isNotEmpty) 'items': command
          .items,
      if (command.language != null) 'language': command.language,
      if (command.originalText != null) 'original_text': command.originalText,
      if (command.translatedText != null) 'translated_text': command
          .translatedText,
      if (command.processedText != null) 'processed_text': command
          .processedText,
      if (command.status != null) 'status': command.status,
      if (command.timestamp != null) 'timestamp': command.timestamp,
    };

    // Format JSON with proper indentation
    final prettyJson = JsonEncoder.withIndent('  ').convert(jsonData);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Colors.grey.shade900,
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
                  color: Colors.green.shade300,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server JSON Output',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade300,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery
                      .of(context)
                      .size
                      .width - 48,
                ),
                child: SelectableText(
                  prettyJson,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green.shade100,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeSpeechDisplay(BuildContext context, String text,
      String languageCode) {
    final bool isTamilText = languageCode == 'ta';
    final bool isTeluguText = languageCode == 'te';
    final bool isHindiText = languageCode == 'hi';
    final bool isMalayalamText = languageCode == 'ml';

    // Get display name for the language
    String languageName = _getLanguageName(languageCode);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getLanguageColor(languageCode).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getLanguageColor(languageCode).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: _getLanguageColor(languageCode),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Listening in $languageName...',
                style: TextStyle(
                  color: _getLanguageColor(languageCode),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _buildPulsatingDot(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: isTamilText || isTeluguText || isHindiText ||
                  isMalayalamText ? 22 : 20,
              fontWeight: FontWeight.w500,
              fontFamily: _getFontForLanguage(languageCode),
            ),
          ),
        ],
      ),
    );
  }

  String? _getFontForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ta':
        return 'NotoSansTamil';
      case 'te':
        return 'NotoSansTelugu';
      case 'hi':
        return 'NotoSansDevanagari';
      case 'ml':
        return 'NotoSansMalayalam';
      default:
        return null;
    }
  }

  Widget _buildPulsatingDot() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(value as double),
          ),
        );
      },
      onEnd: () => {},
    );
  }
}