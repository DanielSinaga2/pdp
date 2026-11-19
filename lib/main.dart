import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'features/history/domain/history_repository.dart';
import 'features/knowledge/domain/disease_detail_repository.dart';
import 'features/scan/presentation/scan_bloc.dart';
import 'features/scan/presentation/scan_page.dart';
import 'injection.dart';

void main() {
  configureDependencies();
  runApp(const PadiSehatApp());
}

class PadiSehatApp extends StatelessWidget {
  const PadiSehatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadiSehat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF367343)),
      ),
      home: BlocProvider(
        create: (_) => getIt<ScanBloc>(),
        child: ScanPage(
          details: getIt<DiseaseDetailRepository>(),
          history: getIt<HistoryRepository>(),
        ),
      ),
    );
  }
}
