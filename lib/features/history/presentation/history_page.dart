import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../knowledge/domain/condition_label.dart';
import '../../knowledge/domain/disease_detail_repository.dart';
import '../../scan/domain/prediction_repository.dart';
import '../../scan/presentation/scan_result_page.dart';
import '../domain/history_repository.dart';
import 'history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.details,
    required this.repository,
    required this.confidencePercent,
  });

  final DiseaseDetailRepository details;
  final HistoryRepository repository;
  final int confidencePercent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final cubit = context.read<HistoryCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Riwayat Scan')),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Filter kondisi'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: state.filter?.code ?? '',
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua kondisi'),
                          ),
                          for (final label in ConditionLabel.values)
                            DropdownMenuItem(
                              value: label.code,
                              child: Text(details.getDetail(label).name),
                            ),
                        ],
                        onChanged: state.busy ? null : (code) {
                          final label = code == null || code.isEmpty
                              ? null
                              : ConditionLabel.values.firstWhere(
                                  (label) => label.code == code,
                                );
                          cubit.load(filter: label);
                        },
                      ),
                    ),
                  ),
                ),
                if (state.busy) const LinearProgressIndicator(),
                if (state.error case final error?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(error, style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        )),
                        TextButton(
                          onPressed: () => cubit.load(filter: state.filter),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: state.entries.isEmpty
                      ? Center(
                          child: state.busy || state.error != null
                              ? null
                              : Text(state.filter == null
                                  ? 'Belum ada riwayat scan.'
                                  : 'Belum ada scan untuk kondisi ini.'),
                        )
                      : ListView.builder(
                          itemCount: state.entries.length,
                          itemBuilder: (context, index) {
                            final entry = state.entries[index];
                            final detail = details.getDetail(entry.label);
                            final timestamp = _formatDate(context, entry.scannedAt);
                            return ListTile(
                              title: Text(detail.name),
                              subtitle: Text(
                                entry.isSimulated
                                    ? '$timestamp · Hasil simulasi'
                                    : timestamp,
                              ),
                              onTap: state.busy ? null : () {
                                final photo = repository.readPhoto(entry.id);
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => FutureBuilder<Uint8List?>(
                                      future: photo,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState != ConnectionState.done) {
                                          return const Scaffold(
                                            body: Center(child: CircularProgressIndicator()),
                                          );
                                        }
                                        return ScanResultPage(
                                          photo: snapshot.data,
                                          prediction: ScanPrediction(
                                            label: entry.label,
                                            confidence: entry.confidence,
                                            isSimulated: entry.isSimulated,
                                          ),
                                          detail: detail,
                                          scannedAtLabel: timestamp,
                                          confidencePercent: confidencePercent,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                tooltip: 'Hapus catatan',
                                onPressed: state.busy
                                    ? null
                                    : () => _confirmDelete(context, cubit, entry.id),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final formatting = MaterialLocalizations.of(context);
    final date = formatting.formatShortDate(local);
    final clock = formatting.formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date · $clock';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HistoryCubit cubit,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan scan?'),
        content: const Text('Catatan dan salinan fotonya akan dihapus dari riwayat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) await cubit.delete(id);
  }
}
