import '../../domain/entities/voice_command.dart';

class VoiceCommandModel extends VoiceCommand {
  VoiceCommandModel({
    required String action,
    String? location,
    String? date,
    double? amount,
    String? category,
    String? query,
    String? language,
    String? listDescription,
    List<String>? items,
    String? originalText,
    String? translatedText,
    String? processedText,
    String? status,
    String? timestamp,
  }) : super(
         action: action,
         location: location,
         date: date,
         amount: amount,
         category: category,
         query: query,
         language: language,
         listDescription: listDescription,
         items: items,
         originalText: originalText,
         translatedText: translatedText,
         processedText: processedText,
         status: status,
         timestamp: timestamp,
       );

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      action: json['action'] ?? 'unknown',
      // Handle empty strings as null values
      location:
          (json['location'] is String && json['location'].isNotEmpty)
              ? json['location']
              : null,
      date:
          (json['date'] is String && json['date'].isNotEmpty)
              ? json['date']
              : null,
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : null,
      category:
          (json['category'] is String && json['category'].isNotEmpty)
              ? json['category']
              : null,
      query:
          (json['query'] is String && json['query'].isNotEmpty)
              ? json['query']
              : null,
      language:
          (json['language'] is String && json['language'].isNotEmpty)
              ? json['language']
              : null,
      listDescription:
          (json['list_description'] is String &&
                  json['list_description'].isNotEmpty)
              ? json['list_description']
              : null,
      items:
          (json['items'] is List)
              ? (json['items'] as List).map((item) => item.toString()).toList()
              : null,
      originalText:
          (json['original_text'] is String && json['original_text'].isNotEmpty)
              ? json['original_text']
              : null,
      translatedText:
          (json['translated_text'] is String &&
                  json['translated_text'].isNotEmpty)
              ? json['translated_text']
              : null,
      processedText:
          (json['processed_text'] is String &&
                  json['processed_text'].isNotEmpty)
              ? json['processed_text']
              : null,
      status:
          (json['status'] is String && json['status'].isNotEmpty)
              ? json['status']
              : 'success',
      timestamp:
          (json['timestamp'] is String && json['timestamp'].isNotEmpty)
              ? json['timestamp']
              : DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'location': location,
      'date': date,
      'amount': amount,
      'category': category,
      'query': query,
      'language': language,
      'list_description': listDescription,
      'items': items,
      'original_text': originalText,
      'translated_text': translatedText,
      'processed_text': processedText,
      'status': status ?? 'success',
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
    };
  }

  // Helper method to create API-friendly JSON
  Map<String, dynamic> toApiJson() {
    return {
      'command_type': action,
      'location': location ?? '',
      'date': date ?? '',
      'amount': amount ?? 0.0,
      'category': category ?? '',
      'query': query ?? '',
      'language': language ?? 'en',
      'list_description': listDescription ?? '',
      'items': items ?? [],
      'original_text': originalText ?? '',
      'translated_text': translatedText ?? '',
      'processed_text': processedText ?? '',
      'status': status ?? 'success',
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
    };
  }
}