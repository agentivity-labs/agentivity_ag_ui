/// Scripted AG-UI event stream driving the AI Customer Support demo.
///
/// A customer reports a delayed order. The agent looks it up, checks policy,
/// decides to escalate, asks for approval (HIL interrupt), then confirms.
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';

AgUiEvent _e(Map<String, dynamic> json) => AgUiEvent.fromJson(json);
Future<void> _d(int ms) => Future.delayed(Duration(milliseconds: ms));

// ── Phase 1: analysis & escalation decision ───────────────────────────────────

Stream<AgUiEvent> buildDemoStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'support-th1', 'runId': 'support-run-1'});

  // Initial ticket state
  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {
      'caseId': 'SR-2024-4821',
      'status': 'open',
      'category': 'Order Delay',
      'priority': null,
      'eta': null,
      'agentName': 'Aria',
    },
  });

  // ── Activity: looking up order ─────────────────────────────────────────────
  await _d(600);
  yield _e({
    'type': 'ACTIVITY_SNAPSHOT',
    'messageId': 'act1',
    'activityType': 'lookup',
    'content': {
      'label': 'Looking up order #4821…',
      'description': 'Fetching order history and carrier status',
      'progress': 0.12,
    },
  });

  // ── Reasoning ─────────────────────────────────────────────────────────────
  await _d(700);
  yield _e({'type': 'REASONING_MESSAGE_START', 'messageId': 'think1', 'role': 'assistant'});
  const thought =
      'Order #4821 shipped May 2nd via DHL. Today is May 21st — 19 days. '
      'Standard delivery is 5–7 business days. This is 12 business days overdue. '
      'Policy: escalate to Level 2 when delay exceeds 10 business days. '
      'I should retrieve carrier details, then request escalation approval.';
  for (var i = 0; i < thought.length; i += 8) {
    await _d(48);
    yield _e({
      'type': 'REASONING_MESSAGE_CONTENT',
      'messageId': 'think1',
      'delta': thought.substring(i, (i + 8).clamp(0, thought.length)),
    });
  }
  yield _e({'type': 'REASONING_MESSAGE_END', 'messageId': 'think1'});

  // ── Step: order lookup ────────────────────────────────────────────────────
  await _d(400);
  yield _e({'type': 'STEP_STARTED', 'stepName': 'order_lookup'});

  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc-order',
    'toolCallName': 'lookup_order',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc-order',
    'delta': '{"orderId": "4821", "customerId": "c-7742"}',
  });
  await _d(1200);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc-order'});
  await _d(150);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc-order',
    'content': '{"status":"in_transit_delayed","carrier":"DHL","trackingCode":"DHL-882-BCN","shipped":"2024-05-02","estimated":"2024-05-09","business_days_late":12}',
  });
  yield _e({'type': 'STEP_FINISHED', 'stepName': 'order_lookup'});

  // ── Step: policy check ────────────────────────────────────────────────────
  await _d(300);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Checking escalation policy…'},
      {'op': 'replace', 'path': '/progress', 'value': 0.55},
    ],
  });
  yield _e({'type': 'STEP_STARTED', 'stepName': 'policy_check'});

  yield _e({
    'type': 'TOOL_CALL_START',
    'toolCallId': 'tc-policy',
    'toolCallName': 'check_sla_policy',
  });
  yield _e({
    'type': 'TOOL_CALL_ARGS',
    'toolCallId': 'tc-policy',
    'delta': '{"delay_business_days": 12, "carrier": "DHL", "order_value_eur": 189}',
  });
  await _d(900);
  yield _e({'type': 'TOOL_CALL_END', 'toolCallId': 'tc-policy'});
  await _d(150);
  yield _e({
    'type': 'TOOL_CALL_RESULT',
    'toolCallId': 'tc-policy',
    'content': '{"escalation_required":true,"threshold_days":10,"compensation":"€15 voucher eligible","level":"L2_priority"}',
  });
  yield _e({'type': 'STEP_FINISHED', 'stepName': 'policy_check'});

  // ── Activity: drafting response ────────────────────────────────────────────
  await _d(400);
  yield _e({
    'type': 'ACTIVITY_DELTA',
    'messageId': 'act1',
    'patch': [
      {'op': 'replace', 'path': '/label', 'value': 'Preparing response…'},
      {'op': 'replace', 'path': '/description', 'value': 'Escalation criteria met — requesting approval'},
      {'op': 'replace', 'path': '/progress', 'value': 0.9},
    ],
  });

  // ── Agent text response ────────────────────────────────────────────────────
  await _d(600);
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm1', 'role': 'assistant'});
  const response =
      "I'm sorry to hear your order hasn't arrived, and I completely "
      "understand your frustration. I've located order **#4821** — it was "
      "dispatched via DHL on May 2nd and is currently showing *in transit "
      "(delayed)* with a tracking reference of **DHL-882-BCN**.\n\n"
      "This delay is 12 business days beyond our standard delivery window. "
      "Our policy requires escalation to Priority Level 2 support for delays "
      "exceeding 10 business days. I'm requesting authorisation to escalate "
      "your case right now.";
  for (var i = 0; i < response.length; i += 6) {
    await _d(42);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm1',
      'delta': response.substring(i, (i + 6).clamp(0, response.length)),
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

  // ── Interrupt: escalation approval ────────────────────────────────────────
  await _d(700);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'support-th1',
    'runId': 'support-run-1',
    'outcome': {
      'type': 'interrupt',
      'interrupts': [
        {
          'id': 'escalate-approval',
          'reason': 'supervisor_approval',
          'message': 'Authorise Priority Level 2 escalation for case SR-2024-4821?',
        },
      ],
    },
  });
}

// ── Phase 2: resume after escalation approval ─────────────────────────────────

Stream<AgUiEvent> buildResumeStream() async* {
  yield _e({'type': 'RUN_STARTED', 'threadId': 'support-th1', 'runId': 'support-run-2'});
  await _d(500);

  // Update ticket state
  yield _e({
    'type': 'STATE_SNAPSHOT',
    'snapshot': {
      'caseId': 'SR-2024-4821',
      'status': 'escalated',
      'category': 'Order Delay',
      'priority': 'P1',
      'eta': '2 hours',
      'agentName': 'Aria',
      'escalatedAt': '14:32',
    },
  });
  await _d(400);

  // Confirmation message
  yield _e({'type': 'TEXT_MESSAGE_START', 'messageId': 'm2', 'role': 'assistant'});
  const msg =
      '✅ **Escalation authorised.** Your case has been escalated to our '
      'Priority Support team (Level 2).\n\n'
      '**What happens next:**\n'
      '• A senior agent will contact you within **2 hours**\n'
      '• You\'ll also receive a **€15 voucher** for the inconvenience\n'
      '• Tracking code: DHL-882-BCN — we\'ve opened a carrier investigation\n\n'
      'Case reference: **SR-2024-4821**. Is there anything else I can help you with?';
  for (var i = 0; i < msg.length; i += 6) {
    await _d(45);
    yield _e({
      'type': 'TEXT_MESSAGE_CONTENT',
      'messageId': 'm2',
      'delta': msg.substring(i, (i + 6).clamp(0, msg.length)),
    });
  }
  yield _e({'type': 'TEXT_MESSAGE_END', 'messageId': 'm2'});

  await _d(400);
  yield _e({
    'type': 'RUN_FINISHED',
    'threadId': 'support-th1',
    'runId': 'support-run-2',
    'outcome': {'type': 'success'},
  });
}
