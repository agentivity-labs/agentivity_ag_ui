# Technical Guide — agentivity_ag_ui

This document covers the full integration API: architecture, provider interfaces, controller API, widgets, theming, SSE streaming, generative UI, state sync, and Riverpod integration.

→ For an overview of what the package does and why, see [README.md](README.md).

---

## Architecture

The package is structured in three layers:

```
Your backend  ←──  Provider interface  (you implement)
                          │
                   Controller  (package — ChangeNotifier)
                          │
                     Widget  (package — Material)
```

Each feature area has its own provider interface, controller, and widget. You implement the interface; the package handles the rest.

| Feature | Interface | Controller | Widget |
|---|---|---|---|
| Chat | `IChatProvider` | `ChatController` | `AgUiChatPanel` |
| Human-in-the-loop | `IHilProvider` | `HilController` | `AgUiHilForm` |
| AI assistant | `IAiAssistantProvider` | `AiAssistantController` | `AgUiAssistantPanel` |
| Agent run | `IAgentRunProvider` | `AgentRunController` | `AgUiRunPanel` / `AgUiRunStatusBadge` |
| State sync | — | `AgUiStateController` | `AgUiStateBuilder` |
| Generative UI | — | `AgUiGenerativeController` | `AgUiGenerativeView` |

---

## Installation

```yaml
dependencies:
  agentivity_ag_ui: ^0.2.0
  dio: ^5.5.0   # required for SSE streaming; you can substitute any HTTP client
```

---

## Chat

### Interface

```dart
abstract class IChatProvider {
  Future<List<ChatThread>> listThreads({required String contextId});
  Future<ChatThread> fetchThread({required String contextId, required String threadId});
  Future<List<ChatMessage>> listMessages({required String contextId, required String threadId});
  Future<void> sendMessage({required String contextId, String? threadId, required String text});
}
```

### Controller

```dart
final ctrl = ChatController(
  provider: MyChatProvider(),
  contextId: 'workspace-1',
);

await ctrl.loadThreads();
await ctrl.openThread('thread-abc');
await ctrl.sendMessage('Hello');

ctrl.setSearchQuery('support');  // filters ctrl.threads
```

Key state: `ctrl.threads`, `ctrl.messages`, `ctrl.isLoading`, `ctrl.errorMessage`.

### Widget

```dart
AgUiChatPanel(
  controller: ctrl,
  threadId: 'thread-abc',
  // Optional overrides:
  messageBuilder: (msg) => MyBubble(message: msg),
  inputBuilder: (onSend) => MyInputRow(onSend: onSend),
)
```

---

## Human-in-the-Loop

### Interface

```dart
abstract class IHilProvider {
  Future<List<HilRequest>> listPending({required String contextId, String? channel});
  Future<HilRequest> fetchRequest({required String contextId, required String requestId, String? channel});
  Future<HilSubmitResult> submitResponse({
    required String contextId,
    required String requestId,
    required HilResponse response,
    String? channel,
  });
}
```

### Controller

```dart
final ctrl = HilController(
  provider: MyHilProvider(),
  contextId: 'workspace-1',
  channel: 'forms',   // discriminates approval channels
);

await ctrl.loadPending();
// ctrl.requests — List<HilRequest>
```

### Widget

```dart
AgUiHilForm(
  request: ctrl.requests.first,
  controller: ctrl,
  onSubmitted: () => setState(() {}),
  // Optional structural overrides:
  fieldBuilder: (field, onChange) => MyField(field: field, onChange: onChange),
  actionsBuilder: (request, onAct) => MyActions(onAct: onAct),
)
```

### AG-UI interrupt model

When a `RunFinishedEvent` arrives with an interrupt outcome, the package parses it into:

```dart
final ev = event as RunFinishedEvent;
if (ev.isInterrupted) {
  final outcome = ev.outcome as AgUiInterruptOutcome;
  for (final interrupt in outcome.interrupts) {
    print(interrupt.id);             // unique ID
    print(interrupt.reason);         // machine-readable reason
    print(interrupt.message);        // human-readable prompt
    print(interrupt.responseSchema); // JSON Schema for validation
    print(interrupt.expiresAt);      // optional deadline
  }
}
```

---

## AI Assistant

### Interface

