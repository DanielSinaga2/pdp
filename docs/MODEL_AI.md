# Menghubungkan model AI ke PadiSehat

Aplikasi memakai antarmuka `PredictionRepository`. Implementasi lama
(`SimulatedPredictionRepository`) mengembalikan hasil tetap; sekarang
`TflitePredictionRepository` menjalankan model TFLite hasil pelatihan **di
perangkat** (tanpa internet).

```
foto (Uint8List) ─► UiPhotoPreprocessor ─► LiteRtClassifierBackend ─► pickPrediction ─► ScanPrediction
   dari ScanBloc      resize persegi, RGB 0..255   model_image.tflite      peta kelas -> ConditionLabel
```

| Berkas | Peran |
|---|---|
| `lib/features/scan/data/tflite_prediction_repository.dart` | Orkestrasi: muat model sekali, jalankan, bungkus galat. Tanpa dependensi Flutter (mudah diuji). |
| `lib/features/scan/data/prediction_postprocessing.dart` | Pemetaan kelas model -> `ConditionLabel`, softmax bila perlu. |
| `lib/features/scan/data/tflite_platform.dart` | Adaptor perangkat: `flutter_litert`, `dart:ui`, asset. |
| `lib/injection.dart` | Mendaftarkan repositori (simulasi hanya jika `SIMULATED_MODEL=true`). |
| `assets/model/` | Tempat `model_image.tflite` dan `pemetaan.json`. |
| `tools/konversi_tflite.py` | Keras -> TFLite (+ verifikasi). |
| `tools/prediksi_referensi.py` | Prediksi referensi untuk satu foto, pembanding hasil aplikasi. |

## Langkah

1. **Latih** dengan notebook `Paddy_Doctor_Multimodal_CF_Fuzzy.ipynb`; hasilnya
   `hasil_paddy/model_image.keras` dan `hasil_paddy/pemetaan.json`.
   Pakai model **`image`** (citra saja), bukan `fusion`: varietas Paddy Doctor
   adalah varietas India dan aplikasi ini tidak meminta varietas/umur.
2. **Konversi**:
   ```bash
   pip install tensorflow pillow
   python tools/konversi_tflite.py hasil_paddy/model_image.keras hasil_paddy/pemetaan.json keluaran/
   ```
   Skrip mencetak selisih keluaran TFLite terhadap Keras (harus ~0 untuk float32).
3. **Salin ke aplikasi**:
   ```bash
   cp keluaran/model_image_dynamic.tflite assets/model/model_image.tflite   # atau *_fp32.tflite
   cp keluaran/pemetaan.json assets/model/pemetaan.json
   ```
   Versi `dynamic` (bobot 8-bit) lebih kecil; **ukur ulang akurasinya** pada data uji sebelum memakainya.
4. **Jalankan**:
   ```bash
   flutter pub get
   flutter run                                   # model sungguhan
   flutter run --dart-define=SIMULATED_MODEL=true  # tanpa model (hasil simulasi)
   ```

## Kontrak model (harus sama dengan pelatihan)

* Masukan `[1, img, img, 3]`, `float32`, RGB, nilai **0..255** (penskalaan ada di dalam model). `img` dibaca dari `pemetaan.json`.
* Foto diubah ke persegi **tanpa menjaga rasio**, seperti di notebook.
* Urutan kelas keluaran = urutan `kelas` di `pemetaan.json`.
* Saat pemuatan, aplikasi memeriksa bentuk tensor terhadap `pemetaan.json`; salah pasang berkas menghasilkan galat, bukan label salah.

## Pemetaan kelas

Aplikasi mengenal 5 label (`ConditionLabel`): hawar daun bakteri, blast, bercak coklat, tungro, sehat.
Model Paddy Doctor punya 10 kelas; `normal` dipetakan ke `healthy`. Lima kelas lain
(`bacterial_leaf_streak`, `bacterial_panicle_blight`, `dead_heart`, `downy_mildew`, `hispa`)
**tidak punya label di aplikasi**. Perilakunya: probabilitas kelas itu tidak dihitung ke label mana pun,
sehingga label terbaik yang dikenal mendapat keyakinan rendah dan halaman hasil menampilkan
"Hasil kurang meyakinkan" bila di bawah ambang pengaturan (bawaan 75%). Keyakinan yang
ditampilkan adalah probabilitas mentah model.
Jika ingin perilaku yang lebih tegas, latih ulang model hanya dengan 5 kelas itu, atau
tambahkan label "tidak dikenali" pada `ConditionLabel` dan halaman hasil.

## Memeriksa di perangkat

1. Simpan beberapa foto uji (yang kelasnya diketahui) ke galeri ponsel.
2. Jalankan `python tools/prediksi_referensi.py ... foto.jpg model.tflite` untuk foto yang sama.
3. Bandingkan dengan hasil aplikasi. Selisih kecil wajar (algoritma resize berbeda); jika kelas teratas
   berbeda jauh, periksa urutan kelas, ukuran gambar, dan skala piksel.
4. Galat model dicatat lewat `debugPrint` (cari `Gagal memuat model` / `Prediksi gagal` di log).
   Pesan di layar tetap "Analisis gagal" karena `ScanBloc` tidak diubah.

## Catatan platform

* `flutter_litert` menyertakan runtime native; tidak perlu unduh biner manual. Android: `minSdk` 24 atau lebih;
  README paketnya menyebut Kotlin Gradle plugin 2.3+ hanya untuk mode runtime Play services (opsional).
  iOS: target minimum 15.0 (sudah sama dengan proyek ini).
* iOS: `Info.plist` proyek saat ini belum memuat `NSCameraUsageDescription` dan
  `NSPhotoLibraryUsageDescription`; tanpanya pengambilan foto di iOS ditolak/crash.
  (Tidak berkaitan dengan model, tetapi perlu ditambahkan.)

## Batasan

* Model dilatih pada foto dari India (Paddy Doctor); uji pada foto sawah lokal sebelum dipakai petani.
* Hasil adalah bantuan, bukan diagnosis; materi penanganan di aplikasi masih berstatus "perlu ditinjau".
