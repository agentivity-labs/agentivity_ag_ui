/// Scripted AG-UI event stream that drives the full shopping demo.
///
/// The sequence showcases every major AG-UI feature:
///   Activity snapshot → Reasoning → Tool calls × 2 → Text → Product cards
///   → Text → RUN_FINISHED with interrupt → (resume after user choice)
///   → STATE_DELTA cart update → Confirmation text → RUN_FINISHED
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';

// ── Phase 1: discovery ────────────────────────────────────────────────────────

Stream<AgUiEvent> buildDemoStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'run-1'});

  // Initial state
  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {
      'cart': <Map<String, dynamic>>[],
      'total': 0.0,
      'itemCount': 0,
      'step': 'discover',
    },
  });

  // Activity: scanning preferences
  await _d(300);
  yield _e({
    'type': 'ACTIVITY_SNAPSHOT',
    'activities': [
      {
        'messageId': 'act1',
        'activityType': 'scan',
        'content': {
          'label': 'Scanning your preferences…',
          'progress': 0.1,
        },
      },
    ],
  });

  // ── Reasoning block ──────────────────────────────────────────────────────────
  await _d(200);
  yield _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'think1'});

  const thought =
      'The user wants tech products under €100. '
      'I have three strong candidates: wireless earbuds, a smart fitness band, '
      'and a high-capacity power bank. '
      'All are highly rated. I will present them ranked by value.';

  for (var i = 0; i < thought.length; i += 9) {
    await _d(55);
    final end = (i + 9).clamp(0, thought.length);
    yield _e({
      'type': 'REASONING_MESSAGE_CONTENT',
      'messageId': 'think1',
      'delta': thought.substring(i, end),
    });
  }
  await _d(150);
  yield _e({'type': 'REASONING_MESSAGE_END', 'messageId': 'think1'});

  // Activity update
  await _d(150);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'delta': [
      {'op': 'replace', 'path': '/content/progress', 'value': 0.3},
      {'op': 'replace', 'path': '/content/label', 'value': 'Searching catalog…'},
    ],
  });

  // ── Step: search ─────────────────────────────────────────────────────────────
  yield _e({'type': 'STEP_STARTED', 'stepName': 'search'});

  await _d(200);
  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc1',
    'toolCallName': 'searchProducts',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc1',
    'delta': '{"query":"tech gifts under 100","categories":["audio","fitness","power"]}',
  });
  await _d(900);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc1'});
  await _d(120);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc1',
    'content': '24 products found — filtering by rating ≥ 4.5…',
  });

  yield _e({'type': 'STEP_FINISHED', 'stepName': 'search'});

  // Activity update
  await _d(150);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'delta': [
      {'op': 'replace', 'path': '/content/progress', 'value': 0.65},
      {'op': 'replace', 'path': '/content/label', 'value': 'Ranking top picks…'},
    ],
  });

  // ── Step: rank ───────────────────────────────────────────────────────────────
  yield _e({'type': 'STEP_STARTED', 'stepName': 'rank'});

  await _d(200);
  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc2',
    'toolCallName': 'rankByValueScore',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc2',
    'delta': '{"candidateIds":["p1","p2","p3"],"maxResults":3}',
  });
  await _d(700);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc2'});
  await _d(120);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc2',
    'content': 'Ranked: p1 (score 9.4) > p3 (score 9.1) > p2 (score 8.8)',
  });

  yield _e({'type': 'STEP_FINISHED', 'stepName': 'rank'});

  // Activity: almost done
  await _d(150);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'delta': [
      {'op': 'replace', 'path': '/content/progress', 'value': 0.95},
      {'op': 'replace', 'path': '/content/label', 'value': 'Preparing recommendations…'},
    ],
  });

  // ── Intro assistant message ──────────────────────────────────────────────────
  await _d(200);
  yield _e({
    'type': 'TEXT_MESSAGE_START',
    'messageId': 'm1',
    'role': 'assistant',
  });
  const intro =
      "✨ I found **3 perfect picks** under €100 — all top-rated by thousands of buyers:";
  for (var i = 0; i < intro.length; i += 5) {
    await _d(45);
    final end = (i + 5).clamp(0, intro.length);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm1',
      'delta': intro.substring(i, end),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

  // Activity cleared on run end — clear now to clean up the bar
  await _d(100);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'delta': [
      {'op': 'replace', 'path': '/content/progress', 'value': 1.0},
    ],
  });

  // ── Product cards via CUSTOM render ──────────────────────────────────────────
  for (final p in [
    {
      'id': 'p1',
      'name': 'ProSound Earbuds',
      'tagline': '40h battery · ANC · IPX5 · Hi-Res Audio',
      'price': '€69.99',
      'emoji': '🎧',
      'category': 'Audio',
      'rating': 4.8,
      'reviews': 2340,
      'badge': '⭐ Top Rated',
    },
    {
      'id': 'p2',
      'name': 'SmartTrack Pro Band',
      'tagline': '14-day battery · SpO2 · GPS · Swim-proof',
      'price': '€79.99',
      'emoji': '⌚',
      'category': 'Fitness',
      'rating': 4.6,
      'reviews': 1820,
      'badge': '🔥 Most Popular',
    },
    {
      'id': 'p3',
      'name': 'TurboCharge 20000',
      'tagline': '20,000 mAh · 65W PD · 3 ports · LED display',
      'price': '€54.99',
      'emoji': '⚡',
      'category': 'Power',
      'rating': 4.7,
      'reviews': 3100,
      'badge': '💰 Best Value',
    },
  ]) {
    await _d(300);
    yield _e({
      'type': 'CUSTOM',
      'name': 'ag-ui:render',
      'value': {'component': 'ProductCard', 'props': p},
    });
  }

  // ── Closing message with call-to-action ──────────────────────────────────────
  await _d(350);
  yield _e({
    'type': 'TEXT_MESSAGE_START',
    'messageId': 'm2',
    'role': 'assistant',
  });
  const cta =
      'All come with free shipping & 30-day returns. '
      'Which one would you like to add to your cart? 🛒';
  for (var i = 0; i < cta.length; i += 5) {
    await _d(50);
    final end = (i + 5).clamp(0, cta.length);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm2',
      'delta': cta.substring(i, end),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});

  // ── Interrupt: wait for user to pick a product ───────────────────────────────
  await _d(400);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'th1',
    'runId': 'run-1',
    'outcome': {
      'type': 'interrupt',
      'interrupts': [
        {
          'id': 'pick-product',
          'reason': 'user_choice',
          'message': 'Pick a product to add to cart.',
        },
      ],
    },
  });
}

