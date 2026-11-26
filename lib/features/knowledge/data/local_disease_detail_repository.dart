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
      analysisManagement:
          'Pemupukan:\n'
          '• Kurangi Urea 20-60% dari dosis anjuran setempat (makin berat '
          'serangan, makin besar pengurangannya) dan bagi menjadi 3 kali '
          'pemberian. Hentikan Urea susulan selama gejala masih aktif.\n'
          '• Tambah KCl sekitar 30-50% dari dosis anjuran agar jaringan '
          'tanaman lebih kuat.\n'
          '• Setelah fase berbunga, jangan beri Urea lagi.\n\n'
          'Dosis disesuaikan dengan uji tanah, varietas, dan anjuran '
          'penyuluh/BPTP setempat.',
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
      analysisManagement:
          'Pemupukan:\n'
          '• Kurangi Urea 20-60% dari dosis anjuran setempat (makin berat '
          'serangan, makin besar pengurangannya) dan bagi menjadi 3 kali. '
          'Nitrogen berlebih sangat memicu blast.\n'
          '• Tambah KCl sekitar 30-50% dari dosis anjuran.\n'
          '• Tambahkan sumber silika (kompos jerami atau abu sekam).\n'
          '• Hindari Urea susulan menjelang bunting dan berbunga.\n\n'
          'Dosis disesuaikan dengan uji tanah, varietas, dan anjuran '
          'penyuluh/BPTP setempat.',
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
      analysisManagement:
          'Pemupukan:\n'
          '• Jangan mengurangi pupuk dasar; penuhi dosis N-P-K anjuran '
          'setempat karena penyakit ini berkaitan dengan kekurangan hara.\n'
          '• Tambah KCl sekitar 20-50% dari dosis anjuran.\n'
          '• Gunakan ZA sebagai sebagian sumber nitrogen bila tanah miskin '
          'belerang.\n'
          '• Tambahkan bahan organik atau kompos jerami (sumber silika).\n\n'
          'Dosis disesuaikan dengan uji tanah, varietas, dan anjuran '
          'penyuluh/BPTP setempat.',
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
      analysisManagement:
          'Pemupukan:\n'
          '• Pupuk tidak menyembuhkan virus; fungsinya hanya membantu anakan '
          'yang masih sehat.\n'
          '• Lakukan pemupukan berimbang. Kurangi Urea sekitar 10-30% dari '
          'dosis anjuran setempat karena tanaman yang terlalu rimbun menarik '
          'wereng.\n'
          '• Beri KCl cukup (sekitar 20% di atas dosis anjuran). Setelah fase '
          'berbunga tidak perlu Urea.\n\n'
          'Dosis disesuaikan dengan uji tanah, varietas, dan anjuran '
          'penyuluh/BPTP setempat.',
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
      analysisManagement:
          'Pemupukan:\n'
          '• Lakukan pemupukan berimbang N-P-K sesuai anjuran setempat atau '
          'hasil uji tanah.\n'
          '• Bagi Urea menjadi 2-3 kali (awal tanam, fase anakan, sebelum '
          'bunting) dan hentikan setelah fase berbunga.\n'
          '• Beri KCl pada awal tanam dan saat fase primordia (bunting).\n\n'
          'Dosis disesuaikan dengan uji tanah, varietas, dan anjuran '
          'penyuluh/BPTP setempat.',
    ),
  };
}
