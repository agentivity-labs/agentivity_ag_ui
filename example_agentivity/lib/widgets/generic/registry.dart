/// Builds the [AgUiWidgetRegistry] that maps component names emitted by the
/// agent (via `CUSTOM ag-ui:render` events) to their Flutter widget builders.
///
/// Agent payload shape:
/// ```json
/// {
///   "type": "CUSTOM",
///   "name": "ag-ui:render",
///   "value": {
///     "component": "ChoiceWidget",
///     "props": { ... }
///   }
/// }
/// ```
///
/// Supported components:
/// | Name            | Widget                 | Response key(s)              |
/// |-----------------|------------------------|------------------------------|
/// | ChoiceWidget    | [AgChoiceWidget]       | `selected`                   |
/// | TextInputWidget | [AgTextInputWidget]    | `text`                       |
/// | DateWidget      | [AgDateWidget]         | `date` / `datetime` / range  |
/// | SliderWidget    | [AgSliderWidget]       | `value` / `min`+`max`        |
/// | ConfirmWidget   | [AgConfirmWidget]      | `confirmed`                  |
/// | TagWidget       | [AgTagWidget]          | `tags`                       |
/// | InfoCard        | [AgInfoCard]           | — (display only)             |
library;

import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';

import 'ag_choice_widget.dart';
import 'ag_confirm_widget.dart';
import 'ag_date_widget.dart';
import 'ag_info_card.dart';
import 'ag_slider_widget.dart';
import 'ag_tag_widget.dart';
import 'ag_text_input_widget.dart';

/// Returns a configured [AgUiWidgetRegistry] with all generic widgets
/// wired up. [onSubmit] is called when the user confirms any widget.
AgUiWidgetRegistry buildGenericRegistry({
  required void Function(String component, Map<String, dynamic> response)
      onSubmit,
}) {
  return AgUiWidgetRegistry({
    'ChoiceWidget': (_, props) => AgChoiceWidget(
          props: props,
          onSubmit: (r) => onSubmit('ChoiceWidget', r),
        ),
    'TextInputWidget': (_, props) => AgTextInputWidget(
          props: props,
          onSubmit: (r) => onSubmit('TextInputWidget', r),
        ),
    'DateWidget': (_, props) => AgDateWidget(
          props: props,
          onSubmit: (r) => onSubmit('DateWidget', r),
        ),
    'SliderWidget': (_, props) => AgSliderWidget(
          props: props,
          onSubmit: (r) => onSubmit('SliderWidget', r),
        ),
    'ConfirmWidget': (_, props) => AgConfirmWidget(
          props: props,
          onSubmit: (r) => onSubmit('ConfirmWidget', r),
        ),
    'TagWidget': (_, props) => AgTagWidget(
          props: props,
          onSubmit: (r) => onSubmit('TagWidget', r),
        ),
    'InfoCard': (_, props) => AgInfoCard(props: props),
  });
}
