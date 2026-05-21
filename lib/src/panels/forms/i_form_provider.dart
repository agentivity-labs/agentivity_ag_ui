import 'form_models.dart';

/// Generic form provider — implement this against any backend.
///
/// [channel] is an optional discriminator for backends that expose multiple
/// form channels (e.g. "forms", "approvals"). Pass `null` for the default channel.
abstract interface class IFormProvider {
  Future<List<FormRequest>> listPending({required String contextId, String? channel});
  Future<FormRequest> fetchRequest({required String contextId, required String requestId, String? channel});
  Future<FormSubmitResult> submitResponse({
    required String contextId,
    required String requestId,
    required FormResponse response,
    String? channel,
  });
}
