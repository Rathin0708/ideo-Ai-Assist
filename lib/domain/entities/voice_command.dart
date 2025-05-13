class VoiceCommand {
  final String action;
  final String? location;
  final String? date;

  VoiceCommand({
    required this.action,
    this.location,
    this.date,
  });

  @override
  String toString() {
    return 'VoiceCommand(action: $action, location: $location, date: $date)';
  }
}