/// One run through some quiz cards, kept in memory only. Cards are numbered
/// by their position in the note.
class QuizSession {
  QuizSession(int cardCount)
    : active = List<int>.generate(cardCount, (int i) => i);

  QuizSession._(this.active);

  /// The cards in this run, in note order.
  final List<int> active;

  final Map<int, bool> _results = <int, bool>{};

  /// Marks card [index] right or missed; the last mark wins.
  void mark(int index, {required bool right}) {
    if (active.contains(index)) _results[index] = right;
  }

  /// Whether card [index] was marked right, missed, or not yet (null).
  bool? resultOf(int index) => _results[index];

  /// True once every card in this run is marked.
  bool get done => active.isNotEmpty && _results.length == active.length;

  int get rightCount => _results.values.where((bool r) => r).length;

  List<int> get missed => <int>[
    for (final int i in active)
      if (_results[i] == false) i,
  ];

  /// "6 of 10 right".
  String get tally => '$rightCount of ${active.length} right';

  /// A fresh run of only the missed cards.
  QuizSession retryMissed() => QuizSession._(missed);
}
