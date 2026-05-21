import 'dart:convert';

import '../../shared/json_helpers.dart';

enum FormRequestKind {
  input,
  approval,
  choice,
  notification;

  factory FormRequestKind.fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'approval':
        return FormRequestKind.approval;
      case 'choice':
        return FormRequestKind.choice;
      case 'notification':
        return FormRequestKind.notification;
      default:
        return FormRequestKind.input;
    }
  }
}

enum FormFieldType {
  text,
  multilineText,
  number,
  boolean,
  choice,
  date,
  file;

  factory FormFieldType.fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'multilinetext':
        return FormFieldType.multilineText;
      case 'number':
        return FormFieldType.number;
      case 'boolean':
      case 'bool':
        return FormFieldType.boolean;
      case 'choice':
        return FormFieldType.choice;
      case 'date':
        return FormFieldType.date;
      case 'file':
        return FormFieldType.file;
      default:
        return FormFieldType.text;
    }
  }
}

enum FormOutcome {
  submitted,
  approved,
  rejected,
  revised,
  timedOut,
  cancelled;

  String toApi() {
    switch (this) {
      case FormOutcome.submitted:
        return 'Submitted';
      case FormOutcome.approved:
        return 'Approved';
      case FormOutcome.rejected:
        return 'Rejected';
      case FormOutcome.revised:
        return 'Revised';
      case FormOutcome.timedOut:
        return 'TimedOut';
      case FormOutcome.cancelled:
        return 'Cancelled';
    }
  }
}

/// Descriptor for a single form field.
///
/// Named [AgFormField] to avoid conflict with Flutter's [FormField] widget.
class AgFormField {
  const AgFormField({
    required this.name,
    required this.label,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.hint,
    this.options,
  });

  final String name;
  final String label;
  final FormFieldType type;
  final bool isRequired;
  final dynamic defaultValue;
  final String? hint;
  final List<String>? options;

  factory AgFormField.fromJson(Map<String, dynamic> json) {
    final rawOptions = jsonLookup(json, 'options');
    List<String>? options;
    if (rawOptions is List) options = rawOptions.map((e) => '$e').toList();
    return AgFormField(
      name: jsonStr(json, 'name'),
      label: jsonStr(json, 'label'),
      type: FormFieldType.fromApi(jsonStr(json, 'type')),
      isRequired: jsonLookup(json, 'required') == true,
      defaultValue: jsonLookup(json, 'defaultValue'),
      hint: jsonOpt(json, 'hint'),
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'label': label,
      'type': type.name,
      'required': isRequired,
      if (hint != null && hint!.isNotEmpty) 'hint': hint,
      if (options != null && options!.isNotEmpty) 'options': options,
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }
}

class FormRequest {
  const FormRequest({
    required this.id,
    required this.contextId,
    required this.runId,
    required this.nodeId,
    required this.kind,
    required this.channel,
    required this.title,
    required this.fields,
    required this.createdAt,
    this.description,
    this.message,
    this.query,
    this.metadata,
    this.timeout,
    this.respondent,
  });

  final String id;
  final String contextId;
  final String runId;
  final String nodeId;
  final FormRequestKind kind;

  /// Channel discriminator (e.g. "forms", "approvals", "chat").
  final String channel;

  final String title;
  final String? description;
  final String? message;
  final String? query;
  final Map<String, dynamic>? metadata;
  final List<AgFormField> fields;
  final int? timeout;
  final DateTime createdAt;
  final String? respondent;

  String get effectiveContextId =>
      contextId.trim().isNotEmpty ? contextId : runId;

  int? get remainingSeconds {
    if (timeout == null) return null;
    final deadline = createdAt.add(Duration(minutes: timeout!));
    final remaining = deadline.difference(DateTime.now().toUtc()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  factory FormRequest.fromJson(Map<String, dynamic> json) {
    final rawFields = jsonLookup(json, 'fields');
    List<dynamic>? fieldsList;
    if (rawFields is List) {
      fieldsList = rawFields;
    } else if (rawFields is String && rawFields.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawFields);
        if (decoded is List) fieldsList = decoded;
      } catch (_) {}
    }
    final fields = <AgFormField>[];
    for (final e in fieldsList ?? []) {
      if (e is Map<String, dynamic>) {
        fields.add(AgFormField.fromJson(e));
      } else if (e is Map) {
        fields.add(AgFormField.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return FormRequest(
      id: jsonStr(json, 'id'),
      contextId: jsonStr(json, 'contextId'),
      runId: jsonStr(json, 'runId'),
      nodeId: jsonStr(json, 'nodeId'),
      kind: FormRequestKind.fromApi(jsonStr(json, 'kind')),
      channel: jsonStr(json, 'channelType'),
      title: jsonStr(json, 'title'),
      description: jsonOpt(json, 'description'),
      message: jsonOpt(json, 'message'),
      query: jsonOpt(json, 'query'),
      metadata: jsonMap(json, 'metadata'),
      fields: fields,
      timeout: jsonInt(json, 'timeout'),
      createdAt: jsonDateTime(json, 'createdAt') ?? DateTime.now().toUtc(),
      respondent: jsonOpt(json, 'respondent'),
    );
  }
}

class FormResponse {
  const FormResponse({
    required this.outcome,
    this.data,
    this.metadata,
    this.channel,
    this.respondedBy,
    this.responseText,
  });

  final FormOutcome outcome;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? metadata;
  final String? channel;
  final String? respondedBy;
  final String? responseText;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'outcome': outcome.toApi(),
      if (data != null) 'data': data,
      if (metadata != null) 'metadata': metadata,
      if (channel != null) 'channel': channel,
      if (respondedBy != null) 'respondedBy': respondedBy,
      if (responseText != null) 'responseText': responseText,
    };
  }
}

class FormSubmitResult {
  const FormSubmitResult({
    required this.status,
    required this.contextId,
    required this.runId,
    required this.requestId,
  });

  final String status;
  final String contextId;
  final String runId;
  final String requestId;

  factory FormSubmitResult.fromJson(Map<String, dynamic> json) {
    return FormSubmitResult(
      status: jsonStr(json, 'status'),
      contextId: jsonStr(json, 'contextId'),
      runId: jsonStr(json, 'runId'),
      requestId: jsonStr(json, 'requestId'),
    );
  }
}
