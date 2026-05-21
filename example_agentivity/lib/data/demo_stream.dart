/// Scripted AG-UI event stream for the generic Agentivity demo.
///
/// Simulates a multi-step onboarding questionnaire powered by the full
/// generic widget vocabulary.
///
/// Phase 1 – discovery questions (ChoiceWidget, TextInputWidget, DateWidget, SliderWidget).
/// Phase 2 – resume after first batch; final steps (TagWidget, ConfirmWidget, success InfoCard).
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';

AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);
Future<void> _d(int ms) => Future.delayed(Duration(milliseconds: ms));

/// Streams [text] character by character at ~40 ms / char.
Stream<AgUiEvent> _streamText(String messageId, String text) async* {
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': messageId, 'role': 'assistant'});
  for (var i = 0; i < text.length; i += 5) {
    await _d(40);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': messageId,
      'delta': text.substring(i, (i + 5).clamp(0, text.length)),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': messageId});
}

// ── Phase 1: discovery ────────────────────────────────────────────────────────

Stream<AgUiEvent> buildDemoStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'demo-th1', 'runId': 'demo-run-1'});

  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {'phase': 'discovery', 'step': 0},
  });

  // ── Activity ───────────────────────────────────────────────────────────────
  await _d(300);
  yield _e({
    'type': 'ACTIVITY_SNAPSHOT',
    'messageId': 'act1',
    'activityType': 'thinking',
    'content': {
      'label': 'Preparing your session…',
      'description': 'Setting up personalised questions',
      'progress': 0.1,
    },
  });

  // ── Greeting ───────────────────────────────────────────────────────────────
  await _d(500);
  yield* _streamText(
    'm1',
    '👋 Welcome to **Agentivity**! I\'m going to ask you a few quick questions '
    'to tailor your experience. Every answer you give is reflected back '
    'instantly — just select, type, or slide.',
  );

  await _d(300);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/progress', 'value': 0.3},
    ],
  });

  // ── InfoCard: what to expect ───────────────────────────────────────────────
  await _d(400);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'InfoCard',
      'props': {
        'title': 'What to expect',
        'message':
            'Four quick questions: your goal, a short introduction, '
            'your availability and your budget. Takes less than 2 minutes.',
        'variant': 'info',
      },
    },
  });

  // ── Step 1: ChoiceWidget ───────────────────────────────────────────────────
  await _d(700);
  yield* _streamText('m2', 'First, tell me — **what brings you here today?**');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'ChoiceWidget',
      'props': {
        'title': 'Your main goal',
        'subtitle': 'Pick the option that fits best',
        'options': [
          '🚀  Launch a new product',
          '🤝  Connect with an expert agent',
          '📊  Analyse my data',
          '💡  Just exploring',
        ],
        'multiSelect': false,
      },
    },
  });

  // ── Step 2: TextInputWidget ────────────────────────────────────────────────
  await _d(900);
  yield* _streamText('m3', 'Great! Now **tell me a bit about your project** in your own words.');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'TextInputWidget',
      'props': {
        'title': 'Project description',
        'subtitle': 'A sentence or two is plenty',
        'placeholder': "e.g. \"We're building a Flutter app that…\"",
        'multiline': true,
        'maxLength': 300,
        'validate': 'none',
      },
    },
  });

  // ── Step 3: DateWidget ─────────────────────────────────────────────────────
  await _d(900);
  yield* _streamText('m4', 'When are you **available to kick off**?');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'DateWidget',
      'props': {
        'title': 'Availability window',
        'subtitle': 'Choose your preferred start and end dates',
        'mode': 'range',
        'minDate': '2025-06-01',
        'maxDate': '2026-12-31',
        'initialDate': '2025-07-01',
      },
    },
  });

  // ── Step 4: SliderWidget ───────────────────────────────────────────────────
  await _d(900);
  yield* _streamText('m5', 'And finally — what **monthly budget** are you comfortable with?');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'SliderWidget',
      'props': {
        'title': 'Monthly budget',
        'subtitle': 'Slide to your comfort zone',
        'min': 0,
        'max': 5000,
        'step': 250,
        'initial': 1000,
        'unit': ' €',
        'range': false,
      },
    },
  });

  // ── Activity: done first phase ─────────────────────────────────────────────
  await _d(600);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Awaiting your answers…'},
      {'op': 'replace', 'path': '/description', 'value': 'Complete the 4 cards above'},
      {'op': 'replace', 'path': '/progress', 'value': 0.5},
    ],
  });

  // ── Interrupt: wait for user responses ────────────────────────────────────
  await _d(500);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'demo-th1',
    'runId': 'demo-run-1',
    'outcome': {
      'type': 'interrupt',
      'interrupts': [
        {
          'id': 'collect-answers',
          'reason': 'user_input',
          'message': 'Please complete the four question cards above.',
        },
      ],
    },
  });
}

