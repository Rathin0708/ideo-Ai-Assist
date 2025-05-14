import '../../domain/entities/voice_command.dart';

class VoiceCommandModel extends VoiceCommand {
  VoiceCommandModel({
    required String action,
    String? location,
    String? date,
  }) : super(action: action, location: location, date: date);

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      action: json['action'] ?? 'unknown',
      location: (json['location'] is String && json['location'].isNotEmpty)
          ? json['location']
          : null,
      date: (json['date'] is String && json['date'].isNotEmpty)
          ? json['date']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'location': location,
      'date': date,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'command_type': action,
      'location': location ?? '',
      'date': date ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}