import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

// Build a one-shot ResponseBody from raw SSE text.
ResponseBody _sseBody(String text) => ResponseBody(
      Stream.value(Uint8List.fromList(utf8.encode(text))),
      200,
      headers: {},
    );

// Opener that immediately returns a fixed body.
AgUiSseOpener _fixedOpener(ResponseBody rb) =>
    (_, {lastEventId, cancelToken}) async => rb;

// Opener backed by a caller-supplied StreamController so we can push/close at will.
typedef _CtrlOpener = ({AgUiSseOpener opener, StreamController<Uint8List> ctrl});

_CtrlOpener _ctrlOpener() {
  final ctrl = StreamController<Uint8List>();
  return (
    opener: (_, {lastEventId, cancelToken}) async =>
        ResponseBody(ctrl.stream, 200, headers: {}),
    ctrl: ctrl,
  );
}

// Pushes raw SSE text into a StreamController as bytes.
void _push(StreamController<Uint8List> ctrl, String text) =>
    ctrl.add(Uint8List.fromList(utf8.encode(text)));

// Collects exactly [count] events, then returns.
Future<List<T>> _take<T>(Stream<T> stream, int count) async {
  final result = <T>[];
  await for (final e in stream) {
    result.add(e);
    if (result.length >= count) break;
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── SSE frame parser (RFC 8895) ─────────────────────────────────────────────

  group('SSE frame parser', () {
    // All tests exercise _SseFrameParser indirectly through the channel.

    test('plain data field is emitted', () async {
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data: hello\n\n')),
        path: '/',
        parser: (_, __, data) => data,
      );
      ch.start();
      expect(await _take(ch.stream, 1), ['hello']);
      await ch.dispose();
    });

    test('only the first leading space is stripped from field value', () async {
      // RFC 8895 §9.2.5 — strip exactly one space after the colon.
      final rec = <String?>[];
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data:  two leading spaces\n\n')),
        path: '/',
        parser: (_, __, data) { rec.add(data); return data; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(rec.single, ' two leading spaces'); // one space remains
      await ch.dispose();
    });

    test('multi-line data joined with newline', () async {
      final rec = <String?>[];
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data: a\ndata: b\ndata: c\n\n')),
        path: '/',
        parser: (_, __, data) { rec.add(data); return data; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(rec.single, 'a\nb\nc');
      await ch.dispose();
    });

    test('named event field is forwarded to parser', () async {
      final events = <String>[];
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('event: MY_TYPE\ndata: x\n\n')),
        path: '/',
        parser: (event, _, __) { events.add(event); return event; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(events.single, 'MY_TYPE');
      await ch.dispose();
    });

    test('default event name is "message" when field absent', () async {
      final events = <String>[];
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data: x\n\n')),
        path: '/',
        parser: (event, _, __) { events.add(event); return event; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(events.single, 'message');
      await ch.dispose();
    });

    test('id field is forwarded to parser', () async {
      final ids = <String?>[];
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('id: evt-7\ndata: x\n\n')),
        path: '/',
        parser: (_, id, data) { ids.add(id); return data; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(ids.single, 'evt-7');
      await ch.dispose();
    });

    test('comment lines (starting with :) are ignored', () async {
      int calls = 0;
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(
            _sseBody(': keepalive\n: second comment\ndata: real\n\n')),
        path: '/',
        parser: (_, __, data) { calls++; return data; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(calls, 1);
      await ch.dispose();
    });

    test('blank-line-only frame is not dispatched', () async {
      int calls = 0;
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('\n\n\ndata: real\n\n')),
        path: '/',
        parser: (_, __, data) { calls++; return data; },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(calls, 1); // only the 'real' frame reaches the parser
      await ch.dispose();
    });

    test('multiple frames emitted in order', () async {
      final ch = AgUiSseChannel<String>(
        opener:
            _fixedOpener(_sseBody('data: one\n\ndata: two\n\ndata: three\n\n')),
        path: '/',
        parser: (_, __, data) => data,
      );
      ch.start();
      expect(await _take(ch.stream, 3), ['one', 'two', 'three']);
      await ch.dispose();
    });

    test('retry field does not crash, data in same frame still emitted',
        () async {
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('retry: 2000\ndata: ok\n\n')),
        path: '/',
        parser: (_, __, data) => data,
      );
      ch.start();
      expect(await _take(ch.stream, 1), ['ok']);
      await ch.dispose();
    });

    test('invalid retry value (non-integer) is silently ignored', () async {
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('retry: bad\ndata: ok\n\n')),
        path: '/',
        parser: (_, __, data) => data,
      );
      ch.start();
      expect(await _take(ch.stream, 1), ['ok']);
      await ch.dispose();
    });

    test('field with no colon treated as bare field name with empty value',
        () async {
      // RFC 8895 §9.2.6: a line with no colon is the entire field name, value is ''.
      // 'data' bare → data == '' → parser receives ''
      int calls = 0;
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data\n\ndata: real\n\n')),
        path: '/',
        parser: (_, __, data) {
          calls++;
          return data?.isEmpty == true ? null : data;
        },
      );
      ch.start();
      final got = await _take(ch.stream, 1);
      expect(got, ['real']);
      expect(calls, 2); // parser called for both frames
      await ch.dispose();
    });

    test('parser returning null suppresses event emission', () async {
      final ch = AgUiSseChannel<String>(
        opener:
            _fixedOpener(_sseBody('data: drop\n\ndata: keep\n\n')),
        path: '/',
        parser: (_, __, data) => data == 'drop' ? null : data,
      );
      ch.start();
      expect(await _take(ch.stream, 1), ['keep']);
      await ch.dispose();
    });

    test('parser exception is caught and stream continues', () async {
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data: boom\n\ndata: fine\n\n')),
        path: '/',
        parser: (_, __, data) {
          if (data == 'boom') throw Exception('parser crash');
          return data;
        },
      );
      ch.start();
      // Stream must survive the parser crash and deliver 'fine'.
      expect(await _take(ch.stream, 1), ['fine']);
      await ch.dispose();
    });

    test('event+data+id in same frame all forwarded correctly', () async {
      String? gotEvent, gotId, gotData;
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(
            _sseBody('event: PING\nid: 99\ndata: pong\n\n')),
        path: '/',
        parser: (event, id, data) {
          gotEvent = event;
          gotId = id;
          gotData = data;
          return data;
        },
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(gotEvent, 'PING');
      expect(gotId, '99');
      expect(gotData, 'pong');
      await ch.dispose();
    });
  });

  // ── Channel behaviour ─────────────────────────────────────────────────────

  group('AgUiSseChannel behaviour', () {
    test('start() opens connection and delivers events', () async {
      var opened = false;
      final ch = AgUiSseChannel<String>(
        opener: (path, {lastEventId, cancelToken}) async {
          opened = true;
          return _sseBody('data: hi\n\n');
        },
        path: '/api/stream',
        parser: (_, __, data) => data,
      );
      ch.start();
      expect(await _take(ch.stream, 1), ['hi']);
      expect(opened, isTrue);
      await ch.dispose();
    });

    test('path is forwarded to opener', () async {
      String? got;
      final ch = AgUiSseChannel<String>(
        opener: (path, {lastEventId, cancelToken}) async {
          got = path;
          return _sseBody('data: x\n\n');
        },
        path: '/runs/42/events',
        parser: (_, __, data) => data,
      );
      ch.start();
      await _take(ch.stream, 1);
      expect(got, '/runs/42/events');
      await ch.dispose();
    });

    test('start() is idempotent — calling it multiple times opens once',
        () async {
      var opens = 0;
      final ch = AgUiSseChannel<String>(
        opener: (_, {lastEventId, cancelToken}) async {
          opens++;
          return _sseBody('data: x\n\n');
        },
        path: '/',
        parser: (_, __, data) => data,
      );
      ch.start();
      ch.start();
      ch.start();
      await _take(ch.stream, 1);
      expect(opens, 1);
      await ch.dispose();
    });

    test('dispose() before start() is safe', () async {
      final ch = AgUiSseChannel<String>(
        opener: _fixedOpener(_sseBody('data: x\n\n')),
        path: '/',
        parser: (_, __, data) => data,
      );
      await ch.dispose(); // must not throw
    });

    test('isConnected false initially', () {
      final (:opener, :ctrl) = _ctrlOpener();
      final ch = AgUiSseChannel<String>(
          opener: opener, path: '/', parser: (_, __, d) => d);
      expect(ch.isConnected, isFalse);
      ctrl.close();
    });

    test('isConnected becomes true once the opener resolves', () async {
      final (:opener, :ctrl) = _ctrlOpener();
      final ch = AgUiSseChannel<String>(
          opener: opener, path: '/', parser: (_, __, d) => d);
      ch.start();
      await Future<void>.delayed(Duration.zero);
      expect(ch.isConnected, isTrue);
      await ch.dispose();
      await ctrl.close();
    });

    test('isConnected becomes false when stream ends', () async {
      final (:opener, :ctrl) = _ctrlOpener();
      final ch = AgUiSseChannel<String>(
          opener: opener, path: '/', parser: (_, __, d) => d);
      ch.start();
      await Future<void>.delayed(Duration.zero);
      expect(ch.isConnected, isTrue);

      await ctrl.close();
      await Future<void>.delayed(Duration.zero);
      expect(ch.isConnected, isFalse);

      await ch.dispose();
    });

    test('isConnected becomes false after stream error', () async {
      final (:opener, :ctrl) = _ctrlOpener();
      final ch = AgUiSseChannel<String>(
          opener: opener, path: '/', parser: (_, __, d) => d);
      ch.start();
      await Future<void>.delayed(Duration.zero);

      ctrl.addError(Exception('network failure'));
      await Future<void>.delayed(Duration.zero);
      expect(ch.isConnected, isFalse);

      await ch.dispose();
      await ctrl.close();
    });

    test('events received after dispose() are not emitted', () async {
      final (:opener, :ctrl) = _ctrlOpener();
      final received = <String>[];
      final ch = AgUiSseChannel<String>(
          opener: opener, path: '/', parser: (_, __, d) => d);
      ch.stream.listen(received.add);
      ch.start();
      await Future<void>.delayed(Duration.zero);

      _push(ctrl, 'data: before\n\n');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['before']);

      await ch.dispose();

      _push(ctrl, 'data: after\n\n');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['before']); // no new event
      await ctrl.close();
    });

    test('opener failure does not crash channel — reconnect is scheduled',
        () {
      fakeAsync((fake) {
        var opens = 0;
        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            opens++;
            throw Exception('connection refused');
          },
          path: '/',
          parser: (_, __, d) => d,
        );
        ch.start();
        fake.flushMicrotasks();
        expect(opens, 1);
        expect(ch.isConnected, isFalse);

        // Advance past default retry delay
        fake.elapse(const Duration(seconds: 6));
        expect(opens, 2); // attempted to reconnect

        ch.dispose();
        fake.flushMicrotasks();
      });
    });
  });

  // ── Reconnect behaviour ───────────────────────────────────────────────────

  group('reconnect', () {
    test('reconnects after stream completes', () {
      fakeAsync((fake) {
        var opens = 0;
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            opens++;
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();
        expect(opens, 1);

        bodyCtrl.close();
        fake.flushMicrotasks();
        expect(ch.isConnected, isFalse);

        // Default retry is 5 s; advance past that + max jitter (750 ms).
        fake.elapse(const Duration(seconds: 6));
        expect(opens, 2);

        ch.dispose();
        fake.flushMicrotasks();
      });
    });

    test('reconnects after stream error', () {
      fakeAsync((fake) {
        var opens = 0;
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            opens++;
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();
        expect(opens, 1);

        bodyCtrl.addError(Exception('broken pipe'));
        fake.flushMicrotasks();
        expect(ch.isConnected, isFalse);

        fake.elapse(const Duration(seconds: 6));
        expect(opens, 2);

        ch.dispose();
        fake.flushMicrotasks();
      });
    });

    test('dispose during reconnect wait cancels the pending reconnect', () {
      fakeAsync((fake) {
        var opens = 0;
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            opens++;
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();

        bodyCtrl.close(); // triggers reconnect timer
        fake.flushMicrotasks();

        ch.dispose(); // cancels the timer
        fake.flushMicrotasks();

        fake.elapse(const Duration(seconds: 6));
        expect(opens, 1); // no second connection opened
      });
    });

    test('Last-Event-ID is carried to the opener on reconnect', () {
      fakeAsync((fake) {
        final seenIds = <String?>[];
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            seenIds.add(lastEventId);
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();

        // Push an event with an id.
        _push(bodyCtrl, 'id: abc-123\ndata: x\n\n');
        fake.flushMicrotasks();

        // End stream → reconnect timer started.
        bodyCtrl.close();
        fake.flushMicrotasks();

        fake.elapse(const Duration(seconds: 6));

        expect(seenIds.length, greaterThanOrEqualTo(2));
        expect(seenIds[0], isNull);      // first connect: no ID
        expect(seenIds[1], 'abc-123');   // reconnect carries the last seen ID

        ch.dispose();
        fake.flushMicrotasks();
      });
    });

    test('server-sent retry field overrides default delay', () {
      fakeAsync((fake) {
        var opens = 0;
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            opens++;
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();

        // Server requests a 1-second retry.
        _push(bodyCtrl, 'retry: 1000\ndata: ok\n\n');
        fake.flushMicrotasks();

        bodyCtrl.close();
        fake.flushMicrotasks();

        // 2 s should be enough (1 s retry + 750 ms max jitter).
        fake.elapse(const Duration(seconds: 2));
        expect(opens, 2);

        ch.dispose();
        fake.flushMicrotasks();
      });
    });

    test('exponential backoff: each retry delay is larger than the previous',
        () {
      fakeAsync((fake) {
        final openTimes = <Duration>[];
        late StreamController<Uint8List> bodyCtrl;

        final ch = AgUiSseChannel<String>(
          opener: (_, {lastEventId, cancelToken}) async {
            openTimes.add(fake.elapsed);
            bodyCtrl = StreamController<Uint8List>();
            return ResponseBody(bodyCtrl.stream, 200, headers: {});
          },
          path: '/',
          parser: (_, __, d) => d,
        );

        ch.start();
        fake.flushMicrotasks();

        // First disconnect.
        bodyCtrl.close();
        fake.flushMicrotasks();
        fake.elapse(const Duration(seconds: 6)); // triggers 2nd open

        // Second disconnect.
        bodyCtrl.close();
        fake.flushMicrotasks();
        // 2nd backoff = base * 2^1 = 10 s + jitter → advance 12 s to be safe.
        fake.elapse(const Duration(seconds: 12));

        // Third disconnect.
        bodyCtrl.close();
        fake.flushMicrotasks();
        // 3rd backoff = base * 2^2 = 20 s + jitter → advance 22 s.
        fake.elapse(const Duration(seconds: 22));

        expect(openTimes.length, greaterThanOrEqualTo(4));

        final gap1 = openTimes[1] - openTimes[0];
        final gap2 = openTimes[2] - openTimes[1];
        final gap3 = openTimes[3] - openTimes[2];
        expect(gap2.inMilliseconds, greaterThan(gap1.inMilliseconds));
        expect(gap3.inMilliseconds, greaterThan(gap2.inMilliseconds));

        ch.dispose();
        fake.flushMicrotasks();
      });
    });
  });

  // ── agUiEventParser integration ───────────────────────────────────────────

  group('agUiEventParser + channel', () {
    test('parses AG-UI events from a raw SSE byte stream', () async {
      const raw = 'event: RUN_STARTED\n'
          'data: {"type":"RUN_STARTED","runId":"r1"}\n'
          '\n'
          'event: RUN_FINISHED\n'
          'data: {"type":"RUN_FINISHED","runId":"r1"}\n'
          '\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 2);
      expect(events[0], isA<RunStartedEvent>());
      expect(events[1], isA<RunFinishedEvent>());
      await ch.dispose();
    });

    test('[DONE] sentinel is silently dropped', () async {
      const raw = 'data: {"type":"RUN_STARTED","runId":"r1"}\n'
          '\n'
          'data: [DONE]\n'
          '\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 1);
      expect(events, hasLength(1));
      expect(events.first, isA<RunStartedEvent>());
      await ch.dispose();
    });

    test('SSE event field used as type when JSON has no type key', () async {
      const raw = 'event: TEXT_MESSAGE_START\n'
          'data: {"messageId":"m1","role":"assistant"}\n'
          '\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 1);
      expect(events.first, isA<TextMessageStartEvent>());
      await ch.dispose();
    });

    test('full streaming text message sequence via SSE', () async {
      const raw = 'data: {"type":"TEXT_MESSAGE_START","messageId":"m1"}\n\n'
          'data: {"type":"TEXT_MESSAGE_CONTENT","messageId":"m1","delta":"Hello"}\n\n'
          'data: {"type":"TEXT_MESSAGE_CONTENT","messageId":"m1","delta":" world"}\n\n'
          'data: {"type":"TEXT_MESSAGE_END","messageId":"m1"}\n\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 4);
      expect(events[0], isA<TextMessageStartEvent>());
      expect((events[1] as TextMessageContentEvent).delta, 'Hello');
      expect((events[2] as TextMessageContentEvent).delta, ' world');
      expect(events[3], isA<TextMessageEndEvent>());
      await ch.dispose();
    });

    test('tool call sequence via SSE', () async {
      const raw =
          'data: {"type":"TOOL_CALL_START","toolCallId":"tc1","toolCallName":"search"}\n\n'
          'data: {"type":"TOOL_CALL_ARGS","toolCallId":"tc1","delta":"{\\"q\\":"}\n\n'
          'data: {"type":"TOOL_CALL_END","toolCallId":"tc1"}\n\n'
          'data: {"type":"TOOL_CALL_RESULT","messageId":"m1","toolCallId":"tc1","content":"results"}\n\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 4);
      expect(events[0], isA<ToolCallStartEvent>());
      expect((events[0] as ToolCallStartEvent).toolCallName, 'search');
      expect(events[1], isA<ToolCallArgsDeltaEvent>());
      expect(events[2], isA<ToolCallEndEvent>());
      expect(events[3], isA<ToolCallResultEvent>());
      expect((events[3] as ToolCallResultEvent).content, 'results');
      await ch.dispose();
    });

    test('interrupt outcome parsed from SSE stream', () async {
      const raw = 'data: {"type":"RUN_FINISHED","runId":"r1","outcome":'
          '{"type":"interrupt","interrupts":[{"id":"i1","reason":"approval needed"}]}}\n\n';

      final ch = AgUiSseChannel<AgUiEvent>(
        opener: _fixedOpener(_sseBody(raw)),
        path: '/',
        parser: agUiEventParser,
      );
      ch.start();
      final events = await _take(ch.stream, 1);
      final ev = events.first as RunFinishedEvent;
      expect(ev.isInterrupted, isTrue);
      expect((ev.outcome as AgUiInterruptOutcome).interrupts.first.id, 'i1');
      await ch.dispose();
    });
  });
}