// ── Phase 2: resume after product selection ───────────────────────────────────

Stream<AgUiEvent> buildResumeStream({
  required String productId,
  required String productName,
  required String price,
  required double priceValue,
}) async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'th1', 'runId': 'run-2'});

  await _d(200);

  // Update cart via STATE_DELTA
  yield _e({
    'type': 'STATE_DELTA',
    'delta': [
      {
        'op': 'add',
        'path': '/cart/-',
        'value': {'id': productId, 'name': productName, 'price': price},
      },
      {'op': 'replace', 'path': '/total', 'value': priceValue},
      {'op': 'replace', 'path': '/itemCount', 'value': 1},
    ],
  });

  await _d(250);

  // Confirmation
  yield _e({
    'type': 'TEXT_MESSAGE_START',
    'messageId': 'conf1',
    'role': 'assistant',
  });
  final msg =
      '✅ Added **$productName** ($price) to your cart!\n\n'
      'You can checkout anytime. Want me to find anything else?';
  for (var i = 0; i < msg.length; i += 5) {
    await _d(45);
    final end = (i + 5).clamp(0, msg.length);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'conf1',
      'delta': msg.substring(i, end),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'conf1'});

  await _d(300);
  yield _e({'type': 'RUN_FINISHED', 'threadId': 'th1', 'runId': 'run-2'});
}

// ── Helpers ───────────────────────────────────────────────────────────────────

AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);
Future<void> _d(int ms) => Future.delayed(Duration(milliseconds: ms));
