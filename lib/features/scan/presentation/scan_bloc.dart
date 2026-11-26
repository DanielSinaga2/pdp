import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../history/domain/history_repository.dart';
import '../domain/photo_repository.dart';
import '../domain/prediction_repository.dart';
import '../domain/rice_photo_screening.dart';
import '../domain/scan_photo.dart';

sealed class ScanEvent {
  const ScanEvent();
}

final class PickPhoto extends ScanEvent {
  const PickPhoto(this.source);

  final PhotoSource source;
}

final class RecoverPickerPhoto extends ScanEvent {
  const RecoverPickerPhoto();
}

final class AnalyzePhoto extends ScanEvent {
  const AnalyzePhoto();
}

enum ScanStatus { idle, picking, recovering, ready, analyzing, success, failure }

class ScanState {
  const ScanState(
    this.status, {
    this.photo,
    this.prediction,
    this.errorMessage,
    this.historySaveFailed = false,
  });

  final ScanStatus status;
  final Uint8List? photo;
  final ScanPrediction? prediction;
  final String? errorMessage;
  final bool historySaveFailed;

  bool get isBusy =>
      status == ScanStatus.picking ||
      status == ScanStatus.recovering ||
      status == ScanStatus.analyzing;
}

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc(this._photos, this._scanPhoto, this._history)
    : super(const ScanState(ScanStatus.idle)) {
    on<PickPhoto>(_pickPhoto);
    on<RecoverPickerPhoto>(_recoverPhoto);
    on<AnalyzePhoto>(_analyzePhoto);
  }

  final PhotoRepository _photos;
  final ScanPhoto _scanPhoto;
  final HistoryRepository _history;

  Future<void> _pickPhoto(PickPhoto event, Emitter<ScanState> emit) {
    return _loadPhoto(
      emit,
      status: ScanStatus.picking,
      load: () => _photos.pickPhoto(event.source),
      failureMessage: switch (event.source) {
        PhotoSource.camera => 'Kamera gagal mengambil foto. Silakan coba lagi.',
        PhotoSource.gallery => 'Galeri gagal dibuka. Silakan coba lagi.',
      },
    );
  }

  Future<void> _recoverPhoto(
    RecoverPickerPhoto event,
    Emitter<ScanState> emit,
  ) {
    return _loadPhoto(
      emit,
      status: ScanStatus.recovering,
      load: _photos.recoverPhoto,
      failureMessage: 'Foto sebelumnya gagal dipulihkan. Silakan pilih ulang.',
    );
  }

  Future<void> _loadPhoto(
    Emitter<ScanState> emit, {
    required ScanStatus status,
    required Future<Uint8List?> Function() load,
    required String failureMessage,
  }) async {
    if (state.isBusy) return;

    final previous = state;
    emit(ScanState(status, photo: previous.photo));
    try {
      final photo = await load();
      emit(photo == null ? previous : ScanState(ScanStatus.ready, photo: photo));
    } on Exception catch (error) {
      emit(
        ScanState(
          ScanStatus.failure,
          photo: previous.photo,
          errorMessage: error is FormatException
              ? 'Foto tidak dapat dibaca. Coba pilih foto lain.'
              : failureMessage,
        ),
      );
    }
  }

  Future<void> _analyzePhoto(AnalyzePhoto event, Emitter<ScanState> emit) async {
    final photo = state.photo;
    if (photo == null || state.isBusy) return;

    emit(ScanState(ScanStatus.analyzing, photo: photo));
    try {
      final prediction = await _scanPhoto(photo);
      var historySaveFailed = false;
      try {
        await _history.save(
          label: prediction.label,
          confidence: prediction.confidence,
          scannedAt: DateTime.now(),
          isSimulated: prediction.isSimulated,
          photo: photo,
        );
      } catch (_) {
        historySaveFailed = true;
      }

      emit(ScanState(
        ScanStatus.success,
        photo: photo,
        prediction: prediction,
        historySaveFailed: historySaveFailed,
      ));
    } on Exception catch (error) {
      emit(
        ScanState(
          ScanStatus.failure,
          photo: photo,
          errorMessage: error is UnsuitableRicePhoto
              ? 'Foto belum bisa dianalisis. Pilih foto daun padi yang terlihat jelas.'
              : 'Analisis gagal. Silakan coba lagi.',
        ),
      );
    }
  }
}
