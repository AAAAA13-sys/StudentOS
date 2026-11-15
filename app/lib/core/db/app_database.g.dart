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
          ..write('noteId: $noteId')
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
          other.noteId == this.noteId);
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
          ..write('noteId: $noteId')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    tags,
    createdAt,
    updatedAt,
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
  const NoteRow({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
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
    };
  }

  NoteRow copyWith({
    int? id,
    String? title,
    String? body,
    String? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteRow(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteRow copyWithCompanion(NoteRowsCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, body, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NoteRowsCompanion extends UpdateCompanion<NoteRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NoteRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NoteRowsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    required String tags,
    required DateTime createdAt,
    required DateTime updatedAt,
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
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NoteRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return NoteRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
          ..write('updatedAt: $updatedAt')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventRows,
    transactionRows,
    noteRows,
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
});
typedef $$NoteRowsTableUpdateCompanionBuilder = NoteRowsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> body,
  Value<String> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
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
              }) => NoteRowsCompanion(
                id: id,
                title: title,
                body: body,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String body,
                required String tags,
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => NoteRowsCompanion.insert(
                id: id,
                title: title,
                body: body,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventRowsTableTableManager get eventRows =>
      $$EventRowsTableTableManager(_db, _db.eventRows);
  $$TransactionRowsTableTableManager get transactionRows =>
      $$TransactionRowsTableTableManager(_db, _db.transactionRows);
  $$NoteRowsTableTableManager get noteRows =>
      $$NoteRowsTableTableManager(_db, _db.noteRows);
}
