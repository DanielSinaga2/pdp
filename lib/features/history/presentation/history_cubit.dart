import 'package:flutter_bloc/flutter_bloc.dart';

import '../../knowledge/domain/condition_label.dart';
import '../domain/history_repository.dart';

class HistoryState {
  const HistoryState({
    this.entries = const [],
    this.filter,
    this.busy = false,
    this.error,
  });

  final List<HistoryEntry> entries;
  final ConditionLabel? filter;
  final bool busy;
  final String? error;
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository) : super(const HistoryState());

  final HistoryRepository _repository;

  Future<void> load({ConditionLabel? filter}) async {
    if (state.busy || isClosed) return;
    emit(HistoryState(filter: filter, busy: true));
    try {
      final entries = await _repository.list(label: filter);
      if (!isClosed) emit(HistoryState(entries: entries, filter: filter));
    } catch (_) {
      if (!isClosed) {
        emit(HistoryState(
          filter: filter,
          error: 'Riwayat gagal dimuat. Silakan coba lagi.',
        ));
      }
    }
  }

  Future<void> delete(int id) async {
    if (state.busy || isClosed) return;
    final previous = state;
    emit(HistoryState(entries: previous.entries, filter: previous.filter, busy: true));
    try {
      await _repository.delete(id);
      if (!isClosed) {
        emit(HistoryState(
          entries: previous.entries.where((entry) => entry.id != id).toList(),
          filter: previous.filter,
        ));
      }
    } catch (_) {
      if (!isClosed) {
        emit(HistoryState(
          entries: previous.entries,
          filter: previous.filter,
          error: 'Catatan gagal dihapus. Silakan coba lagi.',
        ));
      }
    }
  }
}
