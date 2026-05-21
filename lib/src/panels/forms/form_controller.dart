import 'package:flutter/foundation.dart';

import '../../protocol/api_contract.dart';
import 'form_models.dart';
import 'i_form_provider.dart';

class FormController extends ChangeNotifier {
  FormController({
    required IFormProvider provider,
    required String contextId,
    this.channel,
  })  : _provider = provider,
        _contextId = contextId;

  final IFormProvider _provider;
  final String _contextId;

  /// Optional channel discriminator (e.g. "forms", "approvals").
  final String? channel;

  List<FormRequest> _requests = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeRequestId;

  List<FormRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get activeRequestId => _activeRequestId;
  bool get hasPending => _requests.isNotEmpty;

  Future<void> loadPending({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _requests = await _provider.listPending(
          contextId: _contextId, channel: channel);
      _activeRequestId = null;
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'FormController.loadPending');
      _errorMessage = userFacingErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FormRequest> fetchRequest({required String requestId}) {
    return _provider.fetchRequest(
        contextId: _contextId, requestId: requestId, channel: channel);
  }

  Future<void> submitResponse({
    required FormRequest request,
    required FormResponse response,
  }) async {
    _activeRequestId = request.id;
    _errorMessage = null;
    notifyListeners();
    try {
      await _provider.submitResponse(
        contextId: _contextId,
        requestId: request.id,
        response: response,
        channel: channel ?? request.channel,
      );
      _requests =
          _requests.where((r) => r.id != request.id).toList(growable: false);
    } on Object catch (e) {
      debugLogApiIssue(e, operation: 'FormController.submitResponse');
      _errorMessage = userFacingErrorMessage(e);
      rethrow;
    } finally {
      _activeRequestId = null;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
