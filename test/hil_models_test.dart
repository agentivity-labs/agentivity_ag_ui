import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormRequestKind.fromApi', () {
    test('known values', () {
      expect(FormRequestKind.fromApi('approval'), FormRequestKind.approval);
      expect(FormRequestKind.fromApi('choice'), FormRequestKind.choice);
      expect(FormRequestKind.fromApi('notification'), FormRequestKind.notification);
      expect(FormRequestKind.fromApi('input'), FormRequestKind.input);
    });

    test('case-insensitive', () {
      expect(FormRequestKind.fromApi('APPROVAL'), FormRequestKind.approval);
    });

    test('unknown defaults to input', () {
      expect(FormRequestKind.fromApi('unknown'), FormRequestKind.input);
    });
  });

  group('FormFieldType.fromApi', () {
    test('known values', () {
      expect(FormFieldType.fromApi('text'), FormFieldType.text);
      expect(FormFieldType.fromApi('multilineText'), FormFieldType.multilineText);
      expect(FormFieldType.fromApi('number'), FormFieldType.number);
      expect(FormFieldType.fromApi('boolean'), FormFieldType.boolean);
      expect(FormFieldType.fromApi('bool'), FormFieldType.boolean);
      expect(FormFieldType.fromApi('choice'), FormFieldType.choice);
      expect(FormFieldType.fromApi('date'), FormFieldType.date);
      expect(FormFieldType.fromApi('file'), FormFieldType.file);
    });

    test('unknown defaults to text', () {
      expect(FormFieldType.fromApi('unknown'), FormFieldType.text);
    });
  });

  group('FormOutcome.toApi', () {
    test('all values', () {
      expect(FormOutcome.submitted.toApi(), 'Submitted');
      expect(FormOutcome.approved.toApi(), 'Approved');
      expect(FormOutcome.rejected.toApi(), 'Rejected');
      expect(FormOutcome.revised.toApi(), 'Revised');
      expect(FormOutcome.timedOut.toApi(), 'TimedOut');
      expect(FormOutcome.cancelled.toApi(), 'Cancelled');
    });
  });

  group('AgFormField.fromJson', () {
    test('parses basic text field', () {
      final f = AgFormField.fromJson({
        'name': 'username',
        'label': 'Username',
        'type': 'text',
        'required': true,
        'hint': 'Enter your username',
      });
      expect(f.name, 'username');
      expect(f.label, 'Username');
      expect(f.type, FormFieldType.text);
      expect(f.isRequired, isTrue);
      expect(f.hint, 'Enter your username');
    });

    test('parses choice field with options', () {
      final f = AgFormField.fromJson({
        'name': 'color',
        'label': 'Color',
        'type': 'choice',
        'required': false,
        'options': ['red', 'green', 'blue'],
      });
      expect(f.type, FormFieldType.choice);
      expect(f.options, ['red', 'green', 'blue']);
    });

    test('toJson round-trips', () {
      final f = AgFormField.fromJson({
        'name': 'n',
        'label': 'N',
        'type': 'number',
        'required': false,
        'hint': 'hint',
        'defaultValue': 42,
      });
      final json = f.toJson();
      expect(json['name'], 'n');
      expect(json['type'], 'number');
      expect(json['defaultValue'], 42);
    });
  });

  group('FormRequest.fromJson', () {
    final baseJson = {
      'id': 'req1',
      'contextId': 'ctx1',
      'runId': 'run1',
      'nodeId': 'node1',
      'kind': 'approval',
      'channelType': 'approvals',
      'title': 'Approve PR',
      'description': 'Please review',
      'fields': <dynamic>[],
      'createdAt': '2024-06-01T10:00:00Z',
    };

    test('parses core fields', () {
      final r = FormRequest.fromJson(baseJson);
      expect(r.id, 'req1');
      expect(r.kind, FormRequestKind.approval);
      expect(r.channel, 'approvals');
      expect(r.title, 'Approve PR');
      expect(r.description, 'Please review');
      expect(r.fields, isEmpty);
    });

    test('parses nested fields', () {
      final r = FormRequest.fromJson({
        ...baseJson,
        'fields': [
          {'name': 'reason', 'label': 'Reason', 'type': 'text', 'required': false},
        ],
      });
      expect(r.fields, hasLength(1));
      expect(r.fields.first.name, 'reason');
    });

    test('effectiveContextId returns contextId when present', () {
      final r = FormRequest.fromJson(baseJson);
      expect(r.effectiveContextId, 'ctx1');
    });

    test('effectiveContextId falls back to runId', () {
      final r = FormRequest.fromJson({...baseJson, 'contextId': ''});
      expect(r.effectiveContextId, 'run1');
    });
  });

  group('FormResponse.toJson', () {
    test('includes outcome and data', () {
      final resp = FormResponse(
        outcome: FormOutcome.approved,
        data: {'reason': 'LGTM'},
      );
      final json = resp.toJson();
      expect(json['outcome'], 'Approved');
      expect(json['data'], {'reason': 'LGTM'});
    });

    test('omits null optional fields', () {
      final resp = FormResponse(outcome: FormOutcome.submitted);
      final json = resp.toJson();
      expect(json.containsKey('data'), isFalse);
      expect(json.containsKey('respondedBy'), isFalse);
    });
  });
}
