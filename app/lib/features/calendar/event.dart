class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.durationMinutes = 60,
    this.location,
    this.notes,
    this.recurrence = 'none',
    this.recurrenceUntil,
    this.reminderMinutes,
  });

  final int id;
  final String title;
  final DateTime startsAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String recurrence;
  final String? recurrenceUntil;
  final int? reminderMinutes;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      recurrence: json['recurrence'] as String? ?? 'none',
      recurrenceUntil: json['recurrence_until'] as String?,
      reminderMinutes: json['reminder_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      'recurrence': recurrence,
      if (recurrenceUntil != null) 'recurrence_until': recurrenceUntil,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
    };
  }
}
