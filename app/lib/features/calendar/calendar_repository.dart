import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'event.dart';

class CalendarRepository {
  const CalendarRepository(this._api);

  final ApiClient _api;

  Future<List<CalendarEvent>> getEvents({DateTime? from, DateTime? to}) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (from != null) {
      query['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      query['to'] = to.toUtc().toIso8601String();
    }

    final Object? json = await _api.get(
      '/api/calendar/events',
      query: query.isNotEmpty ? query : null,
    );

    if (json is Map<String, dynamic> && json['data'] is List) {
      return (json['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CalendarEvent.fromJson)
          .toList();
    }
    throw const UnexpectedApiException();
  }

  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    final Object? json = await _api.post(
      '/api/calendar/events',
      body: event.toJson(),
    );

    if (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>) {
      return CalendarEvent.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<CalendarEvent> updateEvent(int id, Map<String, dynamic> data) async {
    final Object? json = await _api.put(
      '/api/calendar/events/$id',
      body: data,
    );

    if (json is Map<String, dynamic> && json['data'] is Map<String, dynamic>) {
      return CalendarEvent.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw const UnexpectedApiException();
  }

  Future<void> deleteEvent(int id) async {
    await _api.delete('/api/calendar/events/$id');
  }

  Future<Map<String, dynamic>?> getWidgetData() async {
    final Object? json = await _api.get('/api/calendar/widget');
    if (json is Map<String, dynamic>) {
      return json['next_event'] as Map<String, dynamic>?;
    }
    return null;
  }
}

final Provider<CalendarRepository> calendarRepositoryProvider =
    Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(apiClientProvider)),
);
