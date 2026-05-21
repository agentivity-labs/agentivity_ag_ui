/// A registry that collects readable context entries and builds the
/// `context` list for [RunAgentInput].
///
/// This is the Flutter equivalent of CopilotKit's `useCopilotReadable` hook:
/// the frontend declares data the agent can read on every run, without the
/// caller having to rebuild the context list manually each time.
///
/// ```dart
/// final context = AgUiContextRegistry();
///
/// // Register once (e.g. in initState):
/// context.register(
///   'cart',
///   description: 'Current shopping cart contents',
///   value: {'items': ['apple', 'bread'], 'total': 12.50},
/// );
///
/// // Update when data changes:
/// context.update('cart', newCartMap);
///
/// // Build RunAgentInput on every send:
/// final input = RunAgentInput(
///   threadId: threadId,
///   runId: newRunId,
///   messages: history,
///   context: context.build(),
/// );
/// ```
class AgUiContextRegistry {
  final Map<String, AgUiContextEntry> _entries = {};

  /// Register or replace a context entry under [key].
  ///
  /// [description] is what the agent sees when it reads this entry.
  /// [value] is the data — can be any JSON-serialisable object.
  void register(
    String key, {
    required String description,
    required dynamic value,
  }) {
    _entries[key] = AgUiContextEntry(description: description, value: value);
  }

  /// Update the value of an existing entry (description unchanged).
  /// Does nothing if [key] is not registered.
  void update(String key, dynamic value) {
    final e = _entries[key];
    if (e != null) {
      _entries[key] = AgUiContextEntry(description: e.description, value: value);
    }
  }

  /// Remove an entry. Does nothing if [key] is not registered.
  void unregister(String key) => _entries.remove(key);

  /// Remove all entries.
  void clear() => _entries.clear();

  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;
  int get length => _entries.length;

  /// Build the `context` list for [RunAgentInput.context].
  List<Map<String, dynamic>> build() =>
      _entries.values.map((e) => e.toJson()).toList();
}

/// A single readable context entry.
class AgUiContextEntry {
  const AgUiContextEntry({required this.description, required this.value});

  /// Human-readable description visible to the agent.
  final String description;

  /// The data — must be JSON-serialisable.
  final dynamic value;

  Map<String, dynamic> toJson() => {
        'description': description,
        'value': value,
      };
}