```dart
abstract class IAiAssistantProvider {
  Future<AiAssistantHealth> checkHealth();
  Future<AiAssistantResult> send({
    required String message,
    List<Map<String, String>> history,
    Map<String, dynamic>? context,
  });
  Stream<AiAssistantChunk> stream({
    required String message,
    List<Map<String, String>> history,
    Map<String, dynamic>? context,
  });
}
```

### Widget

```dart
AgUiAssistantPanel(
  controller: AiAssistantController(provider: MyProvider()),
  inputHint: 'Ask me anything…',
  autoCheckHealth: true,    // pings checkHealth() on mount
  showStatusBar: true,      // shows online/offline + token count
)
```

---

## Agent Run

### Interface

```dart
abstract class IAgentRunProvider {
  Future<AgentRunStarted> startRun({required String agentId, required String input});
  Future<AgentRunStatus> fetchRun({required String agentId, required String runId});
  Future<List<AgentRunStatus>> listRuns({required String agentId});
  Future<void> cancelRun({required String agentId, required String runId});
  Stream<AgentRunStreamEvent> streamRun({required String runId});
  Future<List<AgentEntity>> listEntities({String? kind});
}
```

### Widget

```dart
AgUiRunPanel(controller: AgentRunController(
  provider: MyProvider(),
  agentId: 'my-agent',
))

// Compact badge for embedding in app bars, lists, etc.:
AgUiRunStatusBadge(controller: ctrl)
```

---

## AG-UI Protocol — SSE Streaming

### Low-level channel

```dart
final channel = AgUiSseChannel<AgUiEvent>(
  opener: (path, {lastEventId, cancelToken}) {
    return dio.get<ResponseBody>(
      path,
      options: Options(
        responseType: ResponseType.stream,
        headers: lastEventId != null ? {'Last-Event-ID': lastEventId} : null,
      ),
      cancelToken: cancelToken,
    ).then((r) => r.data!);
  },
  path: '/agent/stream',
  parser: agUiEventParser,
);

channel.events.listen((event) {
  switch (event) {
    case RunStartedEvent e:   print('started: ${e.runId}');
    case TextMessageContentEvent e: buffer.write(e.delta);
    case ToolCallStartEvent e: print('tool: ${e.toolCallName}');
    case RunFinishedEvent e:   handleOutcome(e.outcome);
    default: break;
  }
});
```

The channel reconnects automatically with exponential backoff (up to 60 s), tracks `Last-Event-ID` for resumption, and enforces a 45-second inactivity watchdog.

### Supported event types

| Event | Description |
|---|---|
| `RUN_STARTED` | Run begins (runId, threadId, parentRunId) |
| `RUN_FINISHED` | Run ends with success or interrupt outcome |
| `RUN_ERROR` | Run failed (message, optional code) |
| `STEP_STARTED` / `STEP_FINISHED` | Named step lifecycle |
| `TEXT_MESSAGE_START/CONTENT/END` | Streaming assistant text |
| `TEXT_MESSAGE_CHUNK` | Combined chunk (convenience) |
| `TOOL_CALL_START` | Agent begins a tool call |
| `TOOL_CALL_ARGS` / `TOOL_CALL_ARGS_DELTA` | Tool argument delta (both names accepted) |
| `TOOL_CALL_END` | Tool arguments complete |
| `TOOL_CALL_RESULT` | Backend returns the tool result |
| `TOOL_CALL_CHUNK` | Combined tool chunk (convenience) |
| `REASONING_MESSAGE_START/CONTENT/END` | Chain-of-thought reasoning |
| `STATE_SNAPSHOT` | Full state replacement |
| `STATE_DELTA` | RFC 6902 JSON Patch operations |
| `MESSAGES_SNAPSHOT` | Full message history replacement |
| `ACTIVITY_SNAPSHOT` / `ACTIVITY_DELTA` | Activity tracking |
| `CUSTOM` | Extension events (generative UI render, etc.) |
| `RAW` | Pass-through backend events |

---

## State Synchronisation

```dart
final ctrl = AgUiStateController(events: channel.events);

// Read state
ctrl.state;        // Map<String, dynamic>
ctrl['progress'];  // operator [] shorthand

// React to changes
AgUiStateBuilder(
  controller: ctrl,
  builder: (context, state) => ProgressBar(value: state['progress'] as double),
)
```

`STATE_DELTA` applies RFC 6902 JSON Patch operations: `add`, `remove`, `replace`, `move`, `copy`. Path escaping (`~0` for `~`, `~1` for `/`) and array append (`-`) are fully supported.

