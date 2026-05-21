# Changelog

## 0.2.0

**Generative UI, protocol alignment, state sync, and frontend tools.**

### New capabilities

- **Generative UI** — `AgUiGenerativeController` processes `Stream<AgUiEvent>` and maintains a sealed `AgUiGenerativeItem` list (`AgUiTextItem`, `AgUiReasoningItem`, `AgUiComponentItem`, `AgUiToolCallItem`). `AgUiGenerativeView` renders it reactively with streaming indicators, collapsible reasoning blocks, and tool-call status cards.
- **Widget registry** — `AgUiWidgetRegistry` maps component names to Flutter widget builders. The agent calls a tool whose name matches a registered component → the controller seamlessly replaces the placeholder with the live widget. Also supported via `CUSTOM` events with `name == 'render'`.
- **Frontend tools** — `AgUiFrontendToolRegistry` / `AgUiFrontendTool` let the agent call client-side code (no backend round-trip). Results are shown inline. Use `toApiDescriptions()` to include frontend tools in the agent's tool list.
- **State sync** — `AgUiStateController` applies `STATE_SNAPSHOT` and `STATE_DELTA` (RFC 6902 JSON Patch: add, remove, replace, move, copy) to a reactive state map. `AgUiStateBuilder` provides a `ListenableBuilder` wrapper.

### Protocol alignment (breaking if you used internal names)

- `ToolCallStartEvent`: JSON key changed from `toolName` → `toolCallName` (legacy `toolName` still read as fallback).
- `ToolCallArgsDeltaEvent`: now handles both spec name `TOOL_CALL_ARGS` and legacy `TOOL_CALL_ARGS_DELTA`.
- `ToolCallResultEvent`: field renamed `result` → `content` (legacy `result` read as fallback); `messageId` is now a required `String`.
- `RunStartedEvent`: added `threadId`, `parentRunId`.
- `RunFinishedEvent`: added `threadId`, `outcome` (`AgUiSuccessOutcome` or `AgUiInterruptOutcome` with `List<AgUiInterrupt>`). `isInterrupted` convenience getter.
- Added event types: `TextMessageChunkEvent`, `ToolCallChunkEvent`, `ReasoningMessageStartEvent`, `ReasoningMessageContentEvent`, `ReasoningMessageEndEvent`, `ReasoningStartEvent`, `ReasoningEndEvent`, `ActivitySnapshotEvent`, `ActivityDeltaEvent`, `RawEvent`.
- `StateDeltaEvent.delta` is now typed `List<dynamic>` (RFC 6902 patch array).

### Tests

- 150 unit tests covering protocol parsing, JSON Patch operations (including `~0`/`~1` escaping and `-` array append), generative controller event handling, and controller notification behaviour.

---

## 0.1.0

Initial release.

- **AG-UI protocol** — sealed `AgUiEvent` hierarchy covering all standard event types (run lifecycle, text messages, tool calls, state, custom). Ready-made `agUiEventParser` for use with `AgUiSseChannel`.
- **SSE channel** — `AgUiSseChannel<T>` with RFC 8895 frame parsing, exponential backoff reconnection, Last-Event-ID tracking, and a 45-second watchdog timer.
- **Abstract provider interfaces** — `IChatProvider`, `IHilProvider`, `IAiAssistantProvider`, `IAgentRunProvider`. Implement against your backend; the package stays backend-agnostic.
- **ChangeNotifier controllers** — `ChatController`, `HilController`, `AiAssistantController`, `AgentRunController`. Drop into any Flutter state management setup (Riverpod, Provider, BLoC, raw `ListenableBuilder`).
- **Flutter widgets** — `AgUiChatPanel`, `AgUiHilForm`, `AgUiAssistantPanel`, `AgUiRunPanel`, `AgUiRunStatusBadge`.
- **ThemeExtension styling** — `AgUiChatTheme`, `AgUiHilTheme`, `AgUiAssistantTheme` integrate with your existing `ThemeData`. Each widget also accepts a per-instance `style` override and builder callbacks for full structural replacement.
