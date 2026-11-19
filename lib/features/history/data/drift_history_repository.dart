import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../knowledge/domain/condition_label.dart';
import '../domain/history_repository.dart';
import 'history_database.dart';

class DriftHistoryRepository implements HistoryRepository {
  DriftHistoryRepository(this._database, this._photoDirectory);

  final HistoryDatabase _database;
  final Future<Directory> Function() _photoDirectory;
  static final _managedName = RegExp(r'^[0-9a-f]{32}\.img$');
  bool _reconciled = false;

  @override
  Future<void> save({
    required ConditionLabel label,
    required double confidence,
    required DateTime scannedAt,
    required bool isSimulated,
    required Uint8List photo,
  }) async {
    final directory = await _photoDirectory();
    await _reconcile(directory);
    final random = Random.secure();
    final token = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final name = '$token.img';
    final copy = _managedFile(directory, name);
    var created = false;

    try {
      await _database.transaction(() async {
        await _database.customInsert(
          'INSERT INTO scan_history '
          '(label_code, confidence, scanned_at, photo_name, is_simulated) '
          'VALUES (?, ?, ?, ?, ?)',
          variables: [
            Variable<String>(label.code),
            Variable<double>(confidence),
            Variable<int>(scannedAt.microsecondsSinceEpoch),
            Variable<String>(name),
            Variable<int>(isSimulated ? 1 : 0),
          ],
        );
        await directory.create(recursive: true);
        await copy.create(exclusive: true);
        created = true;
        await copy.writeAsBytes(photo, flush: true);
      });
    } catch (_) {
      if (created) {
        try {
          await _deleteCopy(copy);
        } on FileSystemException {
          // Retry cleanup when history is next accessed.
          _reconciled = false;
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<HistoryEntry>> list({ConditionLabel? label}) async {
    await _reconcile(await _photoDirectory());
    final rows = await _database.customSelect(
      'SELECT * FROM scan_history '
      '${label == null ? '' : 'WHERE label_code = ? '}'
      'ORDER BY scanned_at DESC, id DESC',
      variables: [if (label != null) Variable<String>(label.code)],
    ).get();
    return rows.map((row) {
      final code = row.read<String>('label_code');
      return HistoryEntry(
        id: row.read<int>('id'),
        label: ConditionLabel.values.firstWhere((label) => label.code == code),
        confidence: row.read<double>('confidence'),
        scannedAt: DateTime.fromMicrosecondsSinceEpoch(
          row.read<int>('scanned_at'),
          isUtc: true,
        ),
        isSimulated: row.read<int>('is_simulated') == 1,
      );
    }).toList();
  }

  @override
  Future<Uint8List?> readPhoto(int id) async {
    try {
      final directory = await _photoDirectory();
      final name = await _findPhotoName(id);
      if (name == null || !_managedName.hasMatch(name)) return null;
      final file = _managedFile(directory, name);
      if (await FileSystemEntity.type(file.path, followLinks: false) !=
          FileSystemEntityType.file) {
        return null;
      }
      return await file.readAsBytes();
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> delete(int id) async {
    final directory = await _photoDirectory();
    await _reconcile(directory);
    await _database.transaction(() async {
      final name = await _findPhotoName(id);
      if (name == null) return;
      await _database.customUpdate(
        'DELETE FROM scan_history WHERE id = ?',
        variables: [Variable<int>(id)],
      );
      if (_managedName.hasMatch(name)) {
        await _deleteCopy(_managedFile(directory, name));
      }
    });
  }

  Future<String?> _findPhotoName(int id) async {
    final row = await _database.customSelect(
      'SELECT photo_name FROM scan_history WHERE id = ?',
      variables: [Variable<int>(id)],
    ).getSingleOrNull();
    return row?.read<String>('photo_name');
  }

  // Clean up copies left behind if the process stopped before SQLite committed.
  Future<void> _reconcile(Directory directory) async {
    if (_reconciled) return;
    await _database.transaction(() async {
      if (_reconciled) return;
      if (await directory.exists()) {
        final rows = await _database.customSelect(
          'SELECT photo_name FROM scan_history',
        ).get();
        final referenced = rows.map((row) => row.read<String>('photo_name')).toSet();
        await for (final entry in directory.list(followLinks: false)) {
          final name = p.basename(entry.path);
          if (entry is File &&
              _managedName.hasMatch(name) &&
              !referenced.contains(name)) {
            await _deleteCopy(entry);
          }
        }
      }
      _reconciled = true;
    });
  }

  File _managedFile(Directory directory, String name) =>
      File(p.join(directory.path, name));

  Future<void> _deleteCopy(File file) async {
    // A missing copy should not prevent deletion of its history entry.
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.file) {
      await file.delete();
    }
  }
}
