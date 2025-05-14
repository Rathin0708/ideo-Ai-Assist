import 'package:flutter/foundation.dart';
import '../../domain/entities/voice_command.dart';

class HistoryItem {
  final String id;
  final DateTime timestamp;
  final VoiceCommand command;

  HistoryItem({
    required this.id,
    required this.timestamp,
    required this.command,
  });
}

class HistoryService extends ChangeNotifier {
  final List<HistoryItem> _history = [];

  List<HistoryItem> get history => List.unmodifiable(_history);

  void addToHistory(VoiceCommand command) {
    final item = HistoryItem(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
      timestamp: DateTime.now(),
      command: command,
    );

    _history.add(item);
    debugPrint('Added to history: ${command.action}');
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  List<HistoryItem> getTranslationHistory() {
    return _history.where((item) =>
    item.command.originalText != null &&
        item.command.translatedText != null
    ).toList();
  }

  List<HistoryItem> getListHistory() {
    return _history.where((item) =>
    item.command.action == 'generate_list' &&
        item.command.items != null &&
        item.command.items!.isNotEmpty
    ).toList();
  }
}