import '../../domain/entities/voice_command.dart';

class VoiceCommandModel extends VoiceCommand {
  VoiceCommandModel({
    required String action,
    String? location,
    String? date,
  }) : super(action: action, location: location, date: date);

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      action: json['action'] ?? 'unknown action',
      location: json['location'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'location': location,
      'date': date,
    };
  }
}