library agentivity_ag_ui;

// json helpers — for use in widget registry builders
export 'src/shared/json_helpers.dart';

// protocol
export 'src/protocol/ag_ui_sse_channel.dart';
export 'src/protocol/ag_ui_protocol.dart';
export 'src/protocol/ag_ui_state_controller.dart';
export 'src/protocol/api_contract.dart';
export 'src/protocol/run_agent_input.dart';

// tools
export 'src/tools/ag_ui_frontend_tool.dart';
export 'src/tools/ag_ui_widget_registry.dart';

// widgets
export 'src/widgets/ag_ui_markdown_body.dart';

// panels — chat
export 'src/panels/chat/chat_models.dart';
export 'src/panels/chat/chat_controller.dart';
export 'src/panels/chat/i_chat_provider.dart';
export 'src/panels/chat/chat_theme.dart';
export 'src/panels/chat/ag_ui_chat_panel.dart';

// panels — assistant
export 'src/panels/assistant/assistant_models.dart';
export 'src/panels/assistant/assistant_controller.dart';
export 'src/panels/assistant/i_assistant_provider.dart';
export 'src/panels/assistant/assistant_theme.dart';
export 'src/panels/assistant/ag_ui_assistant_panel.dart';

// panels — forms
export 'src/panels/forms/form_models.dart';
export 'src/panels/forms/form_controller.dart';
export 'src/panels/forms/i_form_provider.dart';
export 'src/panels/forms/form_theme.dart';
export 'src/panels/forms/ag_ui_form_panel.dart';

// agent
export 'src/agent/agent_run_models.dart';
export 'src/agent/agent_run_controller.dart';
export 'src/agent/i_agent_run_provider.dart';
export 'src/agent/ag_ui_run_status.dart';
export 'src/agent/ag_ui_generative_controller.dart';
export 'src/agent/ag_ui_generative_view.dart';
export 'src/agent/ag_ui_run_lifecycle_controller.dart';
export 'src/agent/ag_ui_activity_controller.dart';
export 'src/agent/ag_ui_context_registry.dart';

// connectors — pre-built backends
export 'src/connectors/ag_ui_generic_connector.dart';
export 'src/connectors/agentivity_connector.dart';
export 'src/connectors/lang_graph_connector.dart';