---

## Generative UI

The agent can decide at runtime which Flutter widget to render — no hardcoded if/else in your UI code.

### Widget registry

```dart
final registry = AgUiWidgetRegistry({
  'WeatherCard': (props) => WeatherCard(
    city: props['city'] as String,
    temp: (props['temp'] as num).toDouble(),
  ),
  'OrderSummary': (props) => OrderSummary.fromJson(props),
  'BookingForm': (props) => BookingForm(serviceId: props['serviceId'] as String),
});
```

### Controller + view

```dart
final ctrl = AgUiGenerativeController(
  events: channel.events,
  widgetRegistry: registry,      // tool name == component name → render widget
  toolRegistry: frontendTools,   // optional frontend tools (see below)
);

AgUiGenerativeView(
  controller: ctrl,
  registry: registry,
  fallbackBuilder: (name, props) => Text('Unknown: $name'),
)
```

The controller renders items in stream order: text bubbles → reasoning blocks → tool-call status cards → registered components. When a tool call ends and its name matches a registry key, the placeholder is replaced with the live widget.

### Frontend tools

Execute code on the device without a backend round-trip:

```dart
final tools = AgUiFrontendToolRegistry([
  AgUiFrontendTool(
    name: 'getLocation',
    description: 'Returns the user\'s current GPS coordinates.',
    parametersSchema: {
      'type': 'object',
      'properties': {'accuracy': {'type': 'string'}},
    },
    handler: (args) async {
      final pos = await Geolocator.getCurrentPosition();
      return {'lat': pos.latitude, 'lng': pos.longitude};
    },
  ),
]);

// Include these tools in your RunAgentInput so the backend knows about them:
final toolDescriptions = tools.toApiDescriptions();
```

### CUSTOM render events

The agent can also push components via CUSTOM events:

```json
{ "type": "CUSTOM", "name": "render", "value": { "component": "WeatherCard", "props": { "city": "Paris", "temp": 22 } } }
```

The controller handles `name == "render"` and `name == "ag-ui:render"` automatically.

---

## Theming

### Global (ThemeExtension)

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      AgUiChatTheme(
        userBubbleColor: Colors.blue.shade100,
        bubbleRadius: BorderRadius.circular(8),
        sendIconColor: Colors.blue,
      ),
      AgUiHilTheme(
        approveColor: Colors.green,
        rejectColor: Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      AgUiAssistantTheme(
        typingIndicatorColor: Colors.grey,
        onlineColor: Colors.green,
      ),
    ],
  ),
)
```

### Per-widget override

```dart
AgUiChatPanel(
  controller: ctrl,
  style: AgUiChatTheme(userBubbleColor: Colors.purple.shade100),
)
```

### Full structural override (builder callbacks)

```dart
AgUiChatPanel(
  controller: ctrl,
  messageBuilder: (msg) => MyCustomBubble(message: msg),
  inputBuilder: (onSend) => MyVoiceInputRow(onSend: onSend),
)

AgUiHilForm(
  request: request,
  controller: ctrl,
  fieldBuilder: (field, onChange) => MyField(field: field, onChange: onChange),
  actionsBuilder: (request, onAct) => MyActionsRow(onAct: onAct),
)
```

---

## Using with Riverpod

```dart
final chatControllerProvider = ChangeNotifierProvider<ChatController>((ref) {
  return ChatController(
    provider: ref.watch(myChatProviderProvider),
    contextId: ref.watch(workspaceIdProvider),
  );
});

// In your widget:
final ctrl = ref.watch(chatControllerProvider);
AgUiChatPanel(controller: ctrl, threadId: selectedThread);
```

The same pattern applies to all other controllers.

---

## RunAgentInput contract

When starting a run, send a spec-compliant payload:

```dart
final input = RunAgentInput(
  runId: uuid(),
  threadId: currentThreadId,
  messages: conversationHistory,
  tools: [
    ...frontendToolRegistry.toApiDescriptions(),
    ...backendToolSchemas,
  ],
  context: [
    {'description': 'Workspace ID', 'value': workspaceId},
  ],
  state: currentAgentState,
);
```

---

## Testing

The package ships with 150 unit tests covering protocol parsing, RFC 6902 JSON Patch operations, all controller lifecycles, and generative UI event handling. Run them with:

```sh
flutter test
```
