// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventRowsTable extends EventRows
    with TableInfo<$EventRowsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _recurrenceUntilMeta = const VerificationMeta(
    'recurrenceUntil',
  );
  @override
  late final GeneratedColumn<String> recurrenceUntil = GeneratedColumn<String>(
    'recurrence_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    startsAt,
    durationMinutes,
    location,
    notes,
    recurrence,
    recurrenceUntil,
    reminderMinutes,
    noteId,
    done,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('recurrence_until')) {
      context.handle(
        _recurrenceUntilMeta,
        recurrenceUntil.isAcceptableOrUnknown(
          data['recurrence_until']!,
          _recurrenceUntilMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      )!,
      recurrenceUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_until'],
      ),
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
    );
  }

  @override
  $EventRowsTable createAlias(String alias) {
    return $EventRowsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final int id;
  final String title;
  final DateTime startsAt;
  final int durationMinutes;
  final String? location;
  final String? notes;

  /// `none`, `daily`, `weekly` or `monthly`.
  final String recurrence;

  /// Last day the event repeats on, as `YYYY-MM-DD` (inclusive).
  final String? recurrenceUntil;
  final int? reminderMinutes;

  /// The note attached to this event, if any. The note may have been
  /// deleted since; readers must cope with a missing note.
  final int? noteId;

  /// An exam or assignment the owner has marked done. Applies to the whole
  /// series when the event repeats.
  final bool done;
  const EventRow({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.durationMinutes,
    this.location,
    this.notes,
    required this.recurrence,
    this.recurrenceUntil,
    this.reminderMinutes,
    this.noteId,
    required this.done,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['recurrence'] = Variable<String>(recurrence);
    if (!nullToAbsent || recurrenceUntil != null) {
      map['recurrence_until'] = Variable<String>(recurrenceUntil);
    }
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || noteId != null) {
      map['note_id'] = Variable<int>(noteId);
    }
    map['done'] = Variable<bool>(done);
    return map;
  }

  EventRowsCompanion toCompanion(bool nullToAbsent) {
    return EventRowsCompanion(
      id: Value(id),
      title: Value(title),
      startsAt: Value(startsAt),
      durationMinutes: Value(durationMinutes),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      recurrence: Value(recurrence),
      recurrenceUntil: recurrenceUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceUntil),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      noteId: noteId == null && nullToAbsent
          ? const Value.absent()
          : Value(noteId),
      done: Value(done),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      recurrenceUntil: serializer.fromJson<String?>(json['recurrenceUntil']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      noteId: serializer.fromJson<int?>(json['noteId']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'recurrence': serializer.toJson<String>(recurrence),
      'recurrenceUntil': serializer.toJson<String?>(recurrenceUntil),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'noteId': serializer.toJson<int?>(noteId),
      'done': serializer.toJson<bool>(done),
    };
  }

  EventRow copyWith({
    int? id,
    String? title,
    DateTime? startsAt,
    int? durationMinutes,
    Value<String?> location = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? recurrence,
    Value<String?> recurrenceUntil = const Value.absent(),
    Value<int?> reminderMinutes = const Value.absent(),
    Value<int?> noteId = const Value.absent(),
    bool? done,
  }) => EventRow(
    id: id ?? this.id,
    title: title ?? this.title,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    location: location.present ? location.value : this.location,
    notes: notes.present ? notes.value : this.notes,
    recurrence: recurrence ?? this.recurrence,
    recurrenceUntil: recurrenceUntil.present
        ? recurrenceUntil.value
        : this.recurrenceUntil,
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    noteId: noteId.present ? noteId.value : this.noteId,
    done: done ?? this.done,
  );
  EventRow copyWithCompanion(EventRowsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      recurrenceUntil: data.recurrenceUntil.present
          ? data.recurrenceUntil.value
          : this.recurrenceUntil,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceUntil: $recurrenceUntil, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('noteId: $noteId, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startsAt,
    durationMinutes,
    location,
    notes,
    recurrence,
    recurrenceUntil,
    reminderMinutes,
    noteId,
    done,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.startsAt == this.startsAt &&
          other.durationMinutes == this.durationMinutes &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.recurrence == this.recurrence &&
          other.recurrenceUntil == this.recurrenceUntil &&
          other.reminderMinutes == this.reminderMinutes &&
          other.noteId == this.noteId &&
          other.done == this.done);
}

class EventRowsCompanion extends UpdateCompanion<EventRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> startsAt;
  final Value<int> durationMinutes;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<String> recurrence;
  final Value<String?> recurrenceUntil;
  final Value<int?> reminderMinutes;
  final Value<int?> noteId;
  final Value<bool> done;
  const EventRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceUntil = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.noteId = const Value.absent(),
    this.done = const Value.absent(),
  });
  EventRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime startsAt,
    this.durationMinutes = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceUntil = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.noteId = const Value.absent(),
    this.done = const Value.absent(),
  }) : title = Value(title),
       startsAt = Value(startsAt);
  static Insertable<EventRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? startsAt,
    Expression<int>? durationMinutes,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<String>? recurrence,
    Expression<String>? recurrenceUntil,
    Expression<int>? reminderMinutes,
    Expression<int>? noteId,
    Expression<bool>? done,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startsAt != null) 'starts_at': startsAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (recurrence != null) 'recurrence': recurrence,
      if (recurrenceUntil != null) 'recurrence_until': recurrenceUntil,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (noteId != null) 'note_id': noteId,
      if (done != null) 'done': done,
    });
  }

  EventRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? startsAt,
    Value<int>? durationMinutes,
    Value<String?>? location,
    Value<String?>? notes,
    Value<String>? recurrence,
    Value<String?>? recurrenceUntil,
    Value<int?>? reminderMinutes,
    Value<int?>? noteId,
    Value<bool>? done,
  }) {
    return EventRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      recurrence: recurrence ?? this.recurrence,
      recurrenceUntil: recurrenceUntil ?? this.recurrenceUntil,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      noteId: noteId ?? this.noteId,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (recurrenceUntil.present) {
      map['recurrence_until'] = Variable<String>(recurrenceUntil.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceUntil: $recurrenceUntil, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('noteId: $noteId, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }
}

class $TransactionRowsTable extends TransactionRows
    with TableInfo<$TransactionRowsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredOnMeta = const VerificationMeta(
    'occurredOn',
  );
  @override
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountCents,
    category,
    occurredOn,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _occurredOnMeta,
        occurredOn.isAcceptableOrUnknown(data['occurred_on']!, _occurredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_on'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TransactionRowsTable createAlias(String alias) {
    return $TransactionRowsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;

  /// `income` or `expense`.
  final String type;

  /// Centavos, so sums never accumulate floating-point error.
  final int amountCents;
  final String category;

  /// `YYYY-MM-DD`; a month is the prefix `YYYY-MM`.
  final String occurredOn;
  final String? note;
  const TransactionRow({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.category,
    required this.occurredOn,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['amount_cents'] = Variable<int>(amountCents);
    map['category'] = Variable<String>(category);
    map['occurred_on'] = Variable<String>(occurredOn);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransactionRowsCompanion toCompanion(bool nullToAbsent) {
    return TransactionRowsCompanion(
      id: Value(id),
      type: Value(type),
      amountCents: Value(amountCents),
      category: Value(category),
      occurredOn: Value(occurredOn),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      category: serializer.fromJson<String>(json['category']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'amountCents': serializer.toJson<int>(amountCents),
      'category': serializer.toJson<String>(category),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'note': serializer.toJson<String?>(note),
    };
  }

  TransactionRow copyWith({
    int? id,
    String? type,
    int? amountCents,
    String? category,
    String? occurredOn,
    Value<String?> note = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    amountCents: amountCents ?? this.amountCents,
    category: category ?? this.category,
    occurredOn: occurredOn ?? this.occurredOn,
    note: note.present ? note.value : this.note,
  );
  TransactionRow copyWithCompanion(TransactionRowsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      category: data.category.present ? data.category.value : this.category,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, amountCents, category, occurredOn, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountCents == this.amountCents &&
          other.category == this.category &&
          other.occurredOn == this.occurredOn &&
          other.note == this.note);
}

class TransactionRowsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> amountCents;
  final Value<String> category;
  final Value<String> occurredOn;
  final Value<String?> note;
  const TransactionRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.category = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.note = const Value.absent(),
  });
  TransactionRowsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int amountCents,
    required String category,
    required String occurredOn,
    this.note = const Value.absent(),
  }) : type = Value(type),
       amountCents = Value(amountCents),
       category = Value(category),
       occurredOn = Value(occurredOn);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? amountCents,
    Expression<String>? category,
    Expression<String>? occurredOn,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountCents != null) 'amount_cents': amountCents,
      if (category != null) 'category': category,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (note != null) 'note': note,
    });
  }

  TransactionRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? amountCents,
    Value<String>? category,
    Value<String>? occurredOn,
    Value<String?>? note,
  }) {
    return TransactionRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      occurredOn: occurredOn ?? this.occurredOn,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $NoteRowsTable extends NoteRows with TableInfo<$NoteRowsTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    tags,
    createdAt,
    updatedAt,
    pinned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
    );
  }

  @override
  $NoteRowsTable createAlias(String alias) {
    return $NoteRowsTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final int id;
  final String title;
  final String body;

  /// JSON array of lower-case tag strings.
  final String tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  const NoteRow({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.pinned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pinned'] = Variable<bool>(pinned);
    return map;
  }

  NoteRowsCompanion toCompanion(bool nullToAbsent) {
    return NoteRowsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      pinned: Value(pinned),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pinned: serializer.fromJson<bool>(json['pinned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pinned': serializer.toJson<bool>(pinned),
    };
  }

  NoteRow copyWith({
    int? id,
    String? title,
    String? body,
    String? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pinned,
  }) => NoteRow(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    pinned: pinned ?? this.pinned,
  );
  NoteRow copyWithCompanion(NoteRowsCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, body, tags, createdAt, updatedAt, pinned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.pinned == this.pinned);
}

class NoteRowsCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> pinned;
  const NoteRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pinned = const Value.absent(),
  });
  NoteRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    required String tags,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.pinned = const Value.absent(),
  }) : title = Value(title),
       body = Value(body),
       tags = Value(tags),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pinned,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pinned != null) 'pinned': pinned,
    });
  }

  NoteRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? pinned,
  }) {
    return NoteRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pinned: $pinned')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShiftRowsTable extends ShiftRows
    with TableInfo<$ShiftRowsTable, ShiftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShiftRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jobMeta = const VerificationMeta('job');
  @override
  late final GeneratedColumn<String> job = GeneratedColumn<String>(
    'job',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breakMinutesMeta = const VerificationMeta(
    'breakMinutes',
  );
  @override
  late final GeneratedColumn<int> breakMinutes = GeneratedColumn<int>(
    'break_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hourlyRateCentsMeta = const VerificationMeta(
    'hourlyRateCents',
  );
  @override
  late final GeneratedColumn<int> hourlyRateCents = GeneratedColumn<int>(
    'hourly_rate_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<bool> paid = GeneratedColumn<bool>(
    'paid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paid" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    job,
    startsAt,
    durationMinutes,
    breakMinutes,
    hourlyRateCents,
    paid,
    seriesId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShiftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job')) {
      context.handle(
        _jobMeta,
        job.isAcceptableOrUnknown(data['job']!, _jobMeta),
      );
    } else if (isInserting) {
      context.missing(_jobMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('break_minutes')) {
      context.handle(
        _breakMinutesMeta,
        breakMinutes.isAcceptableOrUnknown(
          data['break_minutes']!,
          _breakMinutesMeta,
        ),
      );
    }
    if (data.containsKey('hourly_rate_cents')) {
      context.handle(
        _hourlyRateCentsMeta,
        hourlyRateCents.isAcceptableOrUnknown(
          data['hourly_rate_cents']!,
          _hourlyRateCentsMeta,
        ),
      );
    }
    if (data.containsKey('paid')) {
      context.handle(
        _paidMeta,
        paid.isAcceptableOrUnknown(data['paid']!, _paidMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShiftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShiftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      job: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      breakMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}break_minutes'],
      )!,
      hourlyRateCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hourly_rate_cents'],
      )!,
      paid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paid'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
    );
  }

  @override
  $ShiftRowsTable createAlias(String alias) {
    return $ShiftRowsTable(attachedDatabase, alias);
  }
}

class ShiftRow extends DataClass implements Insertable<ShiftRow> {
  final int id;

  /// Where the shift is worked.
  final String job;
  final DateTime startsAt;
  final int durationMinutes;

  /// Unpaid break time inside the shift.
  final int breakMinutes;

  /// Centavos per hour at the time the shift was logged.
  final int hourlyRateCents;

  /// True once the pay for this shift has been received.
  final bool paid;