// ── Phase 2: finalise profile ─────────────────────────────────────────────────

Stream<AgUiEvent> buildResumeStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'demo-th1', 'runId': 'demo-run-2'});

  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {'phase': 'finalise', 'step': 1},
  });

  await _d(400);
  yield _e({
    'type': 'ACTIVITY_SNAPSHOT',
    'messageId': 'act2',
    'activityType': 'processing',
    'content': {
      'label': 'Analysing your answers…',
      'description': 'Building your personalised profile',
      'progress': 0.2,
    },
  });

  // ── Transition text ────────────────────────────────────────────────────────
  await _d(600);
  yield* _streamText(
    'm6',
    '✅ Got it! Two last things to lock in your profile.',
  );

  // ── Step 5: TagWidget ──────────────────────────────────────────────────────
  await _d(500);
  yield* _streamText('m7', 'Which **technologies or topics** matter most to you?');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'TagWidget',
      'props': {
        'title': 'Topics of interest',
        'subtitle': 'Add up to 6 tags — type or pick a suggestion',
        'placeholder': 'e.g. Flutter, AI, Rust…',
        'suggestions': ['Flutter', 'AI / LLM', 'Dart', 'Firebase', 'Node.js', 'Python'],
        'maxTags': 6,
        'minTags': 1,
      },
    },
  });

  await _d(800);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act2',
    'patch': [
      {'op': 'replace', 'path': '/progress', 'value': 0.65},
    ],
  });

  // ── Step 6: ConfirmWidget ──────────────────────────────────────────────────
  await _d(600);
  yield* _streamText('m8', 'Ready to **save your profile** and get started?');
  await _d(300);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'ConfirmWidget',
      'props': {
        'title': 'Confirm your profile',
        'subtitle': 'Your answers will be sent to the Agentivity team',
        'message':
            'Once confirmed, your personalised agent session will begin immediately. '
            'You can update your preferences at any time.',
        'confirmLabel': 'Yes, let\'s go!',
        'cancelLabel': 'Not yet',
        'variant': 'success',
      },
    },
  });

  await _d(600);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act2',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Almost done…'},
      {'op': 'replace', 'path': '/progress', 'value': 0.9},
    ],
  });

  // ── Final success InfoCard ─────────────────────────────────────────────────
  await _d(800);
  yield _e({
    'type': 'CUSTOM',
    'name': 'ag-ui:render',
    'value': {
      'component': 'InfoCard',
      'props': {
        'title': 'Profile ready 🎉',
        'message':
            'Your personalised Agentivity session is configured. '
            'Connect a live agent or explore more widgets in the registry.',
        'variant': 'success',
      },
    },
  });

  // ── Closing message ────────────────────────────────────────────────────────
  await _d(400);
  yield* _streamText(
    'm9',
    'All done! This demo showcased **7 generic widgets**: '
    'InfoCard, ChoiceWidget, TextInputWidget, DateWidget, '
    'SliderWidget, TagWidget and ConfirmWidget. '
    'Any Agentivity agent can render them by name — no extra code needed. 🚀',
  );

  await _d(300);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act2',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Session complete'},
      {'op': 'replace', 'path': '/progress', 'value': 1.0},
    ],
  });

  // ── Done ───────────────────────────────────────────────────────────────────
  await _d(400);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'demo-th1',
    'runId': 'demo-run-2',
    'outcome': {'type': 'success'},
  });
}
