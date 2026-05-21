/// Signature for a tool that runs on the Flutter client.
typedef AgUiToolHandler = Future<dynamic> Function(Map<String, dynamic> args);

/// A tool that executes on the Flutter client (device/browser) rather than the backend.
///
/// Declare frontend tools in [AgUiFrontendToolRegistry] and pass the registry
/// to [AgUiGenerativeController]. The agent discovers them via
/// [AgUiFrontendToolRegistry.toApiDescriptions] included in `RunAgentInput.tools`.
class AgUiFrontendTool {
  const AgUiFrontendTool({
    required this.name,
    required this.description,
    this.parametersSchema,
    required this.handler,
  });

  /// Must match the tool name the agent uses in TOOL_CALL_START.toolCallName.
  final String name;
  final String description;

  /// JSON Schema object describing the expected `args` map.
  /// e.g. `{"type":"object","properties":{"query":{"type":"string"}}}`
  final Map<String, dynamic>? parametersSchema;

  final AgUiToolHandler handler;
}

/// Registry of [AgUiFrontendTool]s available to the agent during a run.
///
/// Pass the result of [toApiDescriptions] in your `RunAgentInput.tools` so the
/// agent knows which tools to route to the client.
class AgUiFrontendToolRegistry {
  AgUiFrontendToolRegistry(List<AgUiFrontendTool> tools)
      : _tools = {for (final t in tools) t.name: t};

  final Map<String, AgUiFrontendTool> _tools;

  List<AgUiFrontendTool> get tools => _tools.values.toList();

  bool has(String name) => _tools.containsKey(name);

  /// Execute a registered tool. Throws [ArgumentError] if [name] is unknown.
  Future<dynamic> execute(String name, Map<String, dynamic> args) {
    final tool = _tools[name];
    if (tool == null) throw ArgumentError('No frontend tool registered: "$name"');
    return tool.handler(args);
  }

  /// Returns tool descriptors formatted for `RunAgentInput.tools`.
  List<Map<String, dynamic>> toApiDescriptions() {
    return _tools.values.map((t) {
      return <String, dynamic>{
        'name': t.name,
        'description': t.description,
        if (t.parametersSchema != null) 'parameters': t.parametersSchema,
      };
    }).toList();
  }
}
