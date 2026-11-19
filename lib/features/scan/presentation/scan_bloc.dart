import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/gallery_repository.dart';
import '../domain/prediction_repository.dart';
import '../domain/scan_photo.dart';

sealed class ScanEvent {
  const ScanEvent();
}

final class PickGalleryPhoto extends ScanEvent {
  const PickGalleryPhoto();
}

final class AnalyzePhoto extends ScanEvent {
  const AnalyzePhoto();
}

enum ScanStatus { idle, picking, ready, analyzing, success, failure }

class ScanState {
  const ScanState(
    this.status, {
    this.photo,
    this.prediction,
    this.errorMessage,
  });

  final ScanStatus status;
  final Uint8List? photo;
  final ScanPrediction? prediction;
  final String? errorMessage;

  bool get isBusy =>
      status == ScanStatus.picking || status == ScanStatus.analyzing;
}

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc(this._gallery, this._scanPhoto)
    : super(const ScanState(ScanStatus.idle)) {
    on<PickGalleryPhoto>(_pickPhoto);
    on<AnalyzePhoto>(_analyzePhoto);
  }

  final GalleryRepository _gallery;
  final ScanPhoto _scanPhoto;

  Future<void> _pickPhoto(
    PickGalleryPhoto event,
    Emitter<ScanState> emit,
  ) async {
    if (state.isBusy) return;

    final previous = state;
    emit(ScanState(ScanStatus.picking, photo: previous.photo));
    try {
      final photo = await _gallery.pickPhoto();
      emit(photo == null ? previous : ScanState(ScanStatus.ready, photo: photo));
    } on Exception {
      emit(
        ScanState(
          ScanStatus.failure,
          photo: previous.photo,
          errorMessage: 'Foto tidak dapat dibaca. Coba pilih foto lain.',
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
      emit(ScanState(ScanStatus.success, photo: photo, prediction: prediction));
    } on Exception {
      emit(
        ScanState(
          ScanStatus.failure,
          photo: photo,
          errorMessage: 'Analisis gagal. Silakan coba lagi.',
        ),
      );
    }
  }
}
