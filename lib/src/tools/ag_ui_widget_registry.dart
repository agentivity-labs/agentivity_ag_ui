import 'package:flutter/widgets.dart';

/// Builds a Flutter widget from a component name and its props map.
typedef AgUiComponentBuilder = Widget Function(Map<String, dynamic> props);

/// Maps component names to widget builders for generative UI.
///
/// The agent "renders" a component by calling a tool whose name matches a key
/// in this registry, or by emitting a CUSTOM `render` event. The registry
/// resolves the name to a Flutter widget at runtime.
///
/// ```dart
/// final registry = AgUiWidgetRegistry({
///   'WeatherCard': (props) => WeatherCard(
///     city: props['city'] as String,
///     temp: (props['temp'] as num).toDouble(),
///   ),
///   'OrderSummary': (props) => OrderSummary.fromJson(props),
/// });
/// ```
class AgUiWidgetRegistry {
  const AgUiWidgetRegistry(Map<String, AgUiComponentBuilder> builders)
      : _builders = builders;

  final Map<String, AgUiComponentBuilder> _builders;

  /// Returns the widget for [component], or `null` if not registered.
  Widget? build(String component, Map<String, dynamic> props) =>
      _builders[component]?.call(props);

  bool has(String component) => _builders.containsKey(component);

  Iterable<String> get components => _builders.keys;
}
