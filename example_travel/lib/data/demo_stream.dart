/// Scripted AG-UI event stream driving the AI Trip Planner demo.
///
/// Phase 1 (buildDemoStream): reasoning → tool calls → flights/hotels → interrupt
/// Phase 2 (buildResumeStream): state update with confirmed itinerary → confirmation
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';

AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);
Future<void> _d(int ms) => Future.delayed(Duration(milliseconds: ms));

// ── Phase 1: discovery ────────────────────────────────────────────────────────

Stream<AgUiEvent> buildDemoStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'travel-th1', 'runId': 'travel-run-1'});

  // Initial empty state for the itinerary bar
  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {'status': 'searching', 'total': 0.0},
  });

  // ── Activity: scanning ─────────────────────────────────────────────────────
  await _d(400);
  yield _e({
    'type': 'ACTIVITY_SNAPSHOT',
    'messageId': 'act1',
    'activityType': 'search',
    'content': {
      'label': 'Searching flights & hotels…',
      'description': 'Scanning 200+ options for Barcelona',
      'progress': 0.08,
    },
  });

  // ── Reasoning ─────────────────────────────────────────────────────────────
  await _d(600);
  yield _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'think1', 'role': 'assistant'});
  const thought =
      'User wants 3 days in Barcelona, mid-June. '
      'Best route: CDG outbound — shoulder season pricing applies. '
      'I should search economy+ flights under €250 and target 4–5★ hotels '
      'in Barceloneta or Eixample. Prioritising pool access for summer heat. '
      'Hotel Arts is the benchmark; I will also surface two alternatives.';
  for (var i = 0; i < thought.length; i += 8) {
    await _d(50);
    yield _e({
      'type': 'REASONING_MESSAGE_CONTENT',
      'messageId': 'think1',
      'delta': thought.substring(i, (i + 8).clamp(0, thought.length)),
    });
  }
  yield _e({'type': 'REASONING_MESSAGE_END', 'messageId': 'think1'});

  // ── Step: flight search ───────────────────────────────────────────────────
  await _d(400);
  yield _e({'type': 'STEP_STARTED', 'stepName': 'flight_search'});
  await _d(200);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Searching flights…'},
      {'op': 'replace', 'path': '/progress', 'value': 0.25},
    ],
  });

  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc-flights',
    'toolCallName': 'search_flights',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc-flights',
    'delta': '{"origin":"CDG","destination":"BCN","date":"2025-06-15","cabin":"economy_plus","max_price":250}',
  });
  await _d(1400);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc-flights'});
  await _d(150);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc-flights',
    'content': '{"found": 2, "cheapest_eur": 189, "airlines": ["Vueling","Iberia"]}',
  });
  yield _e({'type': 'STEP_FINISHED', 'stepName': 'flight_search'});

  // ── Step: hotel search ────────────────────────────────────────────────────
  await _d(400);
  yield _e({'type': 'STEP_STARTED', 'stepName': 'hotel_search'});
  await _d(200);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Searching hotels…'},
      {'op': 'replace', 'path': '/progress', 'value': 0.55},
    ],
  });

  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc-hotels',
    'toolCallName': 'search_hotels',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc-hotels',
    'delta': '{"city":"Barcelona","checkin":"2025-06-15","nights":3,"stars_min":4,"amenities":["pool"]}',
  });
  await _d(1600);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc-hotels'});
  await _d(150);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc-hotels',
    'content': '{"found": 3, "avg_per_night_eur": 315, "top": "Hotel Arts Barcelona"}',
  });
  yield _e({'type': 'STEP_FINISHED', 'stepName': 'hotel_search'});

  // ── Activity: curating ────────────────────────────────────────────────────
  await _d(400);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Curating best options…'},
      {'op': 'replace', 'path': '/description', 'value': 'Ranking by value, reviews & comfort'},
      {'op': 'replace', 'path': '/progress', 'value': 0.88},
    ],
  });

  // ── Intro text ────────────────────────────────────────────────────────────
  await _d(700);
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'assistant'});
  const intro =
      '✈️ Great news! I found **2 flights** and **3 hotels** for your '
      '3-day Barcelona trip. Here are my top picks:';
  for (var i = 0; i < intro.length; i += 6) {
    await _d(48);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm1',
      'delta': intro.substring(i, (i + 6).clamp(0, intro.length)),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm1'});

  // Activity done
  await _d(200);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/progress', 'value': 1.0},
    ],
  });

  // ── Generative cards: flights ─────────────────────────────────────────────
  await _d(400);
  for (final id in ['f1', 'f2']) {
    yield _e({
      'type': 'CUSTOM',
      'name': 'ag-ui:render',
      'value': {'component': 'FlightCard', 'props': {'id': id}},
    });
    await _d(650);
  }

  // ── Generative cards: hotels ──────────────────────────────────────────────
  await _d(300);
  for (final id in ['h1', 'h2', 'h3']) {
    yield _e({
      'type': 'CUSTOM',
      'name': 'ag-ui:render',
      'value': {'component': 'HotelCard', 'props': {'id': id}},
    });
    await _d(700);
  }

  // ── Call-to-action text ───────────────────────────────────────────────────
  await _d(400);
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm2', 'role': 'assistant'});
  const cta =
      '**My recommendation:** Vueling VY 1234 + Hotel Arts Barcelona — '
      'total **€1,149** (flights + 3 nights). '
      'Shall I book this for you?';
  for (var i = 0; i < cta.length; i += 6) {
    await _d(55);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm2',
      'delta': cta.substring(i, (i + 6).clamp(0, cta.length)),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});

  // ── Interrupt: booking confirmation ───────────────────────────────────────
  await _d(900);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'travel-th1',
    'runId': 'travel-run-1',
    'outcome': {
      'type': 'interrupt',
      'interrupts': [
        {
          'id': 'confirm-booking',
          'reason': 'user_confirmation',
          'message': 'Confirm booking: Vueling VY 1234 + Hotel Arts Barcelona?',
        },
      ],
    },
  });
}

// ── Phase 2: resume after booking confirmation ────────────────────────────────

Stream<AgUiEvent> buildResumeStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'travel-th1', 'runId': 'travel-run-2'});
  await _d(500);

  // Confirmed itinerary via STATE_SNAPSHOT
  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {
      'status': 'confirmed',
      'flight': {
        'id': 'f1',
        'airline': 'Vueling',
        'number': 'VY 1234',
        'originCode': 'CDG',
        'destinationCode': 'BCN',
        'departure': '08:30',
        'arrival': '10:45',
      },
      'hotel': {
        'id': 'h1',
        'name': 'Hotel Arts Barcelona',
        'neighborhood': 'Barceloneta',
        'nights': 3,
      },
      'flightPrice': 189.0,
      'hotelTotal': 960.0,
      'total': 1149.0,
      'pnr': 'VY-4821-BCN',
    },
  });
  await _d(400);

  // Confirmation message
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm3', 'role': 'assistant'});
  const msg =
      '🎉 **Booking confirmed!** Your Barcelona trip is all set.\n\n'
      '**PNR:** VY-4821-BCN\n'
      'Hotel Arts will send a pre-arrival email 48 hours before check-in. '
      'Have a wonderful trip! 🌊☀️';
  for (var i = 0; i < msg.length; i += 6) {
    await _d(50);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm3',
      'delta': msg.substring(i, (i + 6).clamp(0, msg.length)),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm3'});

  await _d(500);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'travel-th1',
    'runId': 'travel-run-2',
    'outcome': {'type': 'success'},
  });
}
