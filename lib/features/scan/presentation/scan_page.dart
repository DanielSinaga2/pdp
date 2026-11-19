import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../knowledge/domain/disease_detail_repository.dart';
import '../domain/photo_repository.dart';
import 'scan_bloc.dart';
import 'scan_result_page.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key, required this.details});

  final DiseaseDetailRepository details;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanBloc, ScanState>(
      listenWhen: (previous, current) =>
          previous.status == ScanStatus.analyzing &&
          current.status == ScanStatus.success,
      listener: (context, state) {
        final photo = state.photo;
        final prediction = state.prediction;
        if (photo == null || prediction == null) return;

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ScanResultPage(
              photo: photo,
              prediction: prediction,
              detail: details.getDetail(prediction.label),
            ),
          ),
        );
      },
      builder: (context, state) {
        final bloc = context.read<ScanBloc>();
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final photo = state.photo;

        return Scaffold(
          appBar: AppBar(title: const Text('PadiSehat')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  children: [
                    Text('Scan daun padi', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Ambil foto daun padi atau pilih foto dari galeri.',
                    ),
                    const SizedBox(height: 24),
                    if (photo == null)
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.photo_outlined,
                          size: 56,
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      ScanPhotoPreview(photo: photo),
                    const SizedBox(height: 20),
                    if (state.errorMessage case final message?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            message,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      ),
                    if (state.isBusy) ...[
                      LinearProgressIndicator(
                        semanticsLabel: switch (state.status) {
                          ScanStatus.analyzing => 'Analisis berlangsung',
                          ScanStatus.recovering => 'Memulihkan foto',
                          _ => 'Menunggu pemilihan foto',
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => bloc.add(const PickPhoto(PhotoSource.gallery)),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        photo == null ? 'Pilih Foto dari Galeri' : 'Ganti Foto',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => bloc.add(const PickPhoto(PhotoSource.camera)),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Ambil Foto'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: photo == null || state.isBusy
                          ? null
                          : () => bloc.add(const AnalyzePhoto()),
                      child: Text(
                        state.status == ScanStatus.analyzing
                            ? 'Menganalisis…'
                            : 'Analisis',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
