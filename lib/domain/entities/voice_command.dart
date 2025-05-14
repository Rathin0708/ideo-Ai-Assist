class VoiceCommand {
  final String action;
  final String? location;
  final String? date;
  final double? amount;
  final String? category;
  final String? query;
  final String? language;
  final String? listDescription;
  final List<String>? items;
  final String? originalText;
  final String? translatedText;
  final String? processedText;
  final String? status;
  final String? timestamp;

  VoiceCommand({
    required this.action,
    this.location,
    this.date,
    this.amount,
    this.category,
    this.query,
    this.language,
    this.listDescription,
    this.items,
    this.originalText,
    this.translatedText,
    this.processedText,
    this.status,
    this.timestamp,
  });

  @override
  String toString() {
    return 'VoiceCommand(action: $action, location: $location, date: $date, amount: $amount, category: $category, query: $query, language: $language, listDescription: $listDescription, items: $items, originalText: $originalText, translatedText: $translatedText, processedText: $processedText, status: $status, timestamp: $timestamp)';
  }
}