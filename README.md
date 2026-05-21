# agentivity_ag_ui

<!-- pub.dev badge appears once the package is published -->
[![pub.dev](https://img.shields.io/pub/v/agentivity_ag_ui.svg)](https://pub.dev/packages/agentivity_ag_ui)
[![CI](https://github.com/agentivity-labs/agentivity_ag_ui/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/agentivity-labs/agentivity_ag_ui/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**The Flutter SDK for building AI agent interfaces — powered by the [AG-UI open protocol](https://github.com/ag-ui-protocol/ag-ui).**

Ship real-time AI chat, human-in-the-loop approvals, generative UI, and agent monitoring in your Flutter app — in minutes, not weeks.

<br>

<p align="center">
  <img src="https://raw.githubusercontent.com/agentivity-labs/agentivity_ag_ui/master/docs/screenshots/travel_dark.png"    width="30%" alt="AI Trip Planner — generative flight &amp; hotel cards"/>
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/agentivity-labs/agentivity_ag_ui/master/docs/screenshots/support_light.png"  width="30%" alt="AI Customer Support — ticket tracking + escalation HIL"/>
  &nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/agentivity-labs/agentivity_ag_ui/master/docs/screenshots/widgets_light.png"  width="30%" alt="Generic Agentivity client — widget vocabulary"/>
</p>

<p align="center">
  <sub>
    Left: <strong>AI Trip Planner</strong> — generative FlightCard + HotelCard, booking confirmation HIL &nbsp;·&nbsp;
    Center: <strong>AI Customer Support</strong> — live ticket bar, escalation approval &nbsp;·&nbsp;
    Right: <strong>Generic client</strong> — 7 reusable agent-driven widgets
  </sub>
</p>

---

## What is AG-UI?

[AG-UI](https://github.com/ag-ui-protocol/ag-ui) is an open, lightweight, event-based protocol that standardizes how AI agents connect to user-facing applications. Think of it as the missing link between your AI backend (LangGraph, Agentivity.io, CrewAI, Claude, GPT-4…) and your frontend — a universal contract for streaming tokens, tool calls, state updates, and human-in-the-loop interactions.

AG-UI sits alongside MCP (agent ↔ tools) and A2A (agent ↔ agent): it handles the third piece — **agent ↔ user**.

> *"Bring agents into frontend applications."* — ag-ui-protocol/ag-ui

**agentivity_ag_ui** is the Flutter implementation of this protocol. It gives you everything you need to build production-grade agentic UIs on iOS, Android, and Web — without reinventing the wheel.

### Agent-driven UI vs traditional UI

In a conventional app every UI state transition is hardcoded:

```dart
// Traditional — developer decides the flow at compile time
if (results.isNotEmpty) showProductList(results.take(3));
```

With AG-UI the **agent decides at runtime** — which components to render, when
to pause and ask for human input, how to update shared state. Your Flutter code
stays thin and declarative; the intelligence lives in the agent:

```
Your Agent (backend)       agentivity_ag_ui              Your Flutter UI
──────────────────────  ───────────────────────────  ──────────────────────
REASONING_MESSAGE_*  →  AgUiReasoningItem          →  Collapsible "Thinking…"
TEXT_MESSAGE_*       →  AgUiTextItem (streaming)   →  Chat bubble
TOOL_CALL_*          →  AgUiToolCallItem            →  Status card
CUSTOM ag-ui:render  →  Resolve "ProductCard"      →  YOUR widget
STATE_DELTA          →  RFC 6902 JSON Patch         →  CartBar re-renders
RUN_FINISHED(int.)   →  isInterrupted = true        →  YOUR bottom sheet
```

The library handles the left and middle columns. You own the right column.

---

## Why agentivity_ag_ui?

Building an AI agent UI from scratch is harder than it looks. You need to handle:

- **Streaming tokens** that arrive one character at a time, mid-sentence
- **Tool calls** that pause the conversation while the agent does work
- **State diffs** (JSON Patch) synchronised in real-time between backend and UI
- **Interruptions** where the agent asks a human to approve, fill a form, or make a decision
- **Reconnections** when the SSE stream drops — without losing context
- **Reasoning traces** you may want to show (or hide) to your users
- **Generative UI** where the agent itself decides which components to render

**agentivity_ag_ui handles all of this.** You focus on your product; the protocol plumbing is done.

---

## What you get

### 💬 AI Chat — out of the box
Drop `AgUiChatPanel` into your widget tree. Streaming messages, typing indicators, thread history — fully themed with `AgUiChatTheme`.

### ✅ Human-in-the-Loop — approvals & forms
When your agent needs a human decision, `AgUiHilForm` renders the right form automatically — approval cards, multi-field inputs, dropdowns, checkboxes. Built on the AG-UI interrupt protocol.

### 🤖 AI Assistant Panel
A contextual assistant widget with health monitoring, streaming responses, and conversation history. Plug in any backend — OpenAI, Anthropic, your own endpoint.

### 📡 Agent Run Monitoring
Track long-running agent jobs in real time: step progress, tool activations, final outcome, error states. `AgUiRunPanel` gives your users live visibility into what the agent is doing.

### 🔄 Live State Synchronisation
Your agent's state — task progress, intermediate results, shared context — stays in sync via RFC 6902 JSON Patch. `AgUiStateController` applies delta updates reactively.

### 🎨 Generative UI
The most powerful feature: let your agent decide what to render. Register Flutter widgets in `AgUiWidgetRegistry`; the agent calls them by name, passing props. Cards, charts, forms, booking flows — generated on the fly, rendered natively.

---

## Examples

### `example/` — 9 step-by-step screens

Open one concept at a time, each self-contained and fully offline:

| Step | Concept |
|------|---------|
| 1 | SSE connection — raw event log |
| 2 | Streaming text — live chat bubbles |
| 3 | Tool calls — pending → running → completed cards |
| 4 | Generative UI — `AgUiWidgetRegistry`, two injection paths |
| 5 | Reasoning blocks — collapsible chain-of-thought |
| 6 | State sync — JSON Patch applied in real time |
| 7 | HIL forms — approval cards and dynamic inputs |
| 8 | Interrupts & resume — `ResumePayload` flow |
| 9 | Full stack — all four controllers on one broadcast stream |

```bash
cd example && flutter run
```

### `example_shopping/` — AI Shopping Assistant (marketing demo)

A polished dark-themed demo that runs a complete agent interaction
automatically when you open it. No backend, no API keys. Shows the full
AG-UI feature set in one coherent product experience:

- Reasoning block → tool calls → streaming text → generative product cards
- Agent-controlled `STATE_DELTA` updates an animated cart bar
- `RUN_FINISHED` with interrupt → bottom sheet → user picks a product → resume

```bash
cd example_shopping && flutter run
```

[Full walkthrough →](example_shopping/README.md)

---

## Get started in your own app

```yaml
# pubspec.yaml
dependencies:
  agentivity_ag_ui: ^0.2.0
  dio: ^5.5.0
```

```dart
// 1. Implement one interface for your backend
class MyAssistantProvider implements IAssistantProvider {
  @override
  Stream<AssistantChunk> stream({required String message, ...}) { ... }
}

// 2. Wire it to a controller
final ctrl = AssistantController(provider: MyAssistantProvider());

// 3. Drop the widget
AgUiAssistantPanel(controller: ctrl)
```

That's it. [See the full integration guide →](TECHNICAL.md)

---

## Connecting to a backend

Three ready-made connectors ship with the library. Each returns a `Stream<AgUiEvent>` you can feed directly into any controller.

### Any AG-UI-native backend

Use `AgUiGenericConnector` for any backend that already emits AG-UI events over SSE (FastAPI + ag-ui adapter, Express, your own endpoint, etc.):

```dart
final connector = AgUiGenericConnector(
  baseUrl: 'https://my-backend.example.com',
  headers: {'Authorization': 'Bearer $token'},
);

final broadcast = connector.run(
  path: '/api/agent',
  input: RunAgentInput(
    threadId: 'thread-1',
    runId: 'run-1',
    messages: [buildAgUiMessage('user', text: 'Find me an espresso machine')],
  ),
).asBroadcastStream();

_lifecycle = AgUiRunLifecycleController(events: broadcast);
_gen       = AgUiGenerativeController(events: broadcast);
```

### Agentivity

`AgentivityConnector` targets the [Agentivity](https://agentivity.io) platform. Run a single agent, an entire agent team, resume after an interrupt, or cancel:

```dart
final connector = AgentivityConnector(
  apiKey: 'ag_live_...',
  organizationId: 'org_...',  // optional
);

// Single agent
final stream = connector.runAgent(
  agentId: 'product-search',
  input: RunAgentInput(threadId: 't1', runId: 'r1', messages: [...]),
);

// Team of agents
final stream = connector.runTeam(
  teamId: 'shopping-team',
  input: RunAgentInput(threadId: 't2', runId: 'r2', messages: [...]),
);

// Resume after RUN_FINISHED with interrupt
final stream = connector.resumeAgent(
  agentId: 'product-search',
  input: RunAgentInput(
    threadId: 't1',
    runId: 'r3',
    messages: previousMessages,
    resume: [
      ResumePayload(
        interruptId: interrupt.id,
        status: ResumeStatus.resolved,
        response: {'choice': 'p2'},
      ),
    ],
  ),
);

// Cancel
await connector.cancel(runId: 'r2');
```

### LangGraph

`LangGraphConnector` targets LangGraph Cloud and self-hosted LangGraph deployments. Your graph must use the [ag-ui Python adapter](https://github.com/ag-ui-protocol/ag-ui) so it emits AG-UI events:

```python
# server.py  (Python backend)
from ag_ui.langgraph import add_agui_route
add_agui_route(app, my_graph, path="/agent")
```

```dart
// Flutter
final connector = LangGraphConnector(
  deploymentUrl: 'https://my-graph.langchain.app',
  apiKey: 'lsv2_pt_...',
  assistantId: 'my-assistant',
);

// Optional: let LangGraph manage the thread
final threadId = await connector.createThread();

final stream = connector.run(
  input: RunAgentInput(
    threadId: threadId,
    runId: uuid.v4(),
    messages: [buildAgUiMessage('user', text: 'Plan my trip to Lisbon')],
  ),
);
```

---

## Backend-agnostic by design

agentivity_ag_ui has **zero opinion** on your backend stack. It speaks AG-UI events over SSE — if your server emits them, you're done. Tested with:

- **LangGraph** (Python / JS) via `LangGraphConnector` or generic connector
- **CrewAI** — expose an AG-UI SSE endpoint, use `AgUiGenericConnector`
- **Agentivity** via `AgentivityConnector`
- **Custom FastAPI / Express / any SSE endpoint** via `AgUiGenericConnector`
- **Anthropic Claude Agent SDK**

The provider interfaces (`IChatProvider`, `IHilProvider`, `IAiAssistantProvider`, `IAgentRunProvider`) are thin abstractions — implement them in an afternoon.

---

## Works with your state management

Controllers are plain `ChangeNotifier`. They compose naturally with whatever you already use:

| Library | How |
|---|---|
| **Riverpod** | `ChangeNotifierProvider` |
| **Provider** | `ChangeNotifierProvider` |
| **BLoC** | Wrap as a `Cubit` |
| **GetX** | Wrap as a `GetxController` |
| **Raw Flutter** | `ListenableBuilder` |

---

## Theme it your way

Every widget respects your existing `ThemeData` — no style overrides needed for a coherent look. Go further with `ThemeExtension` for global branding, per-widget `style` for local tweaks, or full `builder` callbacks to replace any component structurally.

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      AgUiChatTheme(userBubbleColor: Colors.blue.shade100),
      AgUiHilTheme(approveColor: Colors.green),
    ],
  ),
)
```

---

## Built on open standards

| Standard | Used for |
|---|---|
| [AG-UI Protocol](https://github.com/ag-ui-protocol/ag-ui) | Event contract between agent and UI |
| [RFC 8895](https://www.rfc-editor.org/rfc/rfc8895) | Server-Sent Events framing |
| [RFC 6902](https://www.rfc-editor.org/rfc/rfc6902) | JSON Patch for state delta updates |

---

## Contributing

Issues and PRs are welcome. For major changes, open an issue first to align on direction.

Built and maintained by [Agentivity](https://agentivity.io) — the platform for AI agent orchestration and monitoring.

---

## License

[MIT](LICENSE) © Agentivity
