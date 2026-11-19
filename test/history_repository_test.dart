import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pdp/features/history/data/drift_history_repository.dart';
import 'package:pdp/features/history/data/history_database.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';

void main() {
  test('riwayat bertahan saat dibuka ulang, bisa difilter dan dihapus', () async {
    final support = await Directory.systemTemp.createTemp('padisehat-test-');
    addTearDown(() => support.delete(recursive: true));
    final photos = Directory(p.join(support.path, 'history_photos'));
    final original = File(p.join(support.path, 'gallery.jpg'));
    final bytes = Uint8List.fromList([1, 2, 3]);
    await original.writeAsBytes(bytes);

    final databaseFile = File(p.join(support.path, 'history.sqlite'));
    final firstDatabase = HistoryDatabase(NativeDatabase(databaseFile));
    final first = DriftHistoryRepository(firstDatabase, () async => photos);
    final older = DateTime.utc(2026, 11, 18);
    final newer = DateTime.utc(2026, 11, 19);
    try {
      await first.save(
        label: ConditionLabel.healthy,
        confidence: 0.75,
        scannedAt: newer,
        isSimulated: false,
        photo: await original.readAsBytes(),
      );
      await first.save(
        label: ConditionLabel.brownSpot,
        confidence: 0.85,
        scannedAt: older,
        isSimulated: true,
        photo: bytes,
      );
    } finally {
      await firstDatabase.close();
    }

    final orphan = File(p.join(photos.path, '0123456789abcdef0123456789abcdef.img'));
    await orphan.writeAsBytes(bytes);

    final reopened = HistoryDatabase(NativeDatabase(databaseFile));
    addTearDown(reopened.close);
    final repository = DriftHistoryRepository(reopened, () async => photos);
    final entries = await repository.list();
    expect(entries.map((entry) => entry.label), [
      ConditionLabel.healthy,
      ConditionLabel.brownSpot,
    ]);
    expect(await orphan.exists(), isFalse);
    final filtered = await repository.list(label: ConditionLabel.healthy);
    final saved = filtered.single;
    expect(saved.confidence, 0.75);
    expect(saved.scannedAt, newer);
    expect(saved.isSimulated, isFalse);
    expect(await repository.readPhoto(saved.id), bytes);

    await repository.delete(saved.id);
    expect(await repository.readPhoto(saved.id), isNull);
    expect(await photos.list().length, 1);
    expect(await original.readAsBytes(), bytes);

    final remainingCopy = await photos.list().single;
    await remainingCopy.delete();
    expect(await repository.readPhoto(entries.last.id), isNull);
    expect((await repository.list()).single.isSimulated, isTrue);
    await repository.delete(entries.last.id);
    expect(await repository.list(), isEmpty);
  });

  test('gagal membuat salinan tidak meninggalkan catatan', () async {
    final support = await Directory.systemTemp.createTemp('padisehat-test-');
    addTearDown(() => support.delete(recursive: true));
    final path = p.join(support.path, 'blocked');
    final blocker = await File(path).create();
    final database = HistoryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftHistoryRepository(database, () async => Directory(path));

    await expectLater(
      repository.save(
        label: ConditionLabel.healthy,
        confidence: 0.75,
        scannedAt: DateTime.utc(2026, 11, 19),
        isSimulated: false,
        photo: Uint8List.fromList([1, 2, 3]),
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(await blocker.exists(), isTrue);
    await blocker.delete();
    expect(await repository.list(), isEmpty);
  });
}
