import 'dart:async';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// Emits events from a list, then closes.
Stream<AgUiEvent> _stream(List<AgUiEvent> events) => Stream.fromIterable(events);

// Drains all pending stream microtasks by yielding to a timer.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

StateSnapshotEvent _snapshot(Map<String, dynamic> snap) => AgUiEvent.fromJson({
      'type': 'STATE_SNAPSHOT',
      'snapshot': snap,
    }) as StateSnapshotEvent;

StateDeltaEvent _delta(List<Map<String, dynamic>> ops) => AgUiEvent.fromJson({
      'type': 'STATE_DELTA',
      'delta': ops,
    }) as StateDeltaEvent;

void main() {
  group('AgUiStateController', () {
    // ── STATE_SNAPSHOT ────────────────────────────────────────────────────────

    test('initial state is empty', () {
      final ctrl = AgUiStateController(events: const Stream.empty());
      expect(ctrl.state, isEmpty);
      ctrl.dispose();
    });

    test('STATE_SNAPSHOT replaces entire state', () async {
      final snap = {'count': 1, 'name': 'Alice'};
      final ctrl = AgUiStateController(events: _stream([_snapshot(snap)]));
      await _pump();
      expect(ctrl.state, {'count': 1, 'name': 'Alice'});
      ctrl.dispose();
    });

    test('STATE_SNAPSHOT replaces previous state completely', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'a': 1, 'b': 2}),
          _snapshot({'c': 3}),
        ]),
      );
      await _pump();
      expect(ctrl.state, {'c': 3});
      expect(ctrl['a'], isNull);
      ctrl.dispose();
    });

    test('operator [] reads top-level key', () async {
      final ctrl = AgUiStateController(events: _stream([_snapshot({'x': 42})]));
      await _pump();
      expect(ctrl['x'], 42);
      ctrl.dispose();
    });

    test('notifies listeners on STATE_SNAPSHOT', () async {
      var notified = 0;
      final ctrl = AgUiStateController(events: _stream([_snapshot({'k': 'v'})]));
      ctrl.addListener(() => notified++);
      await _pump();
      expect(notified, greaterThan(0));
      ctrl.dispose();
    });

    // ── STATE_DELTA — add ─────────────────────────────────────────────────────

    test('STATE_DELTA add inserts key into state', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'a': 1}),
          _delta([
            {'op': 'add', 'path': '/b', 'value': 2}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state, {'a': 1, 'b': 2});
      ctrl.dispose();
    });

    test('STATE_DELTA add appends to list with - index', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({
            'items': [1, 2]
          }),
          _delta([
            {'op': 'add', 'path': '/items/-', 'value': 3}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['items'], [1, 2, 3]);
      ctrl.dispose();
    });

    test('STATE_DELTA add inserts at list index', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({
            'items': ['a', 'c']
          }),
          _delta([
            {'op': 'add', 'path': '/items/1', 'value': 'b'}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['items'], ['a', 'b', 'c']);
      ctrl.dispose();
    });

    // ── STATE_DELTA — replace ─────────────────────────────────────────────────

    test('STATE_DELTA replace updates existing key', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'count': 0}),
          _delta([
            {'op': 'replace', 'path': '/count', 'value': 5}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['count'], 5);
      ctrl.dispose();
    });

    test('STATE_DELTA replace updates nested key', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({
            'user': {'name': 'Alice', 'age': 30}
          }),
          _delta([
            {'op': 'replace', 'path': '/user/age', 'value': 31}
          ]),
        ]),
      );
      await _pump();
      expect((ctrl.state['user'] as Map)['age'], 31);
      expect((ctrl.state['user'] as Map)['name'], 'Alice');
      ctrl.dispose();
    });

    // ── STATE_DELTA — remove ──────────────────────────────────────────────────

    test('STATE_DELTA remove deletes a key', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'keep': 1, 'drop': 2}),
          _delta([
            {'op': 'remove', 'path': '/drop'}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state.containsKey('drop'), isFalse);
      expect(ctrl.state['keep'], 1);
      ctrl.dispose();
    });

    test('STATE_DELTA remove deletes list item by index', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({
            'items': ['a', 'b', 'c']
          }),
          _delta([
            {'op': 'remove', 'path': '/items/1'}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['items'], ['a', 'c']);
      ctrl.dispose();
    });

    // ── STATE_DELTA — copy ────────────────────────────────────────────────────

    test('STATE_DELTA copy duplicates a value', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'src': 42}),
          _delta([
            {'op': 'copy', 'from': '/src', 'path': '/dst'}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['src'], 42);
      expect(ctrl.state['dst'], 42);
      ctrl.dispose();
    });

    // ── STATE_DELTA — move ────────────────────────────────────────────────────

    test('STATE_DELTA move renames a key', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'old': 'hello'}),
          _delta([
            {'op': 'move', 'from': '/old', 'path': '/new'}
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state.containsKey('old'), isFalse);
      expect(ctrl.state['new'], 'hello');
      ctrl.dispose();
    });

    // ── Escaped path segments (RFC 6902 §3) ──────────────────────────────────

    test('STATE_DELTA handles ~ escaped path segments', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'a~b': 1, 'c/d': 2}),
          _delta([
            {'op': 'replace', 'path': '/a~0b', 'value': 10},
            {'op': 'replace', 'path': '/c~1d', 'value': 20},
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state['a~b'], 10);
      expect(ctrl.state['c/d'], 20);
      ctrl.dispose();
    });

    // ── Multiple ops in one delta ─────────────────────────────────────────────

    test('STATE_DELTA applies multiple operations in order', () async {
      final ctrl = AgUiStateController(
        events: _stream([
          _snapshot({'x': 0, 'y': 0}),
          _delta([
            {'op': 'replace', 'path': '/x', 'value': 1},
            {'op': 'replace', 'path': '/y', 'value': 2},
            {'op': 'add', 'path': '/z', 'value': 3},
          ]),
        ]),
      );
      await _pump();
      expect(ctrl.state, {'x': 1, 'y': 2, 'z': 3});
      ctrl.dispose();
    });

    // ── Immutability (delta does not mutate the previous state object) ────────

    test('STATE_DELTA does not mutate prior state object', () async {
      final ctrl = AgUiStateController(events: const Stream.empty());
      // Seed state directly via snapshot event
      final stream = StreamController<AgUiEvent>();
      final ctrl2 = AgUiStateController(events: stream.stream);
      stream.add(_snapshot({'val': 1}));
      await _pump();
      final before = ctrl2.state;
      stream.add(_delta([
        {'op': 'replace', 'path': '/val', 'value': 99}
      ]));
      await _pump();
      // before should still hold the old value (it's a different Map instance)
      expect(before['val'], 1);
      expect(ctrl2.state['val'], 99);
      await stream.close();
      ctrl2.dispose();
      ctrl.dispose();
    });

    // ── notifies listeners on delta ───────────────────────────────────────────

    test('notifies listeners on STATE_DELTA', () async {
      var notified = 0;
      final stream = StreamController<AgUiEvent>();
      final ctrl = AgUiStateController(events: stream.stream);
      ctrl.addListener(() => notified++);
      stream.add(_snapshot({'a': 1}));
      await _pump();
      final before = notified;
      stream.add(_delta([
        {'op': 'add', 'path': '/b', 'value': 2}
      ]));
      await _pump();
      expect(notified, greaterThan(before));
      await stream.close();
      ctrl.dispose();
    });
  });
}
