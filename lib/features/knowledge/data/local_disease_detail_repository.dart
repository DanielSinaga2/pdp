import '../domain/condition_label.dart';
import '../domain/disease_detail_repository.dart';

class LocalDiseaseDetailRepository implements DiseaseDetailRepository {
  const LocalDiseaseDetailRepository();

  @override
  DiseaseDetail getDetail(ConditionLabel label) => switch (label) {
    ConditionLabel.bacterialLeafBlight => const DiseaseDetail(
      name: 'Hawar daun bakteri',
      symptoms:
          'Gejala biasanya berupa bercak basah kekuningan di tepi atau ujung '
          'daun yang memanjang dan dapat membuat daun mengering. Pada bibit, '
          'tanaman dapat layu.',
      cause:
          'Penyakit disebabkan oleh bakteri Xanthomonas oryzae pv. oryzae. '
          'Bakteri dapat menyebar melalui air, sisa tanaman terinfeksi, dan '
          'alat atau bahan tanam yang tercemar.',
      management:
          'Gunakan varietas yang tahan, bibit sehat, dan pemupukan berimbang. '
          'Jaga kebersihan lahan dan saluran air, serta hindari pemupukan '
          'nitrogen berlebihan. Minta saran penyuluh setempat sebelum '
          'menggunakan pestisida.',
    ),
    ConditionLabel.blast => const DiseaseDetail(
      name: 'Blast',
      symptoms:
          'Bercak pada daun umumnya berbentuk belah ketupat dengan bagian '
          'tengah abu-abu atau keputihan dan tepi berwarna cokelat. Infeksi '
          'pada leher malai dapat menyebabkan pengisian gabah terganggu.',
      cause:
          'Penyakit disebabkan oleh jamur Pyricularia oryzae (Magnaporthe '
          'oryzae). Perkembangan penyakit dapat didukung kelembapan tinggi, '
          'varietas rentan, dan pemupukan nitrogen berlebihan.',
      management:
          'Tanam varietas tahan dan gunakan pemupukan berimbang. Pantau '
          'tanaman terutama saat kondisi lembap, bersihkan tanaman padi '
          'relawan dan sisa tanaman sakit, serta konsultasikan pengendalian '
          'dengan penyuluh setempat.',
    ),
    ConditionLabel.brownSpot => const DiseaseDetail(
      name: 'Bercak coklat',
      symptoms:
          'Muncul bercak kecil berbentuk bulat atau oval berwarna cokelat '
          'pada daun. Bercak dapat bertambah banyak dan menyatu saat serangan '
          'berat.',
      cause:
          'Penyakit disebabkan oleh jamur Bipolaris oryzae. Benih atau sisa '
          'tanaman terinfeksi dapat menjadi sumber penyakit; tanaman yang '
          'kekurangan hara atau mengalami cekaman juga lebih rentan.',
      management:
          'Gunakan benih sehat dan varietas yang sesuai, jaga kesuburan tanah '
          'serta pemupukan tetap berimbang, dan kelola sisa tanaman setelah '
          'panen. Untuk langkah pengendalian lebih lanjut, mintalah saran '
          'penyuluh setempat.',
    ),
    ConditionLabel.tungro => const DiseaseDetail(
      name: 'Tungro',
      symptoms:
          'Tanaman dapat tumbuh kerdil, jumlah anakan berkurang, dan daun '
          'menguning hingga jingga. Tingkat gejala dapat berbeda menurut '
          'umur tanaman dan varietas.',
      cause:
          'Tungro disebabkan oleh infeksi virus yang ditularkan wereng hijau. '
          'Serangga tersebut dapat membawa virus dari tanaman terinfeksi ke '
          'tanaman sehat.',
      management:
          'Gunakan varietas tahan, tanam serempak bila memungkinkan, dan '
          'cabut tanaman bergejala berat untuk mengurangi sumber penularan. '
          'Kendalikan tanaman padi relawan dan gulma inang, pantau wereng '
          'hijau, serta ikuti saran penyuluh setempat.',
    ),
    ConditionLabel.healthy => const DiseaseDetail(
      name: 'Sehat',
      symptoms:
          'Tidak tampak gejala penyakit yang dikenali oleh model pada foto. '
          'Hasil ini tidak memastikan tanaman bebas dari semua penyakit.',
      cause:
          'Tanaman tampak tidak menunjukkan gejala penyakit pada foto yang '
          'dianalisis.',
      management:
          'Lanjutkan pemantauan rutin, gunakan benih sehat, dan lakukan '
          'pemupukan serta pengairan sesuai kebutuhan tanaman.',
    ),
  };
}
