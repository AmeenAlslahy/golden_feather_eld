import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/log_repository_providers.dart';
import '../providers/logs_provider.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/daily_form_update.dart';
import '../../../../core/error/user_facing_message.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

class FormTabState {
  final bool isLoading;
  const FormTabState({this.isLoading = false});
}

class FormTabController extends StateNotifier<FormTabState> {
  final Ref _ref;
  final DailyLog _log;

  FormTabController(this._ref, this._log) : super(const FormTabState());

  Future<String?> saveForm({
    required DailyFormUpdate update,
    required AppLocalizations loc,
    required void Function(String) onSuccess,
    required void Function(String) onOffline,
  }) async {
    state = const FormTabState(isLoading: true);
    
    final result = await _ref.read(logRepositoryProvider).saveForm(
      logId: _log.id,
      form: update,
    );
    
    if (!mounted) return null;
    state = const FormTabState(isLoading: false);
    
    return result.fold(
      (error) => anyErrorUserMessage(error, loc: loc),
      (saveResult) {
        if (saveResult.isOffline) {
          onOffline(loc.formSavedOffline);
          return null;
        }

        final read = saveResult.syncedData!;
        if (read.complete != null) {
          _ref.read(logsProvider.notifier).updateLog(
            _log.copyWith(
              isFormComplete: read.complete,
              formStatus: read.complete! ? FormStatus.completed : FormStatus.incomplete,
            ),
          );
        }
        
        final msg = read.message ?? (read.complete == true ? loc.successMessage : read.complete == false ? loc.serverSavedFormIncomplete : loc.serverSavedFormNoStatus);
        onSuccess(msg);
        return null;
      }
    );
  }
}

final formTabControllerProvider = StateNotifierProvider.autoDispose.family<FormTabController, FormTabState, DailyLog>((ref, log) {
  return FormTabController(ref, log);
});