  /// Shared by the shifts that were added together as one weekly repeat.
  final int? seriesId;
  const ShiftRow({
    required this.id,
    required this.job,
    required this.startsAt,
    required this.durationMinutes,
    required this.breakMinutes,
    required this.hourlyRateCents,
    required this.paid,
    this.seriesId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job'] = Variable<String>(job);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['break_minutes'] = Variable<int>(breakMinutes);
    map['hourly_rate_cents'] = Variable<int>(hourlyRateCents);
    map['paid'] = Variable<bool>(paid);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    return map;
  }

  ShiftRowsCompanion toCompanion(bool nullToAbsent) {
    return ShiftRowsCompanion(
      id: Value(id),
      job: Value(job),
      startsAt: Value(startsAt),
      durationMinutes: Value(durationMinutes),
      breakMinutes: Value(breakMinutes),
      hourlyRateCents: Value(hourlyRateCents),
      paid: Value(paid),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
    );
  }

  factory ShiftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShiftRow(
      id: serializer.fromJson<int>(json['id']),
      job: serializer.fromJson<String>(json['job']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      breakMinutes: serializer.fromJson<int>(json['breakMinutes']),
      hourlyRateCents: serializer.fromJson<int>(json['hourlyRateCents']),
      paid: serializer.fromJson<bool>(json['paid']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'job': serializer.toJson<String>(job),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'breakMinutes': serializer.toJson<int>(breakMinutes),
      'hourlyRateCents': serializer.toJson<int>(hourlyRateCents),
      'paid': serializer.toJson<bool>(paid),
      'seriesId': serializer.toJson<int?>(seriesId),
    };
  }

  ShiftRow copyWith({
    int? id,
    String? job,
    DateTime? startsAt,
    int? durationMinutes,
    int? breakMinutes,
    int? hourlyRateCents,
    bool? paid,
    Value<int?> seriesId = const Value.absent(),
  }) => ShiftRow(
    id: id ?? this.id,
    job: job ?? this.job,
    startsAt: startsAt ?? this.startsAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    breakMinutes: breakMinutes ?? this.breakMinutes,
    hourlyRateCents: hourlyRateCents ?? this.hourlyRateCents,
    paid: paid ?? this.paid,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
  );
  ShiftRow copyWithCompanion(ShiftRowsCompanion data) {
    return ShiftRow(
      id: data.id.present ? data.id.value : this.id,
      job: data.job.present ? data.job.value : this.job,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      breakMinutes: data.breakMinutes.present
          ? data.breakMinutes.value
          : this.breakMinutes,
      hourlyRateCents: data.hourlyRateCents.present
          ? data.hourlyRateCents.value
          : this.hourlyRateCents,
      paid: data.paid.present ? data.paid.value : this.paid,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRow(')
          ..write('id: $id, ')
          ..write('job: $job, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('hourlyRateCents: $hourlyRateCents, ')
          ..write('paid: $paid, ')
          ..write('seriesId: $seriesId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    job,
    startsAt,
    durationMinutes,
    breakMinutes,
    hourlyRateCents,
    paid,
    seriesId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShiftRow &&
          other.id == this.id &&
          other.job == this.job &&
          other.startsAt == this.startsAt &&
          other.durationMinutes == this.durationMinutes &&
          other.breakMinutes == this.breakMinutes &&
          other.hourlyRateCents == this.hourlyRateCents &&
          other.paid == this.paid &&
          other.seriesId == this.seriesId);
}

class ShiftRowsCompanion extends UpdateCompanion<ShiftRow> {
  final Value<int> id;
  final Value<String> job;
  final Value<DateTime> startsAt;
  final Value<int> durationMinutes;
  final Value<int> breakMinutes;
  final Value<int> hourlyRateCents;
  final Value<bool> paid;
  final Value<int?> seriesId;
  const ShiftRowsCompanion({
    this.id = const Value.absent(),
    this.job = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.breakMinutes = const Value.absent(),
    this.hourlyRateCents = const Value.absent(),
    this.paid = const Value.absent(),
    this.seriesId = const Value.absent(),
  });
  ShiftRowsCompanion.insert({
    this.id = const Value.absent(),
    required String job,
    required DateTime startsAt,
    required int durationMinutes,
    this.breakMinutes = const Value.absent(),
    this.hourlyRateCents = const Value.absent(),
    this.paid = const Value.absent(),
    this.seriesId = const Value.absent(),
  }) : job = Value(job),
       startsAt = Value(startsAt),
       durationMinutes = Value(durationMinutes);
  static Insertable<ShiftRow> custom({
    Expression<int>? id,
    Expression<String>? job,
    Expression<DateTime>? startsAt,
    Expression<int>? durationMinutes,
    Expression<int>? breakMinutes,
    Expression<int>? hourlyRateCents,
    Expression<bool>? paid,
    Expression<int>? seriesId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (job != null) 'job': job,
      if (startsAt != null) 'starts_at': startsAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (breakMinutes != null) 'break_minutes': breakMinutes,
      if (hourlyRateCents != null) 'hourly_rate_cents': hourlyRateCents,
      if (paid != null) 'paid': paid,
      if (seriesId != null) 'series_id': seriesId,
    });
  }

  ShiftRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? job,
    Value<DateTime>? startsAt,
    Value<int>? durationMinutes,
    Value<int>? breakMinutes,
    Value<int>? hourlyRateCents,
    Value<bool>? paid,
    Value<int?>? seriesId,
  }) {
    return ShiftRowsCompanion(
      id: id ?? this.id,
      job: job ?? this.job,
      startsAt: startsAt ?? this.startsAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      hourlyRateCents: hourlyRateCents ?? this.hourlyRateCents,
      paid: paid ?? this.paid,
      seriesId: seriesId ?? this.seriesId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (job.present) {
      map['job'] = Variable<String>(job.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (breakMinutes.present) {
      map['break_minutes'] = Variable<int>(breakMinutes.value);
    }
    if (hourlyRateCents.present) {
      map['hourly_rate_cents'] = Variable<int>(hourlyRateCents.value);
    }
    if (paid.present) {
      map['paid'] = Variable<bool>(paid.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShiftRowsCompanion(')
          ..write('id: $id, ')
          ..write('job: $job, ')
          ..write('startsAt: $startsAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('breakMinutes: $breakMinutes, ')
          ..write('hourlyRateCents: $hourlyRateCents, ')
          ..write('paid: $paid, ')
          ..write('seriesId: $seriesId')
          ..write(')'))
        .toString();
  }
}

class $PhoneDayRowsTable extends PhoneDayRows
    with TableInfo<$PhoneDayRowsTable, PhoneDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhoneDayRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenOnMsMeta = const VerificationMeta(
    'screenOnMs',
  );
  @override
  late final GeneratedColumn<int> screenOnMs = GeneratedColumn<int>(
    'screen_on_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlocksMeta = const VerificationMeta(
    'unlocks',
  );
  @override
  late final GeneratedColumn<int> unlocks = GeneratedColumn<int>(
    'unlocks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstPickupMeta = const VerificationMeta(
    'firstPickup',
  );
  @override
  late final GeneratedColumn<DateTime> firstPickup = GeneratedColumn<DateTime>(
    'first_pickup',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restStartMeta = const VerificationMeta(
    'restStart',
  );
  @override
  late final GeneratedColumn<DateTime> restStart = GeneratedColumn<DateTime>(
    'rest_start',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restEndMeta = const VerificationMeta(
    'restEnd',
  );
  @override
  late final GeneratedColumn<DateTime> restEnd = GeneratedColumn<DateTime>(
    'rest_end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    screenOnMs,
    unlocks,
    firstPickup,
    restStart,
    restEnd,
    complete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phone_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhoneDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('screen_on_ms')) {
      context.handle(
        _screenOnMsMeta,
        screenOnMs.isAcceptableOrUnknown(
          data['screen_on_ms']!,
          _screenOnMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenOnMsMeta);
    }
    if (data.containsKey('unlocks')) {
      context.handle(
        _unlocksMeta,
        unlocks.isAcceptableOrUnknown(data['unlocks']!, _unlocksMeta),
      );
    } else if (isInserting) {
      context.missing(_unlocksMeta);
    }
    if (data.containsKey('first_pickup')) {
      context.handle(
        _firstPickupMeta,
        firstPickup.isAcceptableOrUnknown(
          data['first_pickup']!,
          _firstPickupMeta,
        ),
      );
    }
    if (data.containsKey('rest_start')) {
      context.handle(
        _restStartMeta,
        restStart.isAcceptableOrUnknown(data['rest_start']!, _restStartMeta),
      );
    }
    if (data.containsKey('rest_end')) {
      context.handle(
        _restEndMeta,
        restEnd.isAcceptableOrUnknown(data['rest_end']!, _restEndMeta),
      );
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  PhoneDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhoneDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      screenOnMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}screen_on_ms'],
      )!,
      unlocks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unlocks'],
      )!,
      firstPickup: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_pickup'],
      ),
      restStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rest_start'],
      ),
      restEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rest_end'],
      ),
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
    );
  }

  @override
  $PhoneDayRowsTable createAlias(String alias) {
    return $PhoneDayRowsTable(attachedDatabase, alias);
  }
}

class PhoneDayRow extends DataClass implements Insertable<PhoneDayRow> {
  /// `YYYY-MM-DD`.
  final String date;

  /// Time the screen was on.
  final int screenOnMs;
  final int unlocks;

  /// First unlock of the day.
  final DateTime? firstPickup;

  /// The longest stretch with the screen off around the night before this
  /// day; the app cannot know whether that was sleep.
  final DateTime? restStart;
  final DateTime? restEnd;

  /// True once the day was read after it ended. A complete day is never read
  /// again, so the system forgetting it later cannot wipe it.
  final bool complete;
  const PhoneDayRow({
    required this.date,
    required this.screenOnMs,
    required this.unlocks,
    this.firstPickup,
    this.restStart,
    this.restEnd,
    required this.complete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['screen_on_ms'] = Variable<int>(screenOnMs);
    map['unlocks'] = Variable<int>(unlocks);
    if (!nullToAbsent || firstPickup != null) {
      map['first_pickup'] = Variable<DateTime>(firstPickup);
    }
    if (!nullToAbsent || restStart != null) {
      map['rest_start'] = Variable<DateTime>(restStart);
    }
    if (!nullToAbsent || restEnd != null) {
      map['rest_end'] = Variable<DateTime>(restEnd);
    }
    map['complete'] = Variable<bool>(complete);
    return map;
  }

  PhoneDayRowsCompanion toCompanion(bool nullToAbsent) {
    return PhoneDayRowsCompanion(
      date: Value(date),
      screenOnMs: Value(screenOnMs),
      unlocks: Value(unlocks),
      firstPickup: firstPickup == null && nullToAbsent
          ? const Value.absent()
          : Value(firstPickup),
      restStart: restStart == null && nullToAbsent
          ? const Value.absent()
          : Value(restStart),
      restEnd: restEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(restEnd),
      complete: Value(complete),
    );
  }

  factory PhoneDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhoneDayRow(
      date: serializer.fromJson<String>(json['date']),
      screenOnMs: serializer.fromJson<int>(json['screenOnMs']),
      unlocks: serializer.fromJson<int>(json['unlocks']),
      firstPickup: serializer.fromJson<DateTime?>(json['firstPickup']),
      restStart: serializer.fromJson<DateTime?>(json['restStart']),
      restEnd: serializer.fromJson<DateTime?>(json['restEnd']),
      complete: serializer.fromJson<bool>(json['complete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'screenOnMs': serializer.toJson<int>(screenOnMs),
      'unlocks': serializer.toJson<int>(unlocks),
      'firstPickup': serializer.toJson<DateTime?>(firstPickup),
      'restStart': serializer.toJson<DateTime?>(restStart),
      'restEnd': serializer.toJson<DateTime?>(restEnd),
      'complete': serializer.toJson<bool>(complete),
    };
  }

  PhoneDayRow copyWith({
    String? date,
    int? screenOnMs,
    int? unlocks,
    Value<DateTime?> firstPickup = const Value.absent(),
    Value<DateTime?> restStart = const Value.absent(),
    Value<DateTime?> restEnd = const Value.absent(),
    bool? complete,
  }) => PhoneDayRow(
    date: date ?? this.date,
    screenOnMs: screenOnMs ?? this.screenOnMs,
    unlocks: unlocks ?? this.unlocks,
    firstPickup: firstPickup.present ? firstPickup.value : this.firstPickup,
    restStart: restStart.present ? restStart.value : this.restStart,
    restEnd: restEnd.present ? restEnd.value : this.restEnd,
    complete: complete ?? this.complete,
  );
  PhoneDayRow copyWithCompanion(PhoneDayRowsCompanion data) {
    return PhoneDayRow(
      date: data.date.present ? data.date.value : this.date,
      screenOnMs: data.screenOnMs.present
          ? data.screenOnMs.value
          : this.screenOnMs,
      unlocks: data.unlocks.present ? data.unlocks.value : this.unlocks,
      firstPickup: data.firstPickup.present
          ? data.firstPickup.value
          : this.firstPickup,
      restStart: data.restStart.present ? data.restStart.value : this.restStart,
      restEnd: data.restEnd.present ? data.restEnd.value : this.restEnd,
      complete: data.complete.present ? data.complete.value : this.complete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhoneDayRow(')
          ..write('date: $date, ')
          ..write('screenOnMs: $screenOnMs, ')
          ..write('unlocks: $unlocks, ')
          ..write('firstPickup: $firstPickup, ')
          ..write('restStart: $restStart, ')
          ..write('restEnd: $restEnd, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    screenOnMs,
    unlocks,
    firstPickup,
    restStart,
    restEnd,
    complete,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhoneDayRow &&
          other.date == this.date &&
          other.screenOnMs == this.screenOnMs &&
          other.unlocks == this.unlocks &&
          other.firstPickup == this.firstPickup &&
          other.restStart == this.restStart &&
          other.restEnd == this.restEnd &&
          other.complete == this.complete);
}

class PhoneDayRowsCompanion extends UpdateCompanion<PhoneDayRow> {
  final Value<String> date;
  final Value<int> screenOnMs;
  final Value<int> unlocks;
  final Value<DateTime?> firstPickup;
  final Value<DateTime?> restStart;
  final Value<DateTime?> restEnd;
  final Value<bool> complete;
  final Value<int> rowid;
  const PhoneDayRowsCompanion({
    this.date = const Value.absent(),
    this.screenOnMs = const Value.absent(),
    this.unlocks = const Value.absent(),
    this.firstPickup = const Value.absent(),
    this.restStart = const Value.absent(),
    this.restEnd = const Value.absent(),
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhoneDayRowsCompanion.insert({
    required String date,
    required int screenOnMs,
    required int unlocks,
    this.firstPickup = const Value.absent(),
    this.restStart = const Value.absent(),
    this.restEnd = const Value.absent(),
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       screenOnMs = Value(screenOnMs),
       unlocks = Value(unlocks);
  static Insertable<PhoneDayRow> custom({
    Expression<String>? date,
    Expression<int>? screenOnMs,
    Expression<int>? unlocks,
    Expression<DateTime>? firstPickup,
    Expression<DateTime>? restStart,
    Expression<DateTime>? restEnd,
    Expression<bool>? complete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (screenOnMs != null) 'screen_on_ms': screenOnMs,
      if (unlocks != null) 'unlocks': unlocks,
      if (firstPickup != null) 'first_pickup': firstPickup,
      if (restStart != null) 'rest_start': restStart,
      if (restEnd != null) 'rest_end': restEnd,
      if (complete != null) 'complete': complete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhoneDayRowsCompanion copyWith({
    Value<String>? date,
    Value<int>? screenOnMs,
    Value<int>? unlocks,
    Value<DateTime?>? firstPickup,
    Value<DateTime?>? restStart,
    Value<DateTime?>? restEnd,
    Value<bool>? complete,
    Value<int>? rowid,
  }) {
    return PhoneDayRowsCompanion(
      date: date ?? this.date,
      screenOnMs: screenOnMs ?? this.screenOnMs,
      unlocks: unlocks ?? this.unlocks,
      firstPickup: firstPickup ?? this.firstPickup,
      restStart: restStart ?? this.restStart,
      restEnd: restEnd ?? this.restEnd,
      complete: complete ?? this.complete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (screenOnMs.present) {
      map['screen_on_ms'] = Variable<int>(screenOnMs.value);
    }
    if (unlocks.present) {
      map['unlocks'] = Variable<int>(unlocks.value);
    }
    if (firstPickup.present) {
      map['first_pickup'] = Variable<DateTime>(firstPickup.value);
    }
    if (restStart.present) {
      map['rest_start'] = Variable<DateTime>(restStart.value);
    }
    if (restEnd.present) {
      map['rest_end'] = Variable<DateTime>(restEnd.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhoneDayRowsCompanion(')
          ..write('date: $date, ')
          ..write('screenOnMs: $screenOnMs, ')
          ..write('unlocks: $unlocks, ')
          ..write('firstPickup: $firstPickup, ')
          ..write('restStart: $restStart, ')
          ..write('restEnd: $restEnd, ')
          ..write('complete: $complete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhoneAppDayRowsTable extends PhoneAppDayRows
    with TableInfo<$PhoneAppDayRowsTable, PhoneAppDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhoneAppDayRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageMeta = const VerificationMeta(
    'package',
  );
  @override
  late final GeneratedColumn<String> package = GeneratedColumn<String>(
    'package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _foregroundMsMeta = const VerificationMeta(
    'foregroundMs',
  );
  @override
  late final GeneratedColumn<int> foregroundMs = GeneratedColumn<int>(
    'foreground_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, package, label, foregroundMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phone_app_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhoneAppDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('package')) {
      context.handle(
        _packageMeta,
        package.isAcceptableOrUnknown(data['package']!, _packageMeta),
      );
    } else if (isInserting) {
      context.missing(_packageMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('foreground_ms')) {
      context.handle(
        _foregroundMsMeta,
        foregroundMs.isAcceptableOrUnknown(
          data['foreground_ms']!,
          _foregroundMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_foregroundMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, package};
  @override
  PhoneAppDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhoneAppDayRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      package: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      foregroundMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foreground_ms'],
      )!,
    );
  }

  @override
  $PhoneAppDayRowsTable createAlias(String alias) {
    return $PhoneAppDayRowsTable(attachedDatabase, alias);
  }
}

class PhoneAppDayRow extends DataClass implements Insertable<PhoneAppDayRow> {
  final String date;
  final String package;

  /// Kept so the name survives the app being uninstalled.
  final String label;
  final int foregroundMs;
  const PhoneAppDayRow({
    required this.date,
    required this.package,
    required this.label,
    required this.foregroundMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['package'] = Variable<String>(package);
    map['label'] = Variable<String>(label);
    map['foreground_ms'] = Variable<int>(foregroundMs);
    return map;
  }

  PhoneAppDayRowsCompanion toCompanion(bool nullToAbsent) {
    return PhoneAppDayRowsCompanion(
      date: Value(date),
      package: Value(package),
      label: Value(label),
      foregroundMs: Value(foregroundMs),
    );
  }

  factory PhoneAppDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhoneAppDayRow(
      date: serializer.fromJson<String>(json['date']),
      package: serializer.fromJson<String>(json['package']),
      label: serializer.fromJson<String>(json['label']),
      foregroundMs: serializer.fromJson<int>(json['foregroundMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'package': serializer.toJson<String>(package),
      'label': serializer.toJson<String>(label),
      'foregroundMs': serializer.toJson<int>(foregroundMs),
    };
  }

  PhoneAppDayRow copyWith({
    String? date,
    String? package,
    String? label,
    int? foregroundMs,
  }) => PhoneAppDayRow(
    date: date ?? this.date,
    package: package ?? this.package,
    label: label ?? this.label,
    foregroundMs: foregroundMs ?? this.foregroundMs,
  );
  PhoneAppDayRow copyWithCompanion(PhoneAppDayRowsCompanion data) {
    return PhoneAppDayRow(
      date: data.date.present ? data.date.value : this.date,
      package: data.package.present ? data.package.value : this.package,
      label: data.label.present ? data.label.value : this.label,
      foregroundMs: data.foregroundMs.present
          ? data.foregroundMs.value
          : this.foregroundMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhoneAppDayRow(')
          ..write('date: $date, ')
          ..write('package: $package, ')
          ..write('label: $label, ')
          ..write('foregroundMs: $foregroundMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, package, label, foregroundMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhoneAppDayRow &&
          other.date == this.date &&
          other.package == this.package &&
          other.label == this.label &&
          other.foregroundMs == this.foregroundMs);
}

class PhoneAppDayRowsCompanion extends UpdateCompanion<PhoneAppDayRow> {
  final Value<String> date;
  final Value<String> package;
  final Value<String> label;
  final Value<int> foregroundMs;
  final Value<int> rowid;
  const PhoneAppDayRowsCompanion({
    this.date = const Value.absent(),
    this.package = const Value.absent(),
    this.label = const Value.absent(),
    this.foregroundMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhoneAppDayRowsCompanion.insert({
    required String date,
    required String package,
    required String label,
    required int foregroundMs,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       package = Value(package),
       label = Value(label),
       foregroundMs = Value(foregroundMs);
  static Insertable<PhoneAppDayRow> custom({
    Expression<String>? date,
    Expression<String>? package,
    Expression<String>? label,
    Expression<int>? foregroundMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (package != null) 'package': package,
      if (label != null) 'label': label,
      if (foregroundMs != null) 'foreground_ms': foregroundMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhoneAppDayRowsCompanion copyWith({
    Value<String>? date,
    Value<String>? package,
    Value<String>? label,
    Value<int>? foregroundMs,
    Value<int>? rowid,
  }) {
    return PhoneAppDayRowsCompanion(
      date: date ?? this.date,
      package: package ?? this.package,
      label: label ?? this.label,
      foregroundMs: foregroundMs ?? this.foregroundMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (package.present) {
      map['package'] = Variable<String>(package.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (foregroundMs.present) {
      map['foreground_ms'] = Variable<int>(foregroundMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhoneAppDayRowsCompanion(')
          ..write('date: $date, ')
          ..write('package: $package, ')
          ..write('label: $label, ')
          ..write('foregroundMs: $foregroundMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmRowsTable extends AlarmRows
    with TableInfo<$AlarmRowsTable, AlarmRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _soundUriMeta = const VerificationMeta(
    'soundUri',
  );
  @override
  late final GeneratedColumn<String> soundUri = GeneratedColumn<String>(
    'sound_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soundNameMeta = const VerificationMeta(
    'soundName',
  );
  @override
  late final GeneratedColumn<String> soundName = GeneratedColumn<String>(
    'sound_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<int> volume = GeneratedColumn<int>(
    'volume',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _rampSecondsMeta = const VerificationMeta(
    'rampSeconds',
  );
  @override
  late final GeneratedColumn<int> rampSeconds = GeneratedColumn<int>(
    'ramp_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _volumeLockMeta = const VerificationMeta(
    'volumeLock',
  );
  @override
  late final GeneratedColumn<bool> volumeLock = GeneratedColumn<bool>(
    'volume_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("volume_lock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _vibrateMeta = const VerificationMeta(
    'vibrate',
  );
  @override
  late final GeneratedColumn<bool> vibrate = GeneratedColumn<bool>(
    'vibrate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vibrate" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _challengeMeta = const VerificationMeta(
    'challenge',
  );
  @override
  late final GeneratedColumn<String> challenge = GeneratedColumn<String>(
    'challenge',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('math'),
  );
  static const VerificationMeta _challengeCountMeta = const VerificationMeta(
    'challengeCount',
  );
  @override
  late final GeneratedColumn<int> challengeCount = GeneratedColumn<int>(
    'challenge_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _phraseMeta = const VerificationMeta('phrase');
  @override
  late final GeneratedColumn<String> phrase = GeneratedColumn<String>(
    'phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _snoozeLimitMeta = const VerificationMeta(
    'snoozeLimit',
  );
  @override
  late final GeneratedColumn<int> snoozeLimit = GeneratedColumn<int>(
    'snooze_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _snoozeMinutesMeta = const VerificationMeta(
    'snoozeMinutes',
  );
  @override
  late final GeneratedColumn<int> snoozeMinutes = GeneratedColumn<int>(
    'snooze_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _wakeCheckMeta = const VerificationMeta(
    'wakeCheck',
  );
  @override
  late final GeneratedColumn<bool> wakeCheck = GeneratedColumn<bool>(
    'wake_check',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wake_check" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _wakeCheckMinutesMeta = const VerificationMeta(
    'wakeCheckMinutes',
  );
  @override
  late final GeneratedColumn<int> wakeCheckMinutes = GeneratedColumn<int>(
    'wake_check_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hour,
    minute,
    days,
    label,
    enabled,
    soundUri,
    soundName,
    volume,
    rampSeconds,
    volumeLock,
    vibrate,
    challenge,
    challengeCount,
    difficulty,
    phrase,
    snoozeLimit,
    snoozeMinutes,
    wakeCheck,
    wakeCheckMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlarmRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sound_uri')) {
      context.handle(
        _soundUriMeta,
        soundUri.isAcceptableOrUnknown(data['sound_uri']!, _soundUriMeta),
      );
    }
    if (data.containsKey('sound_name')) {
      context.handle(
        _soundNameMeta,
        soundName.isAcceptableOrUnknown(data['sound_name']!, _soundNameMeta),
      );
    }
    if (data.containsKey('volume')) {
      context.handle(
        _volumeMeta,
        volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta),
      );
    }
    if (data.containsKey('ramp_seconds')) {
      context.handle(
        _rampSecondsMeta,
        rampSeconds.isAcceptableOrUnknown(
          data['ramp_seconds']!,
          _rampSecondsMeta,
        ),
      );
    }
    if (data.containsKey('volume_lock')) {
      context.handle(
        _volumeLockMeta,
        volumeLock.isAcceptableOrUnknown(data['volume_lock']!, _volumeLockMeta),
      );
    }
    if (data.containsKey('vibrate')) {
      context.handle(
        _vibrateMeta,
        vibrate.isAcceptableOrUnknown(data['vibrate']!, _vibrateMeta),
      );
    }
    if (data.containsKey('challenge')) {
      context.handle(
        _challengeMeta,
        challenge.isAcceptableOrUnknown(data['challenge']!, _challengeMeta),
      );
    }
    if (data.containsKey('challenge_count')) {
      context.handle(
        _challengeCountMeta,
        challengeCount.isAcceptableOrUnknown(
          data['challenge_count']!,
          _challengeCountMeta,
        ),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('phrase')) {
      context.handle(
        _phraseMeta,
        phrase.isAcceptableOrUnknown(data['phrase']!, _phraseMeta),
      );
    }
    if (data.containsKey('snooze_limit')) {
      context.handle(
        _snoozeLimitMeta,
        snoozeLimit.isAcceptableOrUnknown(
          data['snooze_limit']!,
          _snoozeLimitMeta,
        ),
      );
    }
    if (data.containsKey('snooze_minutes')) {
      context.handle(
        _snoozeMinutesMeta,
        snoozeMinutes.isAcceptableOrUnknown(
          data['snooze_minutes']!,
          _snoozeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('wake_check')) {
      context.handle(
        _wakeCheckMeta,
        wakeCheck.isAcceptableOrUnknown(data['wake_check']!, _wakeCheckMeta),
      );
    }
    if (data.containsKey('wake_check_minutes')) {
      context.handle(
        _wakeCheckMinutesMeta,
        wakeCheckMinutes.isAcceptableOrUnknown(
          data['wake_check_minutes']!,
          _wakeCheckMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlarmRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      soundUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_uri'],
      ),
      soundName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_name'],
      ),
      volume: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume'],
      )!,
      rampSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ramp_seconds'],
      )!,
      volumeLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}volume_lock'],
      )!,
      vibrate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vibrate'],
      )!,
      challenge: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}challenge'],
      )!,
      challengeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}challenge_count'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      phrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phrase'],
      )!,
      snoozeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_limit'],
      )!,
      snoozeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_minutes'],
      )!,
      wakeCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wake_check'],
      )!,
      wakeCheckMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wake_check_minutes'],
      )!,
    );
  }

  @override
  $AlarmRowsTable createAlias(String alias) {
    return $AlarmRowsTable(attachedDatabase, alias);
  }
}

class AlarmRow extends DataClass implements Insertable<AlarmRow> {
  final int id;
  final int hour;
  final int minute;

  /// Weekdays it repeats on: bit 0 is Monday ... bit 6 is Sunday. Zero rings
  /// once and then turns itself off.
  final int days;
  final String label;
  final bool enabled;

  /// A content URI from Android's sound picker; null is the phone's alarm.
  final String? soundUri;
  final String? soundName;

  /// Alarm volume in percent of the phone's maximum.
  final int volume;

  /// Seconds to rise from quiet to [volume]; 0 starts at full volume.
  final int rampSeconds;

  /// Puts the alarm volume back up whenever it is turned down while ringing.
  final bool volumeLock;
  final bool vibrate;

  /// `none`, `math`, `type` or `shake`: what it takes to turn it off.
  final String challenge;

  /// Problems to solve, or shakes to make.
  final int challengeCount;

  /// `easy`, `medium` or `hard` for maths.
  final String difficulty;

  /// The sentence to type for the `type` challenge.
  final String phrase;

  /// How many snoozes are allowed; 0 hides the button.
  final int snoozeLimit;
  final int snoozeMinutes;

  /// Asks "still awake?" a while after it is turned off, and rings again
  /// when nobody answers.
  final bool wakeCheck;
  final int wakeCheckMinutes;
  const AlarmRow({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    required this.label,
    required this.enabled,
    this.soundUri,
    this.soundName,
    required this.volume,
    required this.rampSeconds,
    required this.volumeLock,
    required this.vibrate,
    required this.challenge,
    required this.challengeCount,
    required this.difficulty,
    required this.phrase,
    required this.snoozeLimit,
    required this.snoozeMinutes,
    required this.wakeCheck,
    required this.wakeCheckMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['days'] = Variable<int>(days);
    map['label'] = Variable<String>(label);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || soundUri != null) {
      map['sound_uri'] = Variable<String>(soundUri);
    }
    if (!nullToAbsent || soundName != null) {
      map['sound_name'] = Variable<String>(soundName);
    }
    map['volume'] = Variable<int>(volume);
    map['ramp_seconds'] = Variable<int>(rampSeconds);
    map['volume_lock'] = Variable<bool>(volumeLock);
    map['vibrate'] = Variable<bool>(vibrate);
    map['challenge'] = Variable<String>(challenge);
    map['challenge_count'] = Variable<int>(challengeCount);
    map['difficulty'] = Variable<String>(difficulty);
    map['phrase'] = Variable<String>(phrase);
    map['snooze_limit'] = Variable<int>(snoozeLimit);
    map['snooze_minutes'] = Variable<int>(snoozeMinutes);
    map['wake_check'] = Variable<bool>(wakeCheck);
    map['wake_check_minutes'] = Variable<int>(wakeCheckMinutes);
    return map;
  }

  AlarmRowsCompanion toCompanion(bool nullToAbsent) {
    return AlarmRowsCompanion(
      id: Value(id),
      hour: Value(hour),
      minute: Value(minute),
      days: Value(days),
      label: Value(label),
      enabled: Value(enabled),
      soundUri: soundUri == null && nullToAbsent
          ? const Value.absent()
          : Value(soundUri),
      soundName: soundName == null && nullToAbsent
          ? const Value.absent()
          : Value(soundName),
      volume: Value(volume),
      rampSeconds: Value(rampSeconds),
      volumeLock: Value(volumeLock),
      vibrate: Value(vibrate),
      challenge: Value(challenge),
      challengeCount: Value(challengeCount),
      difficulty: Value(difficulty),
      phrase: Value(phrase),
      snoozeLimit: Value(snoozeLimit),
      snoozeMinutes: Value(snoozeMinutes),
      wakeCheck: Value(wakeCheck),
      wakeCheckMinutes: Value(wakeCheckMinutes),
    );
  }

  factory AlarmRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmRow(
      id: serializer.fromJson<int>(json['id']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      days: serializer.fromJson<int>(json['days']),
      label: serializer.fromJson<String>(json['label']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      soundUri: serializer.fromJson<String?>(json['soundUri']),
      soundName: serializer.fromJson<String?>(json['soundName']),
      volume: serializer.fromJson<int>(json['volume']),
      rampSeconds: serializer.fromJson<int>(json['rampSeconds']),
      volumeLock: serializer.fromJson<bool>(json['volumeLock']),
      vibrate: serializer.fromJson<bool>(json['vibrate']),
      challenge: serializer.fromJson<String>(json['challenge']),
      challengeCount: serializer.fromJson<int>(json['challengeCount']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      phrase: serializer.fromJson<String>(json['phrase']),
      snoozeLimit: serializer.fromJson<int>(json['snoozeLimit']),
      snoozeMinutes: serializer.fromJson<int>(json['snoozeMinutes']),
      wakeCheck: serializer.fromJson<bool>(json['wakeCheck']),
      wakeCheckMinutes: serializer.fromJson<int>(json['wakeCheckMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'days': serializer.toJson<int>(days),
      'label': serializer.toJson<String>(label),
      'enabled': serializer.toJson<bool>(enabled),
      'soundUri': serializer.toJson<String?>(soundUri),
      'soundName': serializer.toJson<String?>(soundName),
      'volume': serializer.toJson<int>(volume),
      'rampSeconds': serializer.toJson<int>(rampSeconds),
      'volumeLock': serializer.toJson<bool>(volumeLock),
      'vibrate': serializer.toJson<bool>(vibrate),
      'challenge': serializer.toJson<String>(challenge),
      'challengeCount': serializer.toJson<int>(challengeCount),
      'difficulty': serializer.toJson<String>(difficulty),
      'phrase': serializer.toJson<String>(phrase),
      'snoozeLimit': serializer.toJson<int>(snoozeLimit),
      'snoozeMinutes': serializer.toJson<int>(snoozeMinutes),
      'wakeCheck': serializer.toJson<bool>(wakeCheck),
      'wakeCheckMinutes': serializer.toJson<int>(wakeCheckMinutes),
    };
  }

  AlarmRow copyWith({
    int? id,
    int? hour,
    int? minute,
    int? days,
    String? label,
    bool? enabled,
    Value<String?> soundUri = const Value.absent(),
    Value<String?> soundName = const Value.absent(),
    int? volume,
    int? rampSeconds,
    bool? volumeLock,
    bool? vibrate,
    String? challenge,
    int? challengeCount,
    String? difficulty,
    String? phrase,
    int? snoozeLimit,
    int? snoozeMinutes,
    bool? wakeCheck,
    int? wakeCheckMinutes,
  }) => AlarmRow(
    id: id ?? this.id,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    days: days ?? this.days,
    label: label ?? this.label,
    enabled: enabled ?? this.enabled,
    soundUri: soundUri.present ? soundUri.value : this.soundUri,
    soundName: soundName.present ? soundName.value : this.soundName,
    volume: volume ?? this.volume,
    rampSeconds: rampSeconds ?? this.rampSeconds,
    volumeLock: volumeLock ?? this.volumeLock,
    vibrate: vibrate ?? this.vibrate,
    challenge: challenge ?? this.challenge,
    challengeCount: challengeCount ?? this.challengeCount,
    difficulty: difficulty ?? this.difficulty,
    phrase: phrase ?? this.phrase,
    snoozeLimit: snoozeLimit ?? this.snoozeLimit,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    wakeCheck: wakeCheck ?? this.wakeCheck,
    wakeCheckMinutes: wakeCheckMinutes ?? this.wakeCheckMinutes,
  );
  AlarmRow copyWithCompanion(AlarmRowsCompanion data) {
    return AlarmRow(
      id: data.id.present ? data.id.value : this.id,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      days: data.days.present ? data.days.value : this.days,
      label: data.label.present ? data.label.value : this.label,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      soundUri: data.soundUri.present ? data.soundUri.value : this.soundUri,
      soundName: data.soundName.present ? data.soundName.value : this.soundName,
      volume: data.volume.present ? data.volume.value : this.volume,
      rampSeconds: data.rampSeconds.present
          ? data.rampSeconds.value
          : this.rampSeconds,
      volumeLock: data.volumeLock.present
          ? data.volumeLock.value
          : this.volumeLock,
      vibrate: data.vibrate.present ? data.vibrate.value : this.vibrate,
      challenge: data.challenge.present ? data.challenge.value : this.challenge,
      challengeCount: data.challengeCount.present
          ? data.challengeCount.value
          : this.challengeCount,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      phrase: data.phrase.present ? data.phrase.value : this.phrase,
      snoozeLimit: data.snoozeLimit.present
          ? data.snoozeLimit.value
          : this.snoozeLimit,
      snoozeMinutes: data.snoozeMinutes.present
          ? data.snoozeMinutes.value
          : this.snoozeMinutes,
      wakeCheck: data.wakeCheck.present ? data.wakeCheck.value : this.wakeCheck,
      wakeCheckMinutes: data.wakeCheckMinutes.present
          ? data.wakeCheckMinutes.value
          : this.wakeCheckMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRow(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('days: $days, ')
          ..write('label: $label, ')
          ..write('enabled: $enabled, ')
          ..write('soundUri: $soundUri, ')
          ..write('soundName: $soundName, ')
          ..write('volume: $volume, ')
          ..write('rampSeconds: $rampSeconds, ')
          ..write('volumeLock: $volumeLock, ')
          ..write('vibrate: $vibrate, ')
          ..write('challenge: $challenge, ')
          ..write('challengeCount: $challengeCount, ')
          ..write('difficulty: $difficulty, ')
          ..write('phrase: $phrase, ')
          ..write('snoozeLimit: $snoozeLimit, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('wakeCheck: $wakeCheck, ')
          ..write('wakeCheckMinutes: $wakeCheckMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hour,
    minute,
    days,
    label,
    enabled,
    soundUri,
    soundName,
    volume,
    rampSeconds,
    volumeLock,
    vibrate,
    challenge,
    challengeCount,
    difficulty,
    phrase,
    snoozeLimit,
    snoozeMinutes,
    wakeCheck,
    wakeCheckMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmRow &&
          other.id == this.id &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.days == this.days &&
          other.label == this.label &&
          other.enabled == this.enabled &&
          other.soundUri == this.soundUri &&
          other.soundName == this.soundName &&
          other.volume == this.volume &&
          other.rampSeconds == this.rampSeconds &&
          other.volumeLock == this.volumeLock &&
          other.vibrate == this.vibrate &&
          other.challenge == this.challenge &&
          other.challengeCount == this.challengeCount &&
          other.difficulty == this.difficulty &&
          other.phrase == this.phrase &&
          other.snoozeLimit == this.snoozeLimit &&
          other.snoozeMinutes == this.snoozeMinutes &&
          other.wakeCheck == this.wakeCheck &&
          other.wakeCheckMinutes == this.wakeCheckMinutes);
}

class AlarmRowsCompanion extends UpdateCompanion<AlarmRow> {
  final Value<int> id;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> days;
  final Value<String> label;
  final Value<bool> enabled;
  final Value<String?> soundUri;
  final Value<String?> soundName;
  final Value<int> volume;
  final Value<int> rampSeconds;
  final Value<bool> volumeLock;
  final Value<bool> vibrate;
  final Value<String> challenge;
  final Value<int> challengeCount;
  final Value<String> difficulty;
  final Value<String> phrase;
  final Value<int> snoozeLimit;
  final Value<int> snoozeMinutes;
  final Value<bool> wakeCheck;
  final Value<int> wakeCheckMinutes;
  const AlarmRowsCompanion({
    this.id = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.days = const Value.absent(),
    this.label = const Value.absent(),
    this.enabled = const Value.absent(),
    this.soundUri = const Value.absent(),
    this.soundName = const Value.absent(),
    this.volume = const Value.absent(),
    this.rampSeconds = const Value.absent(),
    this.volumeLock = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.challenge = const Value.absent(),
    this.challengeCount = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.phrase = const Value.absent(),
    this.snoozeLimit = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.wakeCheck = const Value.absent(),
    this.wakeCheckMinutes = const Value.absent(),
  });
  AlarmRowsCompanion.insert({
    this.id = const Value.absent(),
    required int hour,
    required int minute,
    this.days = const Value.absent(),
    this.label = const Value.absent(),
    this.enabled = const Value.absent(),
    this.soundUri = const Value.absent(),
    this.soundName = const Value.absent(),
    this.volume = const Value.absent(),
    this.rampSeconds = const Value.absent(),
    this.volumeLock = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.challenge = const Value.absent(),
    this.challengeCount = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.phrase = const Value.absent(),
    this.snoozeLimit = const Value.absent(),
    this.snoozeMinutes = const Value.absent(),
    this.wakeCheck = const Value.absent(),
    this.wakeCheckMinutes = const Value.absent(),
  }) : hour = Value(hour),
       minute = Value(minute);
  static Insertable<AlarmRow> custom({
    Expression<int>? id,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? days,
    Expression<String>? label,
    Expression<bool>? enabled,
    Expression<String>? soundUri,
    Expression<String>? soundName,
    Expression<int>? volume,
    Expression<int>? rampSeconds,
    Expression<bool>? volumeLock,
    Expression<bool>? vibrate,
    Expression<String>? challenge,
    Expression<int>? challengeCount,
    Expression<String>? difficulty,
    Expression<String>? phrase,
    Expression<int>? snoozeLimit,
    Expression<int>? snoozeMinutes,
    Expression<bool>? wakeCheck,
    Expression<int>? wakeCheckMinutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (days != null) 'days': days,
      if (label != null) 'label': label,
      if (enabled != null) 'enabled': enabled,
      if (soundUri != null) 'sound_uri': soundUri,
      if (soundName != null) 'sound_name': soundName,
      if (volume != null) 'volume': volume,
      if (rampSeconds != null) 'ramp_seconds': rampSeconds,
      if (volumeLock != null) 'volume_lock': volumeLock,
      if (vibrate != null) 'vibrate': vibrate,
      if (challenge != null) 'challenge': challenge,
      if (challengeCount != null) 'challenge_count': challengeCount,
      if (difficulty != null) 'difficulty': difficulty,
      if (phrase != null) 'phrase': phrase,
      if (snoozeLimit != null) 'snooze_limit': snoozeLimit,
      if (snoozeMinutes != null) 'snooze_minutes': snoozeMinutes,
      if (wakeCheck != null) 'wake_check': wakeCheck,
      if (wakeCheckMinutes != null) 'wake_check_minutes': wakeCheckMinutes,
    });
  }

  AlarmRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? days,
    Value<String>? label,
    Value<bool>? enabled,
    Value<String?>? soundUri,
    Value<String?>? soundName,
    Value<int>? volume,
    Value<int>? rampSeconds,
    Value<bool>? volumeLock,
    Value<bool>? vibrate,
    Value<String>? challenge,
    Value<int>? challengeCount,
    Value<String>? difficulty,
    Value<String>? phrase,
    Value<int>? snoozeLimit,
    Value<int>? snoozeMinutes,
    Value<bool>? wakeCheck,
    Value<int>? wakeCheckMinutes,
  }) {
    return AlarmRowsCompanion(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      soundUri: soundUri ?? this.soundUri,
      soundName: soundName ?? this.soundName,
      volume: volume ?? this.volume,
      rampSeconds: rampSeconds ?? this.rampSeconds,
      volumeLock: volumeLock ?? this.volumeLock,
      vibrate: vibrate ?? this.vibrate,
      challenge: challenge ?? this.challenge,
      challengeCount: challengeCount ?? this.challengeCount,
      difficulty: difficulty ?? this.difficulty,
      phrase: phrase ?? this.phrase,
      snoozeLimit: snoozeLimit ?? this.snoozeLimit,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      wakeCheck: wakeCheck ?? this.wakeCheck,
      wakeCheckMinutes: wakeCheckMinutes ?? this.wakeCheckMinutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (soundUri.present) {
      map['sound_uri'] = Variable<String>(soundUri.value);
    }
    if (soundName.present) {
      map['sound_name'] = Variable<String>(soundName.value);
    }
    if (volume.present) {
      map['volume'] = Variable<int>(volume.value);
    }
    if (rampSeconds.present) {
      map['ramp_seconds'] = Variable<int>(rampSeconds.value);
    }
    if (volumeLock.present) {
      map['volume_lock'] = Variable<bool>(volumeLock.value);
    }
    if (vibrate.present) {
      map['vibrate'] = Variable<bool>(vibrate.value);
    }
    if (challenge.present) {
      map['challenge'] = Variable<String>(challenge.value);
    }
    if (challengeCount.present) {
      map['challenge_count'] = Variable<int>(challengeCount.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (phrase.present) {
      map['phrase'] = Variable<String>(phrase.value);
    }
    if (snoozeLimit.present) {
      map['snooze_limit'] = Variable<int>(snoozeLimit.value);
    }
    if (snoozeMinutes.present) {
      map['snooze_minutes'] = Variable<int>(snoozeMinutes.value);
    }
    if (wakeCheck.present) {
      map['wake_check'] = Variable<bool>(wakeCheck.value);
    }
    if (wakeCheckMinutes.present) {
      map['wake_check_minutes'] = Variable<int>(wakeCheckMinutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmRowsCompanion(')
          ..write('id: $id, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('days: $days, ')
          ..write('label: $label, ')
          ..write('enabled: $enabled, ')
          ..write('soundUri: $soundUri, ')
          ..write('soundName: $soundName, ')
          ..write('volume: $volume, ')
          ..write('rampSeconds: $rampSeconds, ')
          ..write('volumeLock: $volumeLock, ')
          ..write('vibrate: $vibrate, ')
          ..write('challenge: $challenge, ')
          ..write('challengeCount: $challengeCount, ')
          ..write('difficulty: $difficulty, ')
          ..write('phrase: $phrase, ')
          ..write('snoozeLimit: $snoozeLimit, ')
          ..write('snoozeMinutes: $snoozeMinutes, ')
          ..write('wakeCheck: $wakeCheck, ')
          ..write('wakeCheckMinutes: $wakeCheckMinutes')
          ..write(')'))
        .toString();
  }
}

class $FocusLogRowsTable extends FocusLogRows
    with TableInfo<$FocusLogRowsTable, FocusLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focusMsMeta = const VerificationMeta(
    'focusMs',
  );
  @override
  late final GeneratedColumn<int> focusMs = GeneratedColumn<int>(
    'focus_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedEarlyMeta = const VerificationMeta(
    'endedEarly',
  );
  @override
  late final GeneratedColumn<bool> endedEarly = GeneratedColumn<bool>(
    'ended_early',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ended_early" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetLabelMeta = const VerificationMeta(
    'targetLabel',
  );
  @override
  late final GeneratedColumn<String> targetLabel = GeneratedColumn<String>(
    'target_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    focusMs,
    rounds,
    endedEarly,
    targetType,
    targetId,
    targetLabel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('focus_ms')) {
      context.handle(
        _focusMsMeta,
        focusMs.isAcceptableOrUnknown(data['focus_ms']!, _focusMsMeta),
      );
    } else if (isInserting) {
      context.missing(_focusMsMeta);
    }
    if (data.containsKey('rounds')) {
      context.handle(
        _roundsMeta,
        rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta),
      );
    } else if (isInserting) {
      context.missing(_roundsMeta);
    }
    if (data.containsKey('ended_early')) {
      context.handle(
        _endedEarlyMeta,
        endedEarly.isAcceptableOrUnknown(data['ended_early']!, _endedEarlyMeta),
      );
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    if (data.containsKey('target_label')) {
      context.handle(
        _targetLabelMeta,
        targetLabel.isAcceptableOrUnknown(
          data['target_label']!,
          _targetLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      focusMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}focus_ms'],
      )!,
      rounds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rounds'],
      )!,
      endedEarly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ended_early'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      ),
      targetLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_label'],
      ),
    );
  }

  @override
  $FocusLogRowsTable createAlias(String alias) {
    return $FocusLogRowsTable(attachedDatabase, alias);
  }
}

class FocusLogRow extends DataClass implements Insertable<FocusLogRow> {
  final int id;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Time actually spent in focus phases, without breaks or pauses.
  final int focusMs;

  /// Focus rounds finished in full.
  final int rounds;

  /// True when it was stopped before the last round ended.
  final bool endedEarly;

  /// Optional focus intention target (`task`, `event`, or `recall`).
  final String? targetType;

  /// Optional ID of the targeted task or event.
  final int? targetId;

  /// Optional human-readable label of the targeted item at session time.
  final String? targetLabel;
  const FocusLogRow({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.focusMs,
    required this.rounds,
    required this.endedEarly,
    this.targetType,
    this.targetId,
    this.targetLabel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['focus_ms'] = Variable<int>(focusMs);
    map['rounds'] = Variable<int>(rounds);
    map['ended_early'] = Variable<bool>(endedEarly);
    if (!nullToAbsent || targetType != null) {
      map['target_type'] = Variable<String>(targetType);
    }
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<int>(targetId);
    }
    if (!nullToAbsent || targetLabel != null) {
      map['target_label'] = Variable<String>(targetLabel);
    }
    return map;
  }

  FocusLogRowsCompanion toCompanion(bool nullToAbsent) {
    return FocusLogRowsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      focusMs: Value(focusMs),
      rounds: Value(rounds),
      endedEarly: Value(endedEarly),
      targetType: targetType == null && nullToAbsent
          ? const Value.absent()
          : Value(targetType),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
      targetLabel: targetLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(targetLabel),
    );
  }

  factory FocusLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusLogRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      focusMs: serializer.fromJson<int>(json['focusMs']),
      rounds: serializer.fromJson<int>(json['rounds']),
      endedEarly: serializer.fromJson<bool>(json['endedEarly']),
      targetType: serializer.fromJson<String?>(json['targetType']),
      targetId: serializer.fromJson<int?>(json['targetId']),
      targetLabel: serializer.fromJson<String?>(json['targetLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'focusMs': serializer.toJson<int>(focusMs),
      'rounds': serializer.toJson<int>(rounds),
      'endedEarly': serializer.toJson<bool>(endedEarly),
      'targetType': serializer.toJson<String?>(targetType),
      'targetId': serializer.toJson<int?>(targetId),
      'targetLabel': serializer.toJson<String?>(targetLabel),
    };
  }

  FocusLogRow copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? focusMs,
    int? rounds,
    bool? endedEarly,
    Value<String?> targetType = const Value.absent(),
    Value<int?> targetId = const Value.absent(),
    Value<String?> targetLabel = const Value.absent(),
  }) => FocusLogRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    focusMs: focusMs ?? this.focusMs,
    rounds: rounds ?? this.rounds,
    endedEarly: endedEarly ?? this.endedEarly,
    targetType: targetType.present ? targetType.value : this.targetType,
    targetId: targetId.present ? targetId.value : this.targetId,
    targetLabel: targetLabel.present ? targetLabel.value : this.targetLabel,
  );
  FocusLogRow copyWithCompanion(FocusLogRowsCompanion data) {
    return FocusLogRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      focusMs: data.focusMs.present ? data.focusMs.value : this.focusMs,
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
      endedEarly: data.endedEarly.present
          ? data.endedEarly.value
          : this.endedEarly,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      targetLabel: data.targetLabel.present
          ? data.targetLabel.value
          : this.targetLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusLogRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('focusMs: $focusMs, ')
          ..write('rounds: $rounds, ')
          ..write('endedEarly: $endedEarly, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('targetLabel: $targetLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    focusMs,
    rounds,
    endedEarly,
    targetType,
    targetId,
    targetLabel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusLogRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.focusMs == this.focusMs &&
          other.rounds == this.rounds &&
          other.endedEarly == this.endedEarly &&
          other.targetType == this.targetType &&
          other.targetId == this.targetId &&
          other.targetLabel == this.targetLabel);
}

class FocusLogRowsCompanion extends UpdateCompanion<FocusLogRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> focusMs;
  final Value<int> rounds;
  final Value<bool> endedEarly;
  final Value<String?> targetType;
  final Value<int?> targetId;
  final Value<String?> targetLabel;
  const FocusLogRowsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.focusMs = const Value.absent(),
    this.rounds = const Value.absent(),
    this.endedEarly = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.targetLabel = const Value.absent(),
  });
  FocusLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int focusMs,
    required int rounds,
    this.endedEarly = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetId = const Value.absent(),
    this.targetLabel = const Value.absent(),
  }) : startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       focusMs = Value(focusMs),
       rounds = Value(rounds);
  static Insertable<FocusLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? focusMs,
    Expression<int>? rounds,
    Expression<bool>? endedEarly,
    Expression<String>? targetType,
    Expression<int>? targetId,
    Expression<String>? targetLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (focusMs != null) 'focus_ms': focusMs,
      if (rounds != null) 'rounds': rounds,
      if (endedEarly != null) 'ended_early': endedEarly,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
      if (targetLabel != null) 'target_label': targetLabel,
    });
  }

  FocusLogRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? focusMs,
    Value<int>? rounds,
    Value<bool>? endedEarly,
    Value<String?>? targetType,
    Value<int?>? targetId,
    Value<String?>? targetLabel,
  }) {
    return FocusLogRowsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      focusMs: focusMs ?? this.focusMs,
      rounds: rounds ?? this.rounds,
      endedEarly: endedEarly ?? this.endedEarly,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetLabel: targetLabel ?? this.targetLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (focusMs.present) {
      map['focus_ms'] = Variable<int>(focusMs.value);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
    }
    if (endedEarly.present) {
      map['ended_early'] = Variable<bool>(endedEarly.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (targetLabel.present) {
      map['target_label'] = Variable<String>(targetLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('focusMs: $focusMs, ')
          ..write('rounds: $rounds, ')
          ..write('endedEarly: $endedEarly, ')
          ..write('targetType: $targetType, ')
          ..write('targetId: $targetId, ')
          ..write('targetLabel: $targetLabel')
          ..write(')'))
        .toString();
  }
}

class $BillRowsTable extends BillRows with TableInfo<$BillRowsTable, BillRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cadenceMeta = const VerificationMeta(
    'cadence',
  );
  @override
  late final GeneratedColumn<String> cadence = GeneratedColumn<String>(
    'cadence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDueOnMeta = const VerificationMeta(
    'nextDueOn',
  );
  @override
  late final GeneratedColumn<String> nextDueOn = GeneratedColumn<String>(
    'next_due_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoLogMeta = const VerificationMeta(
    'autoLog',
  );
  @override
  late final GeneratedColumn<bool> autoLog = GeneratedColumn<bool>(
    'auto_log',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_log" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    amountCents,
    category,
    cadence,
    nextDueOn,
    active,
    autoLog,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('cadence')) {
      context.handle(
        _cadenceMeta,
        cadence.isAcceptableOrUnknown(data['cadence']!, _cadenceMeta),
      );
    } else if (isInserting) {
      context.missing(_cadenceMeta);
    }
    if (data.containsKey('next_due_on')) {
      context.handle(
        _nextDueOnMeta,
        nextDueOn.isAcceptableOrUnknown(data['next_due_on']!, _nextDueOnMeta),
      );
    } else if (isInserting) {
      context.missing(_nextDueOnMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('auto_log')) {
      context.handle(
        _autoLogMeta,
        autoLog.isAcceptableOrUnknown(data['auto_log']!, _autoLogMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BillRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      cadence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cadence'],
      )!,
      nextDueOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_due_on'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      autoLog: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_log'],
      )!,
    );
  }

  @override
  $BillRowsTable createAlias(String alias) {
    return $BillRowsTable(attachedDatabase, alias);
  }
}

class BillRow extends DataClass implements Insertable<BillRow> {
  final int id;
  final String title;

  /// Centavos, so amounts never accumulate floating-point error.
  final int amountCents;
  final String category;

  /// `weekly:N`, `semimonthly`, or `monthly:N` (PaydaySchedule semantics).
  final String cadence;

  /// Next due date as `YYYY-MM-DD`.
  final String nextDueOn;
  final bool active;
  final bool autoLog;
  const BillRow({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.cadence,
    required this.nextDueOn,
    required this.active,
    required this.autoLog,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['amount_cents'] = Variable<int>(amountCents);
    map['category'] = Variable<String>(category);
    map['cadence'] = Variable<String>(cadence);
    map['next_due_on'] = Variable<String>(nextDueOn);
    map['active'] = Variable<bool>(active);
    map['auto_log'] = Variable<bool>(autoLog);
    return map;
  }

  BillRowsCompanion toCompanion(bool nullToAbsent) {
    return BillRowsCompanion(
      id: Value(id),
      title: Value(title),
      amountCents: Value(amountCents),
      category: Value(category),
      cadence: Value(cadence),
      nextDueOn: Value(nextDueOn),
      active: Value(active),
      autoLog: Value(autoLog),
    );
  }

  factory BillRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      category: serializer.fromJson<String>(json['category']),
      cadence: serializer.fromJson<String>(json['cadence']),
      nextDueOn: serializer.fromJson<String>(json['nextDueOn']),
      active: serializer.fromJson<bool>(json['active']),
      autoLog: serializer.fromJson<bool>(json['autoLog']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'amountCents': serializer.toJson<int>(amountCents),
      'category': serializer.toJson<String>(category),
      'cadence': serializer.toJson<String>(cadence),
      'nextDueOn': serializer.toJson<String>(nextDueOn),
      'active': serializer.toJson<bool>(active),
      'autoLog': serializer.toJson<bool>(autoLog),
    };
  }

  BillRow copyWith({
    int? id,
    String? title,
    int? amountCents,
    String? category,
    String? cadence,
    String? nextDueOn,
    bool? active,
    bool? autoLog,
  }) => BillRow(
    id: id ?? this.id,
    title: title ?? this.title,
    amountCents: amountCents ?? this.amountCents,
    category: category ?? this.category,
    cadence: cadence ?? this.cadence,
    nextDueOn: nextDueOn ?? this.nextDueOn,
    active: active ?? this.active,
    autoLog: autoLog ?? this.autoLog,
  );
  BillRow copyWithCompanion(BillRowsCompanion data) {
    return BillRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      category: data.category.present ? data.category.value : this.category,
      cadence: data.cadence.present ? data.cadence.value : this.cadence,
      nextDueOn: data.nextDueOn.present ? data.nextDueOn.value : this.nextDueOn,
      active: data.active.present ? data.active.value : this.active,
      autoLog: data.autoLog.present ? data.autoLog.value : this.autoLog,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('cadence: $cadence, ')
          ..write('nextDueOn: $nextDueOn, ')
          ..write('active: $active, ')
          ..write('autoLog: $autoLog')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amountCents,
    category,
    cadence,
    nextDueOn,
    active,
    autoLog,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.amountCents == this.amountCents &&
          other.category == this.category &&
          other.cadence == this.cadence &&
          other.nextDueOn == this.nextDueOn &&
          other.active == this.active &&
          other.autoLog == this.autoLog);
}

class BillRowsCompanion extends UpdateCompanion<BillRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> amountCents;
  final Value<String> category;
  final Value<String> cadence;
  final Value<String> nextDueOn;
  final Value<bool> active;
  final Value<bool> autoLog;
  const BillRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.category = const Value.absent(),
    this.cadence = const Value.absent(),
    this.nextDueOn = const Value.absent(),
    this.active = const Value.absent(),
    this.autoLog = const Value.absent(),
  });
  BillRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int amountCents,
    required String category,
    required String cadence,
    required String nextDueOn,
    this.active = const Value.absent(),
    this.autoLog = const Value.absent(),
  }) : title = Value(title),
       amountCents = Value(amountCents),
       category = Value(category),
       cadence = Value(cadence),
       nextDueOn = Value(nextDueOn);
  static Insertable<BillRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? amountCents,
    Expression<String>? category,
    Expression<String>? cadence,
    Expression<String>? nextDueOn,
    Expression<bool>? active,
    Expression<bool>? autoLog,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (amountCents != null) 'amount_cents': amountCents,
      if (category != null) 'category': category,
      if (cadence != null) 'cadence': cadence,
      if (nextDueOn != null) 'next_due_on': nextDueOn,
      if (active != null) 'active': active,
      if (autoLog != null) 'auto_log': autoLog,
    });
  }

  BillRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? amountCents,
    Value<String>? category,
    Value<String>? cadence,
    Value<String>? nextDueOn,
    Value<bool>? active,
    Value<bool>? autoLog,
  }) {
    return BillRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      cadence: cadence ?? this.cadence,
      nextDueOn: nextDueOn ?? this.nextDueOn,
      active: active ?? this.active,
      autoLog: autoLog ?? this.autoLog,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (cadence.present) {
      map['cadence'] = Variable<String>(cadence.value);
    }
    if (nextDueOn.present) {
      map['next_due_on'] = Variable<String>(nextDueOn.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (autoLog.present) {
      map['auto_log'] = Variable<bool>(autoLog.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('cadence: $cadence, ')
          ..write('nextDueOn: $nextDueOn, ')
          ..write('active: $active, ')
          ..write('autoLog: $autoLog')
          ..write(')'))
        .toString();
  }
}

class $TaskRowsTable extends TaskRows with TableInfo<$TaskRowsTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueOnMeta = const VerificationMeta('dueOn');
  @override
  late final GeneratedColumn<String> dueOn = GeneratedColumn<String>(
    'due_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatMeta = const VerificationMeta('repeat');
  @override
  late final GeneratedColumn<String> repeat = GeneratedColumn<String>(
    'repeat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    dueOn,
    repeat,
    done,
    doneAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due_on')) {
      context.handle(
        _dueOnMeta,
        dueOn.isAcceptableOrUnknown(data['due_on']!, _dueOnMeta),
      );
    }
    if (data.containsKey('repeat')) {
      context.handle(
        _repeatMeta,
        repeat.isAcceptableOrUnknown(data['repeat']!, _repeatMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dueOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_on'],
      ),
      repeat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TaskRowsTable createAlias(String alias) {
    return $TaskRowsTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;
  final String title;
  final String? notes;

  /// `YYYY-MM-DD`, or null for unscheduled ("anytime") tasks.
  final String? dueOn;

  /// `none`, `daily`, `weekly` or `monthly`.
  final String repeat;
  final bool done;
  final DateTime? doneAt;
  final DateTime createdAt;
  const TaskRow({
    required this.id,
    required this.title,
    this.notes,
    this.dueOn,
    required this.repeat,
    required this.done,
    this.doneAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || dueOn != null) {
      map['due_on'] = Variable<String>(dueOn);
    }
    map['repeat'] = Variable<String>(repeat);
    map['done'] = Variable<bool>(done);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TaskRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRowsCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dueOn: dueOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dueOn),
      repeat: Value(repeat),
      done: Value(done),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      createdAt: Value(createdAt),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      dueOn: serializer.fromJson<String?>(json['dueOn']),
      repeat: serializer.fromJson<String>(json['repeat']),
      done: serializer.fromJson<bool>(json['done']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'dueOn': serializer.toJson<String?>(dueOn),
      'repeat': serializer.toJson<String>(repeat),
      'done': serializer.toJson<bool>(done),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TaskRow copyWith({
    int? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<String?> dueOn = const Value.absent(),
    String? repeat,
    bool? done,
    Value<DateTime?> doneAt = const Value.absent(),
    DateTime? createdAt,
  }) => TaskRow(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    dueOn: dueOn.present ? dueOn.value : this.dueOn,
    repeat: repeat ?? this.repeat,
    done: done ?? this.done,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    createdAt: createdAt ?? this.createdAt,
  );
  TaskRow copyWithCompanion(TaskRowsCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      done: data.done.present ? data.done.value : this.done,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('dueOn: $dueOn, ')
          ..write('repeat: $repeat, ')
          ..write('done: $done, ')
          ..write('doneAt: $doneAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, notes, dueOn, repeat, done, doneAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.dueOn == this.dueOn &&
          other.repeat == this.repeat &&
          other.done == this.done &&
          other.doneAt == this.doneAt &&
          other.createdAt == this.createdAt);
}

class TaskRowsCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String?> dueOn;
  final Value<String> repeat;
  final Value<bool> done;
  final Value<DateTime?> doneAt;
  final Value<DateTime> createdAt;
  const TaskRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.repeat = const Value.absent(),
    this.done = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TaskRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.repeat = const Value.absent(),
    this.done = const Value.absent(),
    this.doneAt = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? dueOn,
    Expression<String>? repeat,
    Expression<bool>? done,
    Expression<DateTime>? doneAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (dueOn != null) 'due_on': dueOn,
      if (repeat != null) 'repeat': repeat,
      if (done != null) 'done': done,
      if (doneAt != null) 'done_at': doneAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TaskRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<String?>? dueOn,
    Value<String>? repeat,
    Value<bool>? done,
    Value<DateTime?>? doneAt,
    Value<DateTime>? createdAt,
  }) {
    return TaskRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueOn: dueOn ?? this.dueOn,
      repeat: repeat ?? this.repeat,
      done: done ?? this.done,
      doneAt: doneAt ?? this.doneAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<String>(dueOn.value);
    }
    if (repeat.present) {
      map['repeat'] = Variable<String>(repeat.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('dueOn: $dueOn, ')
          ..write('repeat: $repeat, ')
          ..write('done: $done, ')
          ..write('doneAt: $doneAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GoalRowsTable extends GoalRows with TableInfo<$GoalRowsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCentsMeta = const VerificationMeta(
    'targetCents',
  );
  @override
  late final GeneratedColumn<int> targetCents = GeneratedColumn<int>(
    'target_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedCentsMeta = const VerificationMeta(
    'savedCents',
  );
  @override
  late final GeneratedColumn<int> savedCents = GeneratedColumn<int>(
    'saved_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    targetCents,
    savedCents,
    targetDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('target_cents')) {
      context.handle(
        _targetCentsMeta,
        targetCents.isAcceptableOrUnknown(
          data['target_cents']!,
          _targetCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCentsMeta);
    }
    if (data.containsKey('saved_cents')) {
      context.handle(
        _savedCentsMeta,
        savedCents.isAcceptableOrUnknown(data['saved_cents']!, _savedCentsMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_cents'],
      )!,
      savedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_cents'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GoalRowsTable createAlias(String alias) {
    return $GoalRowsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final int id;
  final String title;

  /// Target amount in centavos.
  final int targetCents;

  /// Stashed amount in centavos.
  final int savedCents;

  /// Optional target date as `YYYY-MM-DD`.
  final String? targetDate;
  final DateTime createdAt;
  const GoalRow({
    required this.id,
    required this.title,
    required this.targetCents,
    required this.savedCents,
    this.targetDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['target_cents'] = Variable<int>(targetCents);
    map['saved_cents'] = Variable<int>(savedCents);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GoalRowsCompanion toCompanion(bool nullToAbsent) {
    return GoalRowsCompanion(
      id: Value(id),
      title: Value(title),
      targetCents: Value(targetCents),
      savedCents: Value(savedCents),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdAt: Value(createdAt),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      targetCents: serializer.fromJson<int>(json['targetCents']),
      savedCents: serializer.fromJson<int>(json['savedCents']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'targetCents': serializer.toJson<int>(targetCents),
      'savedCents': serializer.toJson<int>(savedCents),
      'targetDate': serializer.toJson<String?>(targetDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GoalRow copyWith({
    int? id,
    String? title,
    int? targetCents,
    int? savedCents,
    Value<String?> targetDate = const Value.absent(),
    DateTime? createdAt,
  }) => GoalRow(
    id: id ?? this.id,
    title: title ?? this.title,
    targetCents: targetCents ?? this.targetCents,
    savedCents: savedCents ?? this.savedCents,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    createdAt: createdAt ?? this.createdAt,
  );
  GoalRow copyWithCompanion(GoalRowsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      targetCents: data.targetCents.present
          ? data.targetCents.value
          : this.targetCents,
      savedCents: data.savedCents.present
          ? data.savedCents.value
          : this.savedCents,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, targetCents, savedCents, targetDate, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.targetCents == this.targetCents &&
          other.savedCents == this.savedCents &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt);
}

class GoalRowsCompanion extends UpdateCompanion<GoalRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> targetCents;
  final Value<int> savedCents;
  final Value<String?> targetDate;
  final Value<DateTime> createdAt;
  const GoalRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.targetCents = const Value.absent(),
    this.savedCents = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GoalRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int targetCents,
    this.savedCents = const Value.absent(),
    this.targetDate = const Value.absent(),
    required DateTime createdAt,
  }) : title = Value(title),
       targetCents = Value(targetCents),
       createdAt = Value(createdAt);
  static Insertable<GoalRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? targetCents,
    Expression<int>? savedCents,
    Expression<String>? targetDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (targetCents != null) 'target_cents': targetCents,
      if (savedCents != null) 'saved_cents': savedCents,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GoalRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? targetCents,
    Value<int>? savedCents,
    Value<String?>? targetDate,
    Value<DateTime>? createdAt,
  }) {
    return GoalRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      targetCents: targetCents ?? this.targetCents,
      savedCents: savedCents ?? this.savedCents,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetCents.present) {
      map['target_cents'] = Variable<int>(targetCents.value);
    }
    if (savedCents.present) {
      map['saved_cents'] = Variable<int>(savedCents.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $IouRowsTable extends IouRows with TableInfo<$IouRowsTable, IouRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IouRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredOnMeta = const VerificationMeta(
    'occurredOn',
  );
  @override
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledMeta = const VerificationMeta(
    'settled',
  );
  @override
  late final GeneratedColumn<bool> settled = GeneratedColumn<bool>(
    'settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<DateTime> settledAt = GeneratedColumn<DateTime>(
    'settled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    person,
    direction,
    amountCents,
    note,
    occurredOn,
    settled,
    settledAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ious';
  @override
  VerificationContext validateIntegrity(
    Insertable<IouRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _occurredOnMeta,
        occurredOn.isAcceptableOrUnknown(data['occurred_on']!, _occurredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('settled')) {
      context.handle(
        _settledMeta,
        settled.isAcceptableOrUnknown(data['settled']!, _settledMeta),
      );
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IouRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IouRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_on'],
      )!,
      settled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}settled'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}settled_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IouRowsTable createAlias(String alias) {
    return $IouRowsTable(attachedDatabase, alias);
  }
}

class IouRow extends DataClass implements Insertable<IouRow> {
  final int id;
  final String person;

  /// `'owed'` (owed to me) or `'owing'` (I owe).
  final String direction;

  /// Centavos, so amounts never accumulate floating-point error.
  final int amountCents;
  final String? note;

  /// `YYYY-MM-DD`.
  final String occurredOn;
  final bool settled;
  final DateTime? settledAt;
  final DateTime createdAt;
  const IouRow({
    required this.id,
    required this.person,
    required this.direction,
    required this.amountCents,
    this.note,
    required this.occurredOn,
    required this.settled,
    this.settledAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person'] = Variable<String>(person);
    map['direction'] = Variable<String>(direction);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['occurred_on'] = Variable<String>(occurredOn);
    map['settled'] = Variable<bool>(settled);
    if (!nullToAbsent || settledAt != null) {
      map['settled_at'] = Variable<DateTime>(settledAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IouRowsCompanion toCompanion(bool nullToAbsent) {
    return IouRowsCompanion(
      id: Value(id),
      person: Value(person),
      direction: Value(direction),
      amountCents: Value(amountCents),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      occurredOn: Value(occurredOn),
      settled: Value(settled),
      settledAt: settledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAt),
      createdAt: Value(createdAt),
    );
  }

  factory IouRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IouRow(
      id: serializer.fromJson<int>(json['id']),
      person: serializer.fromJson<String>(json['person']),
      direction: serializer.fromJson<String>(json['direction']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      note: serializer.fromJson<String?>(json['note']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      settled: serializer.fromJson<bool>(json['settled']),
      settledAt: serializer.fromJson<DateTime?>(json['settledAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'person': serializer.toJson<String>(person),
      'direction': serializer.toJson<String>(direction),
      'amountCents': serializer.toJson<int>(amountCents),
      'note': serializer.toJson<String?>(note),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'settled': serializer.toJson<bool>(settled),
      'settledAt': serializer.toJson<DateTime?>(settledAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IouRow copyWith({
    int? id,
    String? person,
    String? direction,
    int? amountCents,
    Value<String?> note = const Value.absent(),
    String? occurredOn,
    bool? settled,
    Value<DateTime?> settledAt = const Value.absent(),
    DateTime? createdAt,
  }) => IouRow(
    id: id ?? this.id,
    person: person ?? this.person,
    direction: direction ?? this.direction,
    amountCents: amountCents ?? this.amountCents,
    note: note.present ? note.value : this.note,
    occurredOn: occurredOn ?? this.occurredOn,
    settled: settled ?? this.settled,
    settledAt: settledAt.present ? settledAt.value : this.settledAt,
    createdAt: createdAt ?? this.createdAt,
  );
  IouRow copyWithCompanion(IouRowsCompanion data) {
    return IouRow(
      id: data.id.present ? data.id.value : this.id,
      person: data.person.present ? data.person.value : this.person,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      note: data.note.present ? data.note.value : this.note,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      settled: data.settled.present ? data.settled.value : this.settled,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IouRow(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('settled: $settled, ')
          ..write('settledAt: $settledAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    person,
    direction,
    amountCents,
    note,
    occurredOn,
    settled,
    settledAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IouRow &&
          other.id == this.id &&
          other.person == this.person &&
          other.direction == this.direction &&
          other.amountCents == this.amountCents &&
          other.note == this.note &&
          other.occurredOn == this.occurredOn &&
          other.settled == this.settled &&
          other.settledAt == this.settledAt &&
          other.createdAt == this.createdAt);
}

class IouRowsCompanion extends UpdateCompanion<IouRow> {
  final Value<int> id;
  final Value<String> person;
  final Value<String> direction;
  final Value<int> amountCents;
  final Value<String?> note;
  final Value<String> occurredOn;
  final Value<bool> settled;
  final Value<DateTime?> settledAt;
  final Value<DateTime> createdAt;
  const IouRowsCompanion({
    this.id = const Value.absent(),
    this.person = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.note = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.settled = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IouRowsCompanion.insert({
    this.id = const Value.absent(),
    required String person,
    required String direction,
    required int amountCents,
    this.note = const Value.absent(),
    required String occurredOn,
    this.settled = const Value.absent(),
    this.settledAt = const Value.absent(),
    required DateTime createdAt,
  }) : person = Value(person),
       direction = Value(direction),
       amountCents = Value(amountCents),
       occurredOn = Value(occurredOn),
       createdAt = Value(createdAt);
  static Insertable<IouRow> custom({
    Expression<int>? id,
    Expression<String>? person,
    Expression<String>? direction,
    Expression<int>? amountCents,
    Expression<String>? note,
    Expression<String>? occurredOn,
    Expression<bool>? settled,
    Expression<DateTime>? settledAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (person != null) 'person': person,
      if (direction != null) 'direction': direction,
      if (amountCents != null) 'amount_cents': amountCents,
      if (note != null) 'note': note,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (settled != null) 'settled': settled,
      if (settledAt != null) 'settled_at': settledAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IouRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? person,
    Value<String>? direction,
    Value<int>? amountCents,
    Value<String?>? note,
    Value<String>? occurredOn,
    Value<bool>? settled,
    Value<DateTime?>? settledAt,
    Value<DateTime>? createdAt,
  }) {
    return IouRowsCompanion(
      id: id ?? this.id,
      person: person ?? this.person,
      direction: direction ?? this.direction,
      amountCents: amountCents ?? this.amountCents,
      note: note ?? this.note,
      occurredOn: occurredOn ?? this.occurredOn,
      settled: settled ?? this.settled,
      settledAt: settledAt ?? this.settledAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (settled.present) {
      map['settled'] = Variable<bool>(settled.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<DateTime>(settledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IouRowsCompanion(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountCents: $amountCents, ')
          ..write('note: $note, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('settled: $settled, ')
          ..write('settledAt: $settledAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecallReviewRowsTable extends RecallReviewRows
    with TableInfo<$RecallReviewRowsTable, RecallReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecallReviewRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardKeyMeta = const VerificationMeta(
    'cardKey',
  );
  @override
  late final GeneratedColumn<String> cardKey = GeneratedColumn<String>(
    'card_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _nextReviewOnMeta = const VerificationMeta(
    'nextReviewOn',
  );
  @override
  late final GeneratedColumn<String> nextReviewOn = GeneratedColumn<String>(
    'next_review_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _timesReviewedMeta = const VerificationMeta(
    'timesReviewed',
  );
  @override
  late final GeneratedColumn<int> timesReviewed = GeneratedColumn<int>(
    'times_reviewed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    noteId,
    cardKey,
    box,
    nextReviewOn,
    lastReviewedAt,
    timesReviewed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recall_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecallReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('card_key')) {
      context.handle(
        _cardKeyMeta,
        cardKey.isAcceptableOrUnknown(data['card_key']!, _cardKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cardKeyMeta);
    }
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    }
    if (data.containsKey('next_review_on')) {
      context.handle(
        _nextReviewOnMeta,
        nextReviewOn.isAcceptableOrUnknown(
          data['next_review_on']!,
          _nextReviewOnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextReviewOnMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('times_reviewed')) {
      context.handle(
        _timesReviewedMeta,
        timesReviewed.isAcceptableOrUnknown(
          data['times_reviewed']!,
          _timesReviewedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, cardKey};
  @override
  RecallReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecallReviewRow(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      cardKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_key'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      nextReviewOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_review_on'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      timesReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_reviewed'],
      )!,
    );
  }

  @override
  $RecallReviewRowsTable createAlias(String alias) {
    return $RecallReviewRowsTable(attachedDatabase, alias);
  }
}

class RecallReviewRow extends DataClass implements Insertable<RecallReviewRow> {
  final int noteId;
  final String cardKey;

  /// Leitner box `1..5` (intervals 1, 2, 4, 7, 14 days).
  final int box;

  /// Next scheduled review date as `YYYY-MM-DD`.
  final String nextReviewOn;
  final DateTime? lastReviewedAt;
  final int timesReviewed;
  const RecallReviewRow({
    required this.noteId,
    required this.cardKey,
    required this.box,
    required this.nextReviewOn,
    this.lastReviewedAt,
    required this.timesReviewed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<int>(noteId);
    map['card_key'] = Variable<String>(cardKey);
    map['box'] = Variable<int>(box);
    map['next_review_on'] = Variable<String>(nextReviewOn);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['times_reviewed'] = Variable<int>(timesReviewed);
    return map;
  }

  RecallReviewRowsCompanion toCompanion(bool nullToAbsent) {
    return RecallReviewRowsCompanion(
      noteId: Value(noteId),
      cardKey: Value(cardKey),
      box: Value(box),
      nextReviewOn: Value(nextReviewOn),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      timesReviewed: Value(timesReviewed),
    );
  }

  factory RecallReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecallReviewRow(
      noteId: serializer.fromJson<int>(json['noteId']),
      cardKey: serializer.fromJson<String>(json['cardKey']),
      box: serializer.fromJson<int>(json['box']),
      nextReviewOn: serializer.fromJson<String>(json['nextReviewOn']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      timesReviewed: serializer.fromJson<int>(json['timesReviewed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<int>(noteId),
      'cardKey': serializer.toJson<String>(cardKey),
      'box': serializer.toJson<int>(box),
      'nextReviewOn': serializer.toJson<String>(nextReviewOn),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'timesReviewed': serializer.toJson<int>(timesReviewed),
    };
  }

  RecallReviewRow copyWith({
    int? noteId,
    String? cardKey,
    int? box,
    String? nextReviewOn,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    int? timesReviewed,
  }) => RecallReviewRow(
    noteId: noteId ?? this.noteId,
    cardKey: cardKey ?? this.cardKey,
    box: box ?? this.box,
    nextReviewOn: nextReviewOn ?? this.nextReviewOn,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    timesReviewed: timesReviewed ?? this.timesReviewed,
  );
  RecallReviewRow copyWithCompanion(RecallReviewRowsCompanion data) {
    return RecallReviewRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      cardKey: data.cardKey.present ? data.cardKey.value : this.cardKey,
      box: data.box.present ? data.box.value : this.box,
      nextReviewOn: data.nextReviewOn.present
          ? data.nextReviewOn.value
          : this.nextReviewOn,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      timesReviewed: data.timesReviewed.present
          ? data.timesReviewed.value
          : this.timesReviewed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecallReviewRow(')
          ..write('noteId: $noteId, ')
          ..write('cardKey: $cardKey, ')
          ..write('box: $box, ')
          ..write('nextReviewOn: $nextReviewOn, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('timesReviewed: $timesReviewed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    noteId,
    cardKey,
    box,
    nextReviewOn,
    lastReviewedAt,
    timesReviewed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecallReviewRow &&
          other.noteId == this.noteId &&
          other.cardKey == this.cardKey &&
          other.box == this.box &&
          other.nextReviewOn == this.nextReviewOn &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.timesReviewed == this.timesReviewed);
}

class RecallReviewRowsCompanion extends UpdateCompanion<RecallReviewRow> {
  final Value<int> noteId;
  final Value<String> cardKey;
  final Value<int> box;
  final Value<String> nextReviewOn;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> timesReviewed;
  final Value<int> rowid;
  const RecallReviewRowsCompanion({
    this.noteId = const Value.absent(),
    this.cardKey = const Value.absent(),
    this.box = const Value.absent(),
    this.nextReviewOn = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.timesReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecallReviewRowsCompanion.insert({
    required int noteId,
    required String cardKey,
    this.box = const Value.absent(),
    required String nextReviewOn,
    this.lastReviewedAt = const Value.absent(),
    this.timesReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       cardKey = Value(cardKey),
       nextReviewOn = Value(nextReviewOn);
  static Insertable<RecallReviewRow> custom({
    Expression<int>? noteId,
    Expression<String>? cardKey,
    Expression<int>? box,
    Expression<String>? nextReviewOn,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? timesReviewed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (cardKey != null) 'card_key': cardKey,
      if (box != null) 'box': box,
      if (nextReviewOn != null) 'next_review_on': nextReviewOn,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (timesReviewed != null) 'times_reviewed': timesReviewed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecallReviewRowsCompanion copyWith({
    Value<int>? noteId,
    Value<String>? cardKey,
    Value<int>? box,
    Value<String>? nextReviewOn,
    Value<DateTime?>? lastReviewedAt,
    Value<int>? timesReviewed,
    Value<int>? rowid,
  }) {
    return RecallReviewRowsCompanion(
      noteId: noteId ?? this.noteId,
      cardKey: cardKey ?? this.cardKey,
      box: box ?? this.box,
      nextReviewOn: nextReviewOn ?? this.nextReviewOn,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (cardKey.present) {
      map['card_key'] = Variable<String>(cardKey.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (nextReviewOn.present) {
      map['next_review_on'] = Variable<String>(nextReviewOn.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (timesReviewed.present) {
      map['times_reviewed'] = Variable<int>(timesReviewed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecallReviewRowsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('cardKey: $cardKey, ')
          ..write('box: $box, ')
          ..write('nextReviewOn: $nextReviewOn, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('timesReviewed: $timesReviewed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventRowsTable eventRows = $EventRowsTable(this);
  late final $TransactionRowsTable transactionRows = $TransactionRowsTable(
    this,
  );
  late final $NoteRowsTable noteRows = $NoteRowsTable(this);
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  late final $ShiftRowsTable shiftRows = $ShiftRowsTable(this);
  late final $PhoneDayRowsTable phoneDayRows = $PhoneDayRowsTable(this);
  late final $PhoneAppDayRowsTable phoneAppDayRows = $PhoneAppDayRowsTable(
    this,
  );
  late final $AlarmRowsTable alarmRows = $AlarmRowsTable(this);
  late final $FocusLogRowsTable focusLogRows = $FocusLogRowsTable(this);
  late final $BillRowsTable billRows = $BillRowsTable(this);
  late final $TaskRowsTable taskRows = $TaskRowsTable(this);
  late final $GoalRowsTable goalRows = $GoalRowsTable(this);
  late final $IouRowsTable iouRows = $IouRowsTable(this);
  late final $RecallReviewRowsTable recallReviewRows = $RecallReviewRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventRows,
    transactionRows,
    noteRows,
    settingRows,
    shiftRows,
    phoneDayRows,
    phoneAppDayRows,
    alarmRows,
    focusLogRows,
    billRows,
    taskRows,
    goalRows,
    iouRows,
    recallReviewRows,
  ];
}

typedef $$EventRowsTableCreateCompanionBuilder = EventRowsCompanion Function({
  Value<int> id,
  required String title,
  required DateTime startsAt,
  Value<int> durationMinutes,
  Value<String?> location,
  Value<String?> notes,
  Value<String> recurrence,
  Value<String?> recurrenceUntil,
  Value<int?> reminderMinutes,
  Value<int?> noteId,
  Value<bool> done,
});
typedef $$EventRowsTableUpdateCompanionBuilder = EventRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<DateTime> startsAt,
  Value<int> durationMinutes,
  Value<String?> location,
  Value<String?> notes,
  Value<String> recurrence,
  Value<String?> recurrenceUntil,
  Value<int?> reminderMinutes,
  Value<int?> noteId,
  Value<bool> done,
});

class $$EventRowsTableFilterComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventRowsTable> {
  $$EventRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceUntil => $composableBuilder(
    column: $table.recurrenceUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);
}

class $$EventRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventRowsTable,
          EventRow,
          $$EventRowsTableFilterComposer,
          $$EventRowsTableOrderingComposer,
          $$EventRowsTableAnnotationComposer,
          $$EventRowsTableCreateCompanionBuilder,
          $$EventRowsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventRowsTableTableManager(_$AppDatabase db, $EventRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> recurrenceUntil = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<int?> noteId = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => EventRowsCompanion(
                id: id,
                title: title,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                location: location,
                notes: notes,
                recurrence: recurrence,
                recurrenceUntil: recurrenceUntil,
                reminderMinutes: reminderMinutes,
                noteId: noteId,
                done: done,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required DateTime startsAt,
                Value<int> durationMinutes = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<String?> recurrenceUntil = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<int?> noteId = const Value.absent(),
                Value<bool> done = const Value.absent(),
              }) => EventRowsCompanion.insert(
                id: id,
                title: title,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                location: location,
                notes: notes,
                recurrence: recurrence,
                recurrenceUntil: recurrenceUntil,
                reminderMinutes: reminderMinutes,
                noteId: noteId,
                done: done,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventRowsTable, EventRow>(table),
                  BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventRowsTable,
      EventRow,
      $$EventRowsTableFilterComposer,
      $$EventRowsTableOrderingComposer,
      $$EventRowsTableAnnotationComposer,
      $$EventRowsTableCreateCompanionBuilder,
      $$EventRowsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventRowsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$TransactionRowsTableCreateCompanionBuilder =
    TransactionRowsCompanion Function({
      Value<int> id,
      required String type,
      required int amountCents,
      required String category,
      required String occurredOn,
      Value<String?> note,
    });
typedef $$TransactionRowsTableUpdateCompanionBuilder =
    TransactionRowsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int> amountCents,
      Value<String> category,
      Value<String> occurredOn,
      Value<String?> note,
    });

class $$TransactionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionRowsTable> {
  $$TransactionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionRowsTable> {
  $$TransactionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionRowsTable> {
  $$TransactionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TransactionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionRowsTable,
          TransactionRow,
          $$TransactionRowsTableFilterComposer,
          $$TransactionRowsTableOrderingComposer,
          $$TransactionRowsTableAnnotationComposer,
          $$TransactionRowsTableCreateCompanionBuilder,
          $$TransactionRowsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<
              _$AppDatabase,
              $TransactionRowsTable,
              TransactionRow
            >,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionRowsTableTableManager(
    _$AppDatabase db,
    $TransactionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> occurredOn = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TransactionRowsCompanion(
                id: id,
                type: type,
                amountCents: amountCents,
                category: category,
                occurredOn: occurredOn,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int amountCents,
                required String category,
                required String occurredOn,
                Value<String?> note = const Value.absent(),
              }) => TransactionRowsCompanion.insert(
                id: id,
                type: type,
                amountCents: amountCents,
                category: category,
                occurredOn: occurredOn,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionRowsTable, TransactionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionRowsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionRowsTable,
      TransactionRow,
      $$TransactionRowsTableFilterComposer,
      $$TransactionRowsTableOrderingComposer,
      $$TransactionRowsTableAnnotationComposer,
      $$TransactionRowsTableCreateCompanionBuilder,
      $$TransactionRowsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$AppDatabase, $TransactionRowsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$NoteRowsTableCreateCompanionBuilder = NoteRowsCompanion Function({
  Value<int> id,
  required String title,
  required String body,
  required String tags,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> pinned,
});
typedef $$NoteRowsTableUpdateCompanionBuilder = NoteRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> body,
  Value<String> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> pinned,
});

class $$NoteRowsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteRowsTable> {
  $$NoteRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteRowsTable> {
  $$NoteRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteRowsTable> {
  $$NoteRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);
}

class $$NoteRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteRowsTable,
          NoteRow,
          $$NoteRowsTableFilterComposer,
          $$NoteRowsTableOrderingComposer,
          $$NoteRowsTableAnnotationComposer,
          $$NoteRowsTableCreateCompanionBuilder,
          $$NoteRowsTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NoteRowsTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NoteRowsTableTableManager(_$AppDatabase db, $NoteRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
              }) => NoteRowsCompanion(
                id: id,
                title: title,
                body: body,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pinned: pinned,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String body,
                required String tags,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> pinned = const Value.absent(),
              }) => NoteRowsCompanion.insert(
                id: id,
                title: title,
                body: body,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
                pinned: pinned,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteRowsTable, NoteRow>(table),
                  BaseReferences<_$AppDatabase, $NoteRowsTable, NoteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteRowsTable,
      NoteRow,
      $$NoteRowsTableFilterComposer,
      $$NoteRowsTableOrderingComposer,
      $$NoteRowsTableAnnotationComposer,
      $$NoteRowsTableCreateCompanionBuilder,
      $$NoteRowsTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NoteRowsTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingRowsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$ShiftRowsTableCreateCompanionBuilder = ShiftRowsCompanion Function({
  Value<int> id,
  required String job,
  required DateTime startsAt,
  required int durationMinutes,
  Value<int> breakMinutes,
  Value<int> hourlyRateCents,
  Value<bool> paid,
  Value<int?> seriesId,
});
typedef $$ShiftRowsTableUpdateCompanionBuilder = ShiftRowsCompanion Function({
  Value<int> id,
  Value<String> job,
  Value<DateTime> startsAt,
  Value<int> durationMinutes,
  Value<int> breakMinutes,
  Value<int> hourlyRateCents,
  Value<bool> paid,
  Value<int?> seriesId,
});

class $$ShiftRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ShiftRowsTable> {
  $$ShiftRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get job => $composableBuilder(
    column: $table.job,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShiftRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShiftRowsTable> {
  $$ShiftRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get job => $composableBuilder(
    column: $table.job,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paid => $composableBuilder(
    column: $table.paid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShiftRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShiftRowsTable> {
  $$ShiftRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get job =>
      $composableBuilder(column: $table.job, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breakMinutes => $composableBuilder(
    column: $table.breakMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hourlyRateCents => $composableBuilder(
    column: $table.hourlyRateCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);
}

class $$ShiftRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShiftRowsTable,
          ShiftRow,
          $$ShiftRowsTableFilterComposer,
          $$ShiftRowsTableOrderingComposer,
          $$ShiftRowsTableAnnotationComposer,
          $$ShiftRowsTableCreateCompanionBuilder,
          $$ShiftRowsTableUpdateCompanionBuilder,
          (ShiftRow, BaseReferences<_$AppDatabase, $ShiftRowsTable, ShiftRow>),
          ShiftRow,
          PrefetchHooks Function()
        > {
  $$ShiftRowsTableTableManager(_$AppDatabase db, $ShiftRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShiftRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShiftRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShiftRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> job = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> breakMinutes = const Value.absent(),
                Value<int> hourlyRateCents = const Value.absent(),
                Value<bool> paid = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
              }) => ShiftRowsCompanion(
                id: id,
                job: job,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                breakMinutes: breakMinutes,
                hourlyRateCents: hourlyRateCents,
                paid: paid,
                seriesId: seriesId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String job,
                required DateTime startsAt,
                required int durationMinutes,
                Value<int> breakMinutes = const Value.absent(),
                Value<int> hourlyRateCents = const Value.absent(),
                Value<bool> paid = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
              }) => ShiftRowsCompanion.insert(
                id: id,
                job: job,
                startsAt: startsAt,
                durationMinutes: durationMinutes,
                breakMinutes: breakMinutes,
                hourlyRateCents: hourlyRateCents,
                paid: paid,
                seriesId: seriesId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShiftRowsTable, ShiftRow>(table),
                  BaseReferences<_$AppDatabase, $ShiftRowsTable, ShiftRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShiftRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShiftRowsTable,
      ShiftRow,
      $$ShiftRowsTableFilterComposer,
      $$ShiftRowsTableOrderingComposer,
      $$ShiftRowsTableAnnotationComposer,
      $$ShiftRowsTableCreateCompanionBuilder,
      $$ShiftRowsTableUpdateCompanionBuilder,
      (ShiftRow, BaseReferences<_$AppDatabase, $ShiftRowsTable, ShiftRow>),
      ShiftRow,
      PrefetchHooks Function()
    >;
typedef $$PhoneDayRowsTableCreateCompanionBuilder =
    PhoneDayRowsCompanion Function({
      required String date,
      required int screenOnMs,
      required int unlocks,
      Value<DateTime?> firstPickup,
      Value<DateTime?> restStart,
      Value<DateTime?> restEnd,
      Value<bool> complete,
      Value<int> rowid,
    });
typedef $$PhoneDayRowsTableUpdateCompanionBuilder =
    PhoneDayRowsCompanion Function({
      Value<String> date,
      Value<int> screenOnMs,
      Value<int> unlocks,
      Value<DateTime?> firstPickup,
      Value<DateTime?> restStart,
      Value<DateTime?> restEnd,
      Value<bool> complete,
      Value<int> rowid,
    });

class $$PhoneDayRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PhoneDayRowsTable> {
  $$PhoneDayRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get screenOnMs => $composableBuilder(
    column: $table.screenOnMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unlocks => $composableBuilder(
    column: $table.unlocks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstPickup => $composableBuilder(
    column: $table.firstPickup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get restStart => $composableBuilder(
    column: $table.restStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get restEnd => $composableBuilder(
    column: $table.restEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhoneDayRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhoneDayRowsTable> {
  $$PhoneDayRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get screenOnMs => $composableBuilder(
    column: $table.screenOnMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unlocks => $composableBuilder(
    column: $table.unlocks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstPickup => $composableBuilder(
    column: $table.firstPickup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get restStart => $composableBuilder(
    column: $table.restStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get restEnd => $composableBuilder(
    column: $table.restEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhoneDayRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhoneDayRowsTable> {
  $$PhoneDayRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get screenOnMs => $composableBuilder(
    column: $table.screenOnMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unlocks =>
      $composableBuilder(column: $table.unlocks, builder: (column) => column);

  GeneratedColumn<DateTime> get firstPickup => $composableBuilder(
    column: $table.firstPickup,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get restStart =>
      $composableBuilder(column: $table.restStart, builder: (column) => column);

  GeneratedColumn<DateTime> get restEnd =>
      $composableBuilder(column: $table.restEnd, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);
}

class $$PhoneDayRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhoneDayRowsTable,
          PhoneDayRow,
          $$PhoneDayRowsTableFilterComposer,
          $$PhoneDayRowsTableOrderingComposer,
          $$PhoneDayRowsTableAnnotationComposer,
          $$PhoneDayRowsTableCreateCompanionBuilder,
          $$PhoneDayRowsTableUpdateCompanionBuilder,
          (
            PhoneDayRow,
            BaseReferences<_$AppDatabase, $PhoneDayRowsTable, PhoneDayRow>,
          ),
          PhoneDayRow,
          PrefetchHooks Function()
        > {
  $$PhoneDayRowsTableTableManager(_$AppDatabase db, $PhoneDayRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhoneDayRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhoneDayRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhoneDayRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> screenOnMs = const Value.absent(),
                Value<int> unlocks = const Value.absent(),
                Value<DateTime?> firstPickup = const Value.absent(),
                Value<DateTime?> restStart = const Value.absent(),
                Value<DateTime?> restEnd = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhoneDayRowsCompanion(
                date: date,
                screenOnMs: screenOnMs,
                unlocks: unlocks,
                firstPickup: firstPickup,
                restStart: restStart,
                restEnd: restEnd,
                complete: complete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int screenOnMs,
                required int unlocks,
                Value<DateTime?> firstPickup = const Value.absent(),
                Value<DateTime?> restStart = const Value.absent(),
                Value<DateTime?> restEnd = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhoneDayRowsCompanion.insert(
                date: date,
                screenOnMs: screenOnMs,
                unlocks: unlocks,
                firstPickup: firstPickup,
                restStart: restStart,
                restEnd: restEnd,
                complete: complete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhoneDayRowsTable, PhoneDayRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PhoneDayRowsTable,
                    PhoneDayRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhoneDayRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhoneDayRowsTable,
      PhoneDayRow,
      $$PhoneDayRowsTableFilterComposer,
      $$PhoneDayRowsTableOrderingComposer,
      $$PhoneDayRowsTableAnnotationComposer,
      $$PhoneDayRowsTableCreateCompanionBuilder,
      $$PhoneDayRowsTableUpdateCompanionBuilder,
      (
        PhoneDayRow,
        BaseReferences<_$AppDatabase, $PhoneDayRowsTable, PhoneDayRow>,
      ),
      PhoneDayRow,
      PrefetchHooks Function()
    >;
typedef $$PhoneAppDayRowsTableCreateCompanionBuilder =
    PhoneAppDayRowsCompanion Function({
      required String date,
      required String package,
      required String label,
      required int foregroundMs,
      Value<int> rowid,
    });
typedef $$PhoneAppDayRowsTableUpdateCompanionBuilder =
    PhoneAppDayRowsCompanion Function({
      Value<String> date,
      Value<String> package,
      Value<String> label,
      Value<int> foregroundMs,
      Value<int> rowid,
    });

class $$PhoneAppDayRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PhoneAppDayRowsTable> {
  $$PhoneAppDayRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get package => $composableBuilder(
    column: $table.package,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhoneAppDayRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhoneAppDayRowsTable> {
  $$PhoneAppDayRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get package => $composableBuilder(
    column: $table.package,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhoneAppDayRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhoneAppDayRowsTable> {
  $$PhoneAppDayRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get package =>
      $composableBuilder(column: $table.package, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get foregroundMs => $composableBuilder(
    column: $table.foregroundMs,
    builder: (column) => column,
  );
}

class $$PhoneAppDayRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhoneAppDayRowsTable,
          PhoneAppDayRow,
          $$PhoneAppDayRowsTableFilterComposer,
          $$PhoneAppDayRowsTableOrderingComposer,
          $$PhoneAppDayRowsTableAnnotationComposer,
          $$PhoneAppDayRowsTableCreateCompanionBuilder,
          $$PhoneAppDayRowsTableUpdateCompanionBuilder,
          (
            PhoneAppDayRow,
            BaseReferences<
              _$AppDatabase,
              $PhoneAppDayRowsTable,
              PhoneAppDayRow
            >,
          ),
          PhoneAppDayRow,
          PrefetchHooks Function()
        > {
  $$PhoneAppDayRowsTableTableManager(
    _$AppDatabase db,
    $PhoneAppDayRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhoneAppDayRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhoneAppDayRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhoneAppDayRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> package = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> foregroundMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhoneAppDayRowsCompanion(
                date: date,
                package: package,
                label: label,
                foregroundMs: foregroundMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String package,
                required String label,
                required int foregroundMs,
                Value<int> rowid = const Value.absent(),
              }) => PhoneAppDayRowsCompanion.insert(
                date: date,
                package: package,
                label: label,
                foregroundMs: foregroundMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhoneAppDayRowsTable, PhoneAppDayRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PhoneAppDayRowsTable,
                    PhoneAppDayRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhoneAppDayRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhoneAppDayRowsTable,
      PhoneAppDayRow,
      $$PhoneAppDayRowsTableFilterComposer,
      $$PhoneAppDayRowsTableOrderingComposer,
      $$PhoneAppDayRowsTableAnnotationComposer,
      $$PhoneAppDayRowsTableCreateCompanionBuilder,
      $$PhoneAppDayRowsTableUpdateCompanionBuilder,
      (
        PhoneAppDayRow,
        BaseReferences<_$AppDatabase, $PhoneAppDayRowsTable, PhoneAppDayRow>,
      ),
      PhoneAppDayRow,
      PrefetchHooks Function()
    >;
typedef $$AlarmRowsTableCreateCompanionBuilder = AlarmRowsCompanion Function({
  Value<int> id,
  required int hour,
  required int minute,
  Value<int> days,
  Value<String> label,
  Value<bool> enabled,
  Value<String?> soundUri,
  Value<String?> soundName,
  Value<int> volume,
  Value<int> rampSeconds,
  Value<bool> volumeLock,
  Value<bool> vibrate,
  Value<String> challenge,
  Value<int> challengeCount,
  Value<String> difficulty,
  Value<String> phrase,
  Value<int> snoozeLimit,
  Value<int> snoozeMinutes,
  Value<bool> wakeCheck,
  Value<int> wakeCheckMinutes,
});
typedef $$AlarmRowsTableUpdateCompanionBuilder = AlarmRowsCompanion Function({
  Value<int> id,
  Value<int> hour,
  Value<int> minute,
  Value<int> days,
  Value<String> label,
  Value<bool> enabled,
  Value<String?> soundUri,
  Value<String?> soundName,
  Value<int> volume,
  Value<int> rampSeconds,
  Value<bool> volumeLock,
  Value<bool> vibrate,
  Value<String> challenge,
  Value<int> challengeCount,
  Value<String> difficulty,
  Value<String> phrase,
  Value<int> snoozeLimit,
  Value<int> snoozeMinutes,
  Value<bool> wakeCheck,
  Value<int> wakeCheckMinutes,
});

class $$AlarmRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmRowsTable> {
  $$AlarmRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundUri => $composableBuilder(
    column: $table.soundUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundName => $composableBuilder(
    column: $table.soundName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rampSeconds => $composableBuilder(
    column: $table.rampSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get volumeLock => $composableBuilder(
    column: $table.volumeLock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vibrate => $composableBuilder(
    column: $table.vibrate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get challenge => $composableBuilder(
    column: $table.challenge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get challengeCount => $composableBuilder(
    column: $table.challengeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeLimit => $composableBuilder(
    column: $table.snoozeLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wakeCheck => $composableBuilder(
    column: $table.wakeCheck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wakeCheckMinutes => $composableBuilder(
    column: $table.wakeCheckMinutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlarmRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmRowsTable> {
  $$AlarmRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundUri => $composableBuilder(
    column: $table.soundUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundName => $composableBuilder(
    column: $table.soundName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volume => $composableBuilder(
    column: $table.volume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rampSeconds => $composableBuilder(
    column: $table.rampSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get volumeLock => $composableBuilder(
    column: $table.volumeLock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vibrate => $composableBuilder(
    column: $table.vibrate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get challenge => $composableBuilder(
    column: $table.challenge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get challengeCount => $composableBuilder(
    column: $table.challengeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeLimit => $composableBuilder(
    column: $table.snoozeLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wakeCheck => $composableBuilder(
    column: $table.wakeCheck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wakeCheckMinutes => $composableBuilder(
    column: $table.wakeCheckMinutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlarmRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmRowsTable> {
  $$AlarmRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get soundUri =>
      $composableBuilder(column: $table.soundUri, builder: (column) => column);

  GeneratedColumn<String> get soundName =>
      $composableBuilder(column: $table.soundName, builder: (column) => column);

  GeneratedColumn<int> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<int> get rampSeconds => $composableBuilder(
    column: $table.rampSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get volumeLock => $composableBuilder(
    column: $table.volumeLock,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vibrate =>
      $composableBuilder(column: $table.vibrate, builder: (column) => column);

  GeneratedColumn<String> get challenge =>
      $composableBuilder(column: $table.challenge, builder: (column) => column);

  GeneratedColumn<int> get challengeCount => $composableBuilder(
    column: $table.challengeCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phrase =>
      $composableBuilder(column: $table.phrase, builder: (column) => column);

  GeneratedColumn<int> get snoozeLimit => $composableBuilder(
    column: $table.snoozeLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeMinutes => $composableBuilder(
    column: $table.snoozeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wakeCheck =>
      $composableBuilder(column: $table.wakeCheck, builder: (column) => column);

  GeneratedColumn<int> get wakeCheckMinutes => $composableBuilder(
    column: $table.wakeCheckMinutes,
    builder: (column) => column,
  );
}

class $$AlarmRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlarmRowsTable,
          AlarmRow,
          $$AlarmRowsTableFilterComposer,
          $$AlarmRowsTableOrderingComposer,
          $$AlarmRowsTableAnnotationComposer,
          $$AlarmRowsTableCreateCompanionBuilder,
          $$AlarmRowsTableUpdateCompanionBuilder,
          (AlarmRow, BaseReferences<_$AppDatabase, $AlarmRowsTable, AlarmRow>),
          AlarmRow,
          PrefetchHooks Function()
        > {
  $$AlarmRowsTableTableManager(_$AppDatabase db, $AlarmRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> soundUri = const Value.absent(),
                Value<String?> soundName = const Value.absent(),
                Value<int> volume = const Value.absent(),
                Value<int> rampSeconds = const Value.absent(),
                Value<bool> volumeLock = const Value.absent(),
                Value<bool> vibrate = const Value.absent(),
                Value<String> challenge = const Value.absent(),
                Value<int> challengeCount = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> phrase = const Value.absent(),
                Value<int> snoozeLimit = const Value.absent(),
                Value<int> snoozeMinutes = const Value.absent(),
                Value<bool> wakeCheck = const Value.absent(),
                Value<int> wakeCheckMinutes = const Value.absent(),
              }) => AlarmRowsCompanion(
                id: id,
                hour: hour,
                minute: minute,
                days: days,
                label: label,
                enabled: enabled,
                soundUri: soundUri,
                soundName: soundName,
                volume: volume,
                rampSeconds: rampSeconds,
                volumeLock: volumeLock,
                vibrate: vibrate,
                challenge: challenge,
                challengeCount: challengeCount,
                difficulty: difficulty,
                phrase: phrase,
                snoozeLimit: snoozeLimit,
                snoozeMinutes: snoozeMinutes,
                wakeCheck: wakeCheck,
                wakeCheckMinutes: wakeCheckMinutes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int hour,
                required int minute,
                Value<int> days = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> soundUri = const Value.absent(),
                Value<String?> soundName = const Value.absent(),
                Value<int> volume = const Value.absent(),
                Value<int> rampSeconds = const Value.absent(),
                Value<bool> volumeLock = const Value.absent(),
                Value<bool> vibrate = const Value.absent(),
                Value<String> challenge = const Value.absent(),
                Value<int> challengeCount = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> phrase = const Value.absent(),
                Value<int> snoozeLimit = const Value.absent(),
                Value<int> snoozeMinutes = const Value.absent(),
                Value<bool> wakeCheck = const Value.absent(),
                Value<int> wakeCheckMinutes = const Value.absent(),
              }) => AlarmRowsCompanion.insert(
                id: id,
                hour: hour,
                minute: minute,
                days: days,
                label: label,
                enabled: enabled,
                soundUri: soundUri,
                soundName: soundName,
                volume: volume,
                rampSeconds: rampSeconds,
                volumeLock: volumeLock,
                vibrate: vibrate,
                challenge: challenge,
                challengeCount: challengeCount,
                difficulty: difficulty,
                phrase: phrase,
                snoozeLimit: snoozeLimit,
                snoozeMinutes: snoozeMinutes,
                wakeCheck: wakeCheck,
                wakeCheckMinutes: wakeCheckMinutes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlarmRowsTable, AlarmRow>(table),
                  BaseReferences<_$AppDatabase, $AlarmRowsTable, AlarmRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlarmRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlarmRowsTable,
      AlarmRow,
      $$AlarmRowsTableFilterComposer,
      $$AlarmRowsTableOrderingComposer,
      $$AlarmRowsTableAnnotationComposer,
      $$AlarmRowsTableCreateCompanionBuilder,
      $$AlarmRowsTableUpdateCompanionBuilder,
      (AlarmRow, BaseReferences<_$AppDatabase, $AlarmRowsTable, AlarmRow>),
      AlarmRow,
      PrefetchHooks Function()
    >;
typedef $$FocusLogRowsTableCreateCompanionBuilder =
    FocusLogRowsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      required DateTime endedAt,
      required int focusMs,
      required int rounds,
      Value<bool> endedEarly,
      Value<String?> targetType,
      Value<int?> targetId,
      Value<String?> targetLabel,
    });
typedef $$FocusLogRowsTableUpdateCompanionBuilder =
    FocusLogRowsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> focusMs,
      Value<int> rounds,
      Value<bool> endedEarly,
      Value<String?> targetType,
      Value<int?> targetId,
      Value<String?> targetLabel,
    });

class $$FocusLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusLogRowsTable> {
  $$FocusLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get focusMs => $composableBuilder(
    column: $table.focusMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLabel => $composableBuilder(
    column: $table.targetLabel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusLogRowsTable> {
  $$FocusLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get focusMs => $composableBuilder(
    column: $table.focusMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rounds => $composableBuilder(
    column: $table.rounds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLabel => $composableBuilder(
    column: $table.targetLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusLogRowsTable> {
  $$FocusLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get focusMs =>
      $composableBuilder(column: $table.focusMs, builder: (column) => column);

  GeneratedColumn<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => column);

  GeneratedColumn<bool> get endedEarly => $composableBuilder(
    column: $table.endedEarly,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get targetLabel => $composableBuilder(
    column: $table.targetLabel,
    builder: (column) => column,
  );
}

class $$FocusLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusLogRowsTable,
          FocusLogRow,
          $$FocusLogRowsTableFilterComposer,
          $$FocusLogRowsTableOrderingComposer,
          $$FocusLogRowsTableAnnotationComposer,
          $$FocusLogRowsTableCreateCompanionBuilder,
          $$FocusLogRowsTableUpdateCompanionBuilder,
          (
            FocusLogRow,
            BaseReferences<_$AppDatabase, $FocusLogRowsTable, FocusLogRow>,
          ),
          FocusLogRow,
          PrefetchHooks Function()
        > {
  $$FocusLogRowsTableTableManager(_$AppDatabase db, $FocusLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> focusMs = const Value.absent(),
                Value<int> rounds = const Value.absent(),
                Value<bool> endedEarly = const Value.absent(),
                Value<String?> targetType = const Value.absent(),
                Value<int?> targetId = const Value.absent(),
                Value<String?> targetLabel = const Value.absent(),
              }) => FocusLogRowsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                focusMs: focusMs,
                rounds: rounds,
                endedEarly: endedEarly,
                targetType: targetType,
                targetId: targetId,
                targetLabel: targetLabel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int focusMs,
                required int rounds,
                Value<bool> endedEarly = const Value.absent(),
                Value<String?> targetType = const Value.absent(),
                Value<int?> targetId = const Value.absent(),
                Value<String?> targetLabel = const Value.absent(),
              }) => FocusLogRowsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                focusMs: focusMs,
                rounds: rounds,
                endedEarly: endedEarly,
                targetType: targetType,
                targetId: targetId,
                targetLabel: targetLabel,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FocusLogRowsTable, FocusLogRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FocusLogRowsTable,
                    FocusLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusLogRowsTable,
      FocusLogRow,
      $$FocusLogRowsTableFilterComposer,
      $$FocusLogRowsTableOrderingComposer,
      $$FocusLogRowsTableAnnotationComposer,
      $$FocusLogRowsTableCreateCompanionBuilder,
      $$FocusLogRowsTableUpdateCompanionBuilder,
      (
        FocusLogRow,
        BaseReferences<_$AppDatabase, $FocusLogRowsTable, FocusLogRow>,
      ),
      FocusLogRow,
      PrefetchHooks Function()
    >;
typedef $$BillRowsTableCreateCompanionBuilder = BillRowsCompanion Function({
  Value<int> id,
  required String title,
  required int amountCents,
  required String category,
  required String cadence,
  required String nextDueOn,
  Value<bool> active,
  Value<bool> autoLog,
});
typedef $$BillRowsTableUpdateCompanionBuilder = BillRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<int> amountCents,
  Value<String> category,
  Value<String> cadence,
  Value<String> nextDueOn,
  Value<bool> active,
  Value<bool> autoLog,
});

class $$BillRowsTableFilterComposer
    extends Composer<_$AppDatabase, $BillRowsTable> {
  $$BillRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextDueOn => $composableBuilder(
    column: $table.nextDueOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoLog => $composableBuilder(
    column: $table.autoLog,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillRowsTable> {
  $$BillRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cadence => $composableBuilder(
    column: $table.cadence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextDueOn => $composableBuilder(
    column: $table.nextDueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoLog => $composableBuilder(
    column: $table.autoLog,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillRowsTable> {
  $$BillRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get cadence =>
      $composableBuilder(column: $table.cadence, builder: (column) => column);

  GeneratedColumn<String> get nextDueOn =>
      $composableBuilder(column: $table.nextDueOn, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get autoLog =>
      $composableBuilder(column: $table.autoLog, builder: (column) => column);
}

class $$BillRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillRowsTable,
          BillRow,
          $$BillRowsTableFilterComposer,
          $$BillRowsTableOrderingComposer,
          $$BillRowsTableAnnotationComposer,
          $$BillRowsTableCreateCompanionBuilder,
          $$BillRowsTableUpdateCompanionBuilder,
          (BillRow, BaseReferences<_$AppDatabase, $BillRowsTable, BillRow>),
          BillRow,
          PrefetchHooks Function()
        > {
  $$BillRowsTableTableManager(_$AppDatabase db, $BillRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> cadence = const Value.absent(),
                Value<String> nextDueOn = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> autoLog = const Value.absent(),
              }) => BillRowsCompanion(
                id: id,
                title: title,
                amountCents: amountCents,
                category: category,
                cadence: cadence,
                nextDueOn: nextDueOn,
                active: active,
                autoLog: autoLog,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int amountCents,
                required String category,
                required String cadence,
                required String nextDueOn,
                Value<bool> active = const Value.absent(),
                Value<bool> autoLog = const Value.absent(),
              }) => BillRowsCompanion.insert(
                id: id,
                title: title,
                amountCents: amountCents,
                category: category,
                cadence: cadence,
                nextDueOn: nextDueOn,
                active: active,
                autoLog: autoLog,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillRowsTable, BillRow>(table),
                  BaseReferences<_$AppDatabase, $BillRowsTable, BillRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BillRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillRowsTable,
      BillRow,
      $$BillRowsTableFilterComposer,
      $$BillRowsTableOrderingComposer,
      $$BillRowsTableAnnotationComposer,
      $$BillRowsTableCreateCompanionBuilder,
      $$BillRowsTableUpdateCompanionBuilder,
      (BillRow, BaseReferences<_$AppDatabase, $BillRowsTable, BillRow>),
      BillRow,
      PrefetchHooks Function()
    >;
typedef $$TaskRowsTableCreateCompanionBuilder = TaskRowsCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> notes,
  Value<String?> dueOn,
  Value<String> repeat,
  Value<bool> done,
  Value<DateTime?> doneAt,
  required DateTime createdAt,
});
typedef $$TaskRowsTableUpdateCompanionBuilder = TaskRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> notes,
  Value<String?> dueOn,
  Value<String> repeat,
  Value<bool> done,
  Value<DateTime?> doneAt,
  Value<DateTime> createdAt,
});

class $$TaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeat => $composableBuilder(
    column: $table.repeat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TaskRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRowsTable,
          TaskRow,
          $$TaskRowsTableFilterComposer,
          $$TaskRowsTableOrderingComposer,
          $$TaskRowsTableAnnotationComposer,
          $$TaskRowsTableCreateCompanionBuilder,
          $$TaskRowsTableUpdateCompanionBuilder,
          (TaskRow, BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow>),
          TaskRow,
          PrefetchHooks Function()
        > {
  $$TaskRowsTableTableManager(_$AppDatabase db, $TaskRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> dueOn = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TaskRowsCompanion(
                id: id,
                title: title,
                notes: notes,
                dueOn: dueOn,
                repeat: repeat,
                done: done,
                doneAt: doneAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<String?> dueOn = const Value.absent(),
                Value<String> repeat = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                required DateTime createdAt,
              }) => TaskRowsCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                dueOn: dueOn,
                repeat: repeat,
                done: done,
                doneAt: doneAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskRowsTable, TaskRow>(table),
                  BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRowsTable,
      TaskRow,
      $$TaskRowsTableFilterComposer,
      $$TaskRowsTableOrderingComposer,
      $$TaskRowsTableAnnotationComposer,
      $$TaskRowsTableCreateCompanionBuilder,
      $$TaskRowsTableUpdateCompanionBuilder,
      (TaskRow, BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow>),
      TaskRow,
      PrefetchHooks Function()
    >;
typedef $$GoalRowsTableCreateCompanionBuilder = GoalRowsCompanion Function({
  Value<int> id,
  required String title,
  required int targetCents,
  Value<int> savedCents,
  Value<String?> targetDate,
  required DateTime createdAt,
});
typedef $$GoalRowsTableUpdateCompanionBuilder = GoalRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<int> targetCents,
  Value<int> savedCents,
  Value<String?> targetDate,
  Value<DateTime> createdAt,
});

class $$GoalRowsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalRowsTable> {
  $$GoalRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalRowsTable> {
  $$GoalRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalRowsTable> {
  $$GoalRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GoalRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalRowsTable,
          GoalRow,
          $$GoalRowsTableFilterComposer,
          $$GoalRowsTableOrderingComposer,
          $$GoalRowsTableAnnotationComposer,
          $$GoalRowsTableCreateCompanionBuilder,
          $$GoalRowsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalRowsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalRowsTableTableManager(_$AppDatabase db, $GoalRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> targetCents = const Value.absent(),
                Value<int> savedCents = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GoalRowsCompanion(
                id: id,
                title: title,
                targetCents: targetCents,
                savedCents: savedCents,
                targetDate: targetDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int targetCents,
                Value<int> savedCents = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                required DateTime createdAt,
              }) => GoalRowsCompanion.insert(
                id: id,
                title: title,
                targetCents: targetCents,
                savedCents: savedCents,
                targetDate: targetDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalRowsTable, GoalRow>(table),
                  BaseReferences<_$AppDatabase, $GoalRowsTable, GoalRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalRowsTable,
      GoalRow,
      $$GoalRowsTableFilterComposer,
      $$GoalRowsTableOrderingComposer,
      $$GoalRowsTableAnnotationComposer,
      $$GoalRowsTableCreateCompanionBuilder,
      $$GoalRowsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalRowsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;
typedef $$IouRowsTableCreateCompanionBuilder = IouRowsCompanion Function({
  Value<int> id,
  required String person,
  required String direction,
  required int amountCents,
  Value<String?> note,
  required String occurredOn,
  Value<bool> settled,
  Value<DateTime?> settledAt,
  required DateTime createdAt,
});
typedef $$IouRowsTableUpdateCompanionBuilder = IouRowsCompanion Function({
  Value<int> id,
  Value<String> person,
  Value<String> direction,
  Value<int> amountCents,
  Value<String?> note,
  Value<String> occurredOn,
  Value<bool> settled,
  Value<DateTime?> settledAt,
  Value<DateTime> createdAt,
});

class $$IouRowsTableFilterComposer
    extends Composer<_$AppDatabase, $IouRowsTable> {
  $$IouRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IouRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $IouRowsTable> {
  $$IouRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IouRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IouRowsTable> {
  $$IouRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get settled =>
      $composableBuilder(column: $table.settled, builder: (column) => column);

  GeneratedColumn<DateTime> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$IouRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IouRowsTable,
          IouRow,
          $$IouRowsTableFilterComposer,
          $$IouRowsTableOrderingComposer,
          $$IouRowsTableAnnotationComposer,
          $$IouRowsTableCreateCompanionBuilder,
          $$IouRowsTableUpdateCompanionBuilder,
          (IouRow, BaseReferences<_$AppDatabase, $IouRowsTable, IouRow>),
          IouRow,
          PrefetchHooks Function()
        > {
  $$IouRowsTableTableManager(_$AppDatabase db, $IouRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IouRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IouRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IouRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> occurredOn = const Value.absent(),
                Value<bool> settled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IouRowsCompanion(
                id: id,
                person: person,
                direction: direction,
                amountCents: amountCents,
                note: note,
                occurredOn: occurredOn,
                settled: settled,
                settledAt: settledAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String person,
                required String direction,
                required int amountCents,
                Value<String?> note = const Value.absent(),
                required String occurredOn,
                Value<bool> settled = const Value.absent(),
                Value<DateTime?> settledAt = const Value.absent(),
                required DateTime createdAt,
              }) => IouRowsCompanion.insert(
                id: id,
                person: person,
                direction: direction,
                amountCents: amountCents,
                note: note,
                occurredOn: occurredOn,
                settled: settled,
                settledAt: settledAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IouRowsTable, IouRow>(table),
                  BaseReferences<_$AppDatabase, $IouRowsTable, IouRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IouRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IouRowsTable,
      IouRow,
      $$IouRowsTableFilterComposer,
      $$IouRowsTableOrderingComposer,
      $$IouRowsTableAnnotationComposer,
      $$IouRowsTableCreateCompanionBuilder,
      $$IouRowsTableUpdateCompanionBuilder,
      (IouRow, BaseReferences<_$AppDatabase, $IouRowsTable, IouRow>),
      IouRow,
      PrefetchHooks Function()
    >;
typedef $$RecallReviewRowsTableCreateCompanionBuilder =
    RecallReviewRowsCompanion Function({
      required int noteId,
      required String cardKey,
      Value<int> box,
      required String nextReviewOn,
      Value<DateTime?> lastReviewedAt,
      Value<int> timesReviewed,
      Value<int> rowid,
    });
typedef $$RecallReviewRowsTableUpdateCompanionBuilder =
    RecallReviewRowsCompanion Function({
      Value<int> noteId,
      Value<String> cardKey,
      Value<int> box,
      Value<String> nextReviewOn,
      Value<DateTime?> lastReviewedAt,
      Value<int> timesReviewed,
      Value<int> rowid,
    });

class $$RecallReviewRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RecallReviewRowsTable> {
  $$RecallReviewRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardKey => $composableBuilder(
    column: $table.cardKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextReviewOn => $composableBuilder(
    column: $table.nextReviewOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesReviewed => $composableBuilder(
    column: $table.timesReviewed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecallReviewRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecallReviewRowsTable> {
  $$RecallReviewRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardKey => $composableBuilder(
    column: $table.cardKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextReviewOn => $composableBuilder(
    column: $table.nextReviewOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesReviewed => $composableBuilder(
    column: $table.timesReviewed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecallReviewRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecallReviewRowsTable> {
  $$RecallReviewRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get cardKey =>
      $composableBuilder(column: $table.cardKey, builder: (column) => column);

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<String> get nextReviewOn => $composableBuilder(
    column: $table.nextReviewOn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesReviewed => $composableBuilder(
    column: $table.timesReviewed,
    builder: (column) => column,
  );
}

class $$RecallReviewRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecallReviewRowsTable,
          RecallReviewRow,
          $$RecallReviewRowsTableFilterComposer,
          $$RecallReviewRowsTableOrderingComposer,
          $$RecallReviewRowsTableAnnotationComposer,
          $$RecallReviewRowsTableCreateCompanionBuilder,
          $$RecallReviewRowsTableUpdateCompanionBuilder,
          (
            RecallReviewRow,
            BaseReferences<
              _$AppDatabase,
              $RecallReviewRowsTable,
              RecallReviewRow
            >,
          ),
          RecallReviewRow,
          PrefetchHooks Function()
        > {
  $$RecallReviewRowsTableTableManager(
    _$AppDatabase db,
    $RecallReviewRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecallReviewRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecallReviewRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecallReviewRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> noteId = const Value.absent(),
                Value<String> cardKey = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<String> nextReviewOn = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> timesReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecallReviewRowsCompanion(
                noteId: noteId,
                cardKey: cardKey,
                box: box,
                nextReviewOn: nextReviewOn,
                lastReviewedAt: lastReviewedAt,
                timesReviewed: timesReviewed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int noteId,
                required String cardKey,
                Value<int> box = const Value.absent(),
                required String nextReviewOn,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<int> timesReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecallReviewRowsCompanion.insert(
                noteId: noteId,
                cardKey: cardKey,
                box: box,
                nextReviewOn: nextReviewOn,
                lastReviewedAt: lastReviewedAt,
                timesReviewed: timesReviewed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecallReviewRowsTable, RecallReviewRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RecallReviewRowsTable,
                    RecallReviewRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecallReviewRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecallReviewRowsTable,
      RecallReviewRow,
      $$RecallReviewRowsTableFilterComposer,
      $$RecallReviewRowsTableOrderingComposer,
      $$RecallReviewRowsTableAnnotationComposer,
      $$RecallReviewRowsTableCreateCompanionBuilder,
      $$RecallReviewRowsTableUpdateCompanionBuilder,
      (
        RecallReviewRow,
        BaseReferences<_$AppDatabase, $RecallReviewRowsTable, RecallReviewRow>,
      ),
      RecallReviewRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventRowsTableTableManager get eventRows =>
      $$EventRowsTableTableManager(_db, _db.eventRows);
  $$TransactionRowsTableTableManager get transactionRows =>
      $$TransactionRowsTableTableManager(_db, _db.transactionRows);
  $$NoteRowsTableTableManager get noteRows =>
      $$NoteRowsTableTableManager(_db, _db.noteRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
  $$ShiftRowsTableTableManager get shiftRows =>
      $$ShiftRowsTableTableManager(_db, _db.shiftRows);
  $$PhoneDayRowsTableTableManager get phoneDayRows =>
      $$PhoneDayRowsTableTableManager(_db, _db.phoneDayRows);
  $$PhoneAppDayRowsTableTableManager get phoneAppDayRows =>
      $$PhoneAppDayRowsTableTableManager(_db, _db.phoneAppDayRows);
  $$AlarmRowsTableTableManager get alarmRows =>
      $$AlarmRowsTableTableManager(_db, _db.alarmRows);
  $$FocusLogRowsTableTableManager get focusLogRows =>
      $$FocusLogRowsTableTableManager(_db, _db.focusLogRows);
  $$BillRowsTableTableManager get billRows =>
      $$BillRowsTableTableManager(_db, _db.billRows);
  $$TaskRowsTableTableManager get taskRows =>
      $$TaskRowsTableTableManager(_db, _db.taskRows);
  $$GoalRowsTableTableManager get goalRows =>
      $$GoalRowsTableTableManager(_db, _db.goalRows);
  $$IouRowsTableTableManager get iouRows =>
      $$IouRowsTableTableManager(_db, _db.iouRows);
  $$RecallReviewRowsTableTableManager get recallReviewRows =>
      $$RecallReviewRowsTableTableManager(_db, _db.recallReviewRows);
}
