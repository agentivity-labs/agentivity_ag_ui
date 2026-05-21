import 'package:agentivity_ag_ui/agentivity_ag_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fake provider ─────────────────────────────────────────────────────────────

class FakeFormProvider implements IFormProvider {
  List<FormRequest> pendingRequests;
  bool submitShouldFail;
  int submitCallCount = 0;

  FakeFormProvider({
    this.pendingRequests = const [],
    this.submitShouldFail = false,
  });

  @override
  Future<List<FormRequest>> listPending({required String contextId, String? channel}) async {
    return pendingRequests;
  }

  @override
  Future<FormRequest> fetchRequest({required String contextId, required String requestId, String? channel}) async {
    return pendingRequests.firstWhere((r) => r.id == requestId);
  }

  @override
  Future<FormSubmitResult> submitResponse({
    required String contextId,
    required String requestId,
    required FormResponse response,
    String? channel,
  }) async {
    submitCallCount++;
    if (submitShouldFail) throw Exception('submit failed');
    return FormSubmitResult(
      status: 'ok',
      contextId: contextId,
      runId: 'run1',
      requestId: requestId,
    );
  }
}

FormRequest _makeRequest(String id) => FormRequest.fromJson({
      'id': id,
      'contextId': 'ctx1',
      'runId': 'run1',
      'nodeId': 'node1',
      'kind': 'input',
      'channelType': 'forms',
      'title': 'Request $id',
      'fields': <dynamic>[],
      'createdAt': '2024-01-01T00:00:00Z',
    });

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('FormController', () {
    late FakeFormProvider provider;
    late FormController ctrl;

    setUp(() {
      provider = FakeFormProvider(
        pendingRequests: [_makeRequest('r1'), _makeRequest('r2')],
      );
      ctrl = FormController(
        provider: provider,
        contextId: 'ctx1',
        channel: 'forms',
      );
    });

    tearDown(() => ctrl.dispose());

    test('initial state is empty and not loading', () {
      expect(ctrl.requests, isEmpty);
      expect(ctrl.isLoading, isFalse);
      expect(ctrl.errorMessage, isNull);
    });

    test('loadPending populates requests', () async {
      await ctrl.loadPending();
      expect(ctrl.requests, hasLength(2));
      expect(ctrl.requests.first.id, 'r1');
      expect(ctrl.isLoading, isFalse);
    });

    test('loadPending notifies listeners', () async {
      var notified = 0;
      ctrl.addListener(() => notified++);
      await ctrl.loadPending();
      expect(notified, greaterThan(0));
    });

    test('submitResponse removes request from list optimistically', () async {
      await ctrl.loadPending();
      final response = FormResponse(outcome: FormOutcome.submitted);
      await ctrl.submitResponse(request: ctrl.requests.first, response: response);
      expect(ctrl.requests, hasLength(1));
      expect(ctrl.requests.first.id, 'r2');
      expect(provider.submitCallCount, 1);
    });

    test('submitResponse re-adds request on failure', () async {
      provider.submitShouldFail = true;
      await ctrl.loadPending();
      final request = ctrl.requests.first;
      final response = FormResponse(outcome: FormOutcome.approved);

      expect(
        () => ctrl.submitResponse(request: request, response: response),
        throwsException,
      );
      await Future.delayed(Duration.zero);
      expect(ctrl.requests, hasLength(2));
    });

    test('clearError clears error message', () async {
      provider.submitShouldFail = true;
      await ctrl.loadPending();
      try {
        await ctrl.submitResponse(
          request: ctrl.requests.first,
          response: FormResponse(outcome: FormOutcome.submitted),
        );
      } catch (_) {}
      ctrl.clearError();
      expect(ctrl.errorMessage, isNull);
    });
  });
}
