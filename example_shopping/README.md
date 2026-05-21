# AI Shopping Assistant Demo

> A fully self-contained Flutter demo that showcases every major feature of
> **agentivity_ag_ui** in a single, polished dark-themed screen — no backend
> required.

---

## What does this demo actually do?

When you open the app the AI agent **auto-plays a scripted run**. Watch it:

| Step | What you see | AG-UI feature |
|------|-------------|---------------|
| 1 | A progress bar appears: *"Scanning your preferences…"* | `ACTIVITY_SNAPSHOT` |
| 2 | A collapsible **"Thinking…"** chip streams in | `REASONING_MESSAGE_*` |
| 3 | Two **tool-call cards** animate through *pending → running → completed* | `TOOL_CALL_START/END/RESULT` |
| 4 | Assistant text streams in word by word | `TEXT_MESSAGE_*` |
| 5 | Three **product cards** pop in, one by one | `CUSTOM ag-ui:render` |
| 6 | A call-to-action text streams in | `TEXT_MESSAGE_*` |
| 7 | A purple **"Tap to choose"** banner slides up | `RUN_FINISHED` with interrupt |
| 8 | A bottom sheet lists the 3 products — you tap one | Human-in-the-loop |
| 9 | The **cart bar bounces** at the bottom with the item and total | `STATE_DELTA` → `AgUiStateController` |
| 10 | A confirmation message streams in | Resume run |

Hit the **↺ replay** button in the top-right to run it again.

---

## Do I still need to build the UI myself?

**Yes — and that's the whole point.**

The library does **not** ship domain-specific widgets. There is no `ProductCard`
in the package, just as there is no `DoctorAppointmentCard`,
`FlightResultCard`, or `InvoiceLineItem`. Those are *your* design, your brand.

What the library gives you is the **plumbing between the agent and your
widgets**:

```
Your Agent (backend)          agentivity_ag_ui              Your Flutter UI
─────────────────────    ──────────────────────────    ──────────────────────
Emit SSE events          Parse & route every event     Render what the agent
                         Reconnect on drop              decided to show
TOOL_CALL_START      →   AgUiToolCallItem (card)    →  ToolCallCard (built-in)
TEXT_MESSAGE_*       →   AgUiTextItem               →  Chat bubble (built-in)
CUSTOM ag-ui:render  →   Look up "ProductCard"      →  YOUR ProductCard widget
STATE_DELTA          →   Apply JSON Patch            →  YOUR CartBar re-renders
RUN_FINISHED(int.)   →   isInterrupted = true       →  YOUR bottom sheet
```

You register **one line per component** in `AgUiWidgetRegistry`:

```dart
final registry = AgUiWidgetRegistry({
  'ProductCard': (props) => ShoppingProductCard(
    product: productById(jsonStr(props, 'id'))!,
    onAddToCart: () => _showPicker(),
  ),
});
```

From that point on, every time the agent emits:

```json
{ "type": "CUSTOM", "name": "ag-ui:render",
  "value": { "component": "ProductCard", "props": { "id": "p2" } } }
```

…your `ShoppingProductCard` widget appears in the conversation — with exactly
the data the agent chose, at exactly the moment the agent decided to show it.

**The agent controls the when and what. You control the how it looks.**

---

## Why is this more than a regular app?

In a conventional app, the UI flow is **hardcoded**:

```
// Traditional approach — you decide everything at compile time
if (searchResults.length > 0) {
  showProductList(searchResults.take(3).toList());
}
```

With agentivity_ag_ui, the agent decides at **runtime**:

- Show 3 products, or 1, or a comparison table, or a bundle offer — whatever
  its reasoning concluded was best for *this* user at *this* moment.
- Interrupt the flow to ask for approval before proceeding.
- Update the cart state atomically via JSON Patch without a page reload.
- Stream its reasoning so users understand *why* they're seeing what they see.
- Retry gracefully if the SSE connection drops mid-sentence.

None of that logic lives in your Flutter code. It lives in the agent. Your UI
stays thin and declarative; the agent stays in control of the experience.

---

## Code map

```
example_shopping/
├── lib/
│   ├── main.dart                    # Dark theme, app entry point
│   ├── data/
│   │   ├── products.dart            # ShoppingProduct model + kProducts list
│   │   └── demo_stream.dart         # Scripted AG-UI event sequences
│   │       ├── buildDemoStream()    # Phase 1: discovery → interrupt
│   │       └── buildResumeStream()  # Phase 2: cart update → confirmation
│   ├── screens/
│   │   └── home_screen.dart         # All 4 controllers wired in parallel
│   └── widgets/
│       ├── product_card.dart        # ShoppingProductCard (YOUR widget)
│       └── cart_bar.dart            # AnimatedCartBar (YOUR widget)
```

### `demo_stream.dart` — the scripted agent

The demo has no live backend. `buildDemoStream()` is an `async*` generator
that yields `AgUiEvent` objects with realistic delays, producing exactly the
same event sequence a real LangGraph or CrewAI agent would emit.

This is how you develop and test your UI before your backend is ready.

### `home_screen.dart` — four controllers, one stream

```dart
// One broadcast stream feeds all four controllers simultaneously.
// Each controller handles only the events it cares about.
final broadcast = buildDemoStream().asBroadcastStream();

_lifecycle = AgUiRunLifecycleController(events: broadcast); // RUN_* STEP_*
_activity  = AgUiActivityController(events: broadcast);     // ACTIVITY_*
_stateCtrl = AgUiStateController(events: broadcast);        // STATE_*
_genCtrl   = AgUiGenerativeController(events: broadcast);   // TEXT_* TOOL_* CUSTOM
```

The cart bar reads from `_stateCtrl.state['itemCount']` and
`_stateCtrl.state['total']`. When the agent emits a `STATE_DELTA` after the
user picks a product, the JSON Patch is applied and the cart bar re-renders —
without any manual state management code.

### `product_card.dart` — your widget, agent's data

`ShoppingProductCard` is a plain Flutter widget. It does not know about
`AgUiGenerativeController` or any AG-UI type. It receives a `ShoppingProduct`
and an `onAddToCart` callback, exactly like any other widget in your app.

The binding happens **only** inside the `AgUiWidgetRegistry` closure in
`home_screen.dart`. That's the seam between the agent world and your UI world.

---

## Running the demo

```bash
cd example_shopping
flutter pub get
flutter run
```

No API keys, no backend, no environment variables needed.

---

## Adapting this to your product

| What to change | Where |
|----------------|-------|
| Your own widgets | Replace `ShoppingProductCard` / `CartBar` with your own |
| Real backend SSE | Replace `buildDemoStream()` with `AgUiSseChannel` pointed at your endpoint |
| Your product data | Replace `kProducts` / `productById()` with your own model |
| Your state shape | The `STATE_SNAPSHOT` / `STATE_DELTA` keys are yours to define |
| Interrupt handling | Swap the bottom sheet for your own approval UI |

The controllers, the protocol, the streaming, the reconnection, the JSON Patch
— all of that stays exactly as-is.

---

## Further reading

- [`example/`](../example) — 9 step-by-step screens, one concept per step
- [Main library README](../README.md) — full feature list and architecture
- [AG-UI protocol spec](https://github.com/ag-ui-protocol/ag-ui)
