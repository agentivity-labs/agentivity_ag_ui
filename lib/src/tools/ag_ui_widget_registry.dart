import 'package:flutter/widgets.dart';

/// Builds a Flutter widget from a [BuildContext] and a props map.
///
/// Follows the Flutter [WidgetBuilder] convention — [context] is the
/// [BuildContext] at the rendering site, giving access to [Theme],
/// [MediaQuery], inherited widgets, and any app-level providers.
typedef AgUiComponentBuilder = Widget Function(
  BuildContext context,
  Map<String, dynamic> props,
);

/// Maps component names to widget builders for generative UI.
///
/// The agent "renders" a component by calling a tool whose name matches a key
/// in this registry, or by emitting a CUSTOM `render` event. The registry
/// resolves the name to a Flutter widget at runtime.
///
/// The [BuildContext] passed to each builder is the context of the
/// [AgUiGenerativeView] that hosts the item, so inherited widgets
/// (Theme, Localizations, custom providers) are all accessible.
///
/// ```dart
/// final registry = AgUiWidgetRegistry({
///   'WeatherCard': (context, props) => WeatherCard(
///     city: props['city'] as String,
///     temp: (props['temp'] as num).toDouble(),
///     unit: Localizations.localeOf(context).countryCode == 'US' ? '°F' : '°C',
///   ),
///   'OrderSummary': (context, props) => OrderSummary.fromJson(props),
/// });
/// ```
class AgUiWidgetRegistry {
  const AgUiWidgetRegistry(Map<String, AgUiComponentBuilder> builders)
      : _builders = builders;

  final Map<String, AgUiComponentBuilder> _builders;

  /// Builds the widget for [component] using [context] and [props],
  /// or returns `null` if the component name is not registered.
  Widget? build(
    BuildContext context,
    String component,
    Map<String, dynamic> props,
  ) =>
      _builders[component]?.call(context, props);

  bool has(String component) => _builders.containsKey(component);

  Iterable<String> get components => _builders.keys;
}
