import 'package:drift/drift.dart';

class HistoryDatabase extends GeneratedDatabase {
  HistoryDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  // This database uses explicit SQL for its schema and queries.
  @override
  Iterable<TableInfo> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => customStatement('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label_code TEXT NOT NULL,
        confidence REAL NOT NULL CHECK (confidence BETWEEN 0 AND 1),
        scanned_at INTEGER NOT NULL,
        photo_name TEXT NOT NULL UNIQUE,
        is_simulated INTEGER NOT NULL CHECK (is_simulated IN (0, 1))
      )
    '''),
  );
}
