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

Metadata `assets/model/pemetaan.json` mencantumkan `cfg.BACKBONE` sebagai
`efficientnetb0`; karena itu arsitektur model ditampilkan sebagai EfficientNetB0.
Model yang dipakai aplikasi tetap model klasifikasi citra (`image`) dan inferensi
dijalankan on-device menggunakan TensorFlow Lite.

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

## Analisis hybrid CNN, Certainty Factor, dan Fuzzy

Notebook `Paddy_Doctor_Multimodal_CF_Fuzzy.ipynb` yang dibagikan menjadi
rujukan untuk rumus dan parameter di bagian ini. Notebook mengonfigurasi
EfficientNetB0 sebagai backbone default dan menyediakan MobileNetV2 sebagai
opsi. Berkas model aplikasi tetap ditentukan oleh metadata model yang terpasang.

### Certainty Factor

Implementasi di `lib/features/scan/domain/certainty_factor.dart` mengikuti
`CF_USER`, `GEJALA`, `LINGKUNGAN`, dan `gabung_mycin` pada notebook:

* Pilihan keyakinan pengguna: `tidak=0`, `ragu=0.4`, `cukup_yakin=0.6`,
  `yakin=0.8`, dan `sangat_yakin=1.0`.
* CF evidence = CF pakar bertanda × keyakinan pengguna. Bobot negatif
  mengurangi dukungan penyakit terkait; jawaban `tidak` bernilai nol dan
  tidak menambahkan evidence.
* Bukti positif dan negatif masing-masing diagregasi:
  `CF+ = 1 − Π(1 − CF positif)` dan
  `CF− = 1 − Π(1 − |CF negatif|)`.
* Nilai gabungan:
  `(CF+ − CF−) / (1 − min(CF+, CF−))`. Jika penyebut nol atau sangat dekat
  nol, notebook menetapkan hasil ke `0.0`.
* Diagnosis CF dianggap yakin bila kandidat teratas minimal `0.50` dan
  selisih terhadap kandidat kedua minimal `0.15`.

Probabilitas CNN tetap terpisah dan tidak pernah dipakai sebagai MB, MD, bobot
pakar, atau input CF. Modul memuat 16 gejala dan bobot pakar bertanda serta
enam bukti lingkungan dari notebook. Bobot tersebut adalah aturan di notebook,
bukan bukti bahwa bobot sudah divalidasi secara independen oleh ahli lapangan.
CF tetap belum dihitung jika pengguna belum memasukkan evidence yang bernilai
non-nol.

Bukti lingkungan hanya ditambahkan jika suhu, RH, hujan tujuh hari, dan HST
seluruhnya tersedia. Degree lingkungan dihitung dari membership notebook:
RH tinggi, hujan lebat, suhu sejuk, cuaca kering, fase awal, dan fase akhir.

### Fuzzy Logic

`FuzzyConfiguration.fromNotebookDraft()` mengikuti membership trapezoid dan
aturan `ATURAN` pada notebook. Variabel Sugeno adalah keparahan gejala (%),
HST, dan RH (%). Suhu dan curah hujan dipakai untuk evidence CF lingkungan,
bukan sebagai antecedent aturan Sugeno.

Membership yang diterapkan sama dengan notebook:

* Keparahan: ringan `(0,0,4,10)`, sedang `(4,12,20,30)`, berat `(20,35,100,100)`.
* Fase tanaman: awal `(0,0,25,45)`, tengah `(30,45,55,70)`, akhir
  `(55,75,150,150)`.
* RH: rendah `(0,0,60,72)`, sedang `(62,72,80,88)`, tinggi `(80,90,100,100)`.
* Suhu sejuk `(15,15,23,27)` dan hujan: rendah `(0,0,20,50)`, sedang
  `(30,70,100,150)`, lebat `(100,150,400,400)`.

Inferensi Sugeno orde-0 memakai `min` untuk AND. Bobot CF penyakit adalah
`max(CF, 0)^3` (`SHARPEN=3`); kekuatan akhir aturan adalah derajat membership
minimum dikali bobot CF tersebut. Output crisp berupa rata-rata terbobot untuk
faktor Urea, faktor KCl, dan skor pengendalian kimia. Ambang skor kimia di
notebook adalah `0.30` untuk siaga dan `0.60` untuk disarankan; rekomendasi
kimia juga bergantung pada ambang diagnosis CF dan fase pemasakan.
Notebook menerapkan pagar fase: faktor Urea dibuat nol setelah HST 60 pada
fase berbunga/pengisian dan pemasakan; pengendalian kimia dinonaktifkan pada
fase pemasakan (HST > 85).

Notebook tidak menghasilkan kategori keparahan atau prioritas generik:
keparahan adalah input, sedangkan output Sugeno adalah faktor dan skor di atas.
Aplikasi tidak mengubah faktor menjadi dosis pupuk/pestisida dan tidak
menampilkan bahan aktif pestisida dari output Sugeno. Aturan/membership berasal
dari notebook, tetapi tetap perlu validasi ahli pertanian sebelum dipakai
sebagai keputusan budidaya. Input fuzzy yang belum lengkap atau tidak ada CF
positif menghasilkan status belum dihitung.

### Integrasi dan rekomendasi

`DiseaseAnalysisService` menerima `ScanPrediction`, observasi gejala,
input lingkungan/fuzzy, dan `DiseaseDetail`. Service memakai hasil prediksi
yang sudah ada. Jika diagnosis CF memenuhi ambang tetapi berbeda dari
label CNN, service menandai perbedaan untuk diverifikasi.

Pada branch utama, modul ini tersedia di lapisan domain. Halaman Scan,
Hasil, dan Riwayat tetap memakai alur TFLite yang sudah ada. Formulir input
gejala dan halaman detail analisis hybrid belum tersambung. Materi utama
di `DiseaseDetail.management` dipakai halaman hasil. Materi tambahan di
`DiseaseDetail.analysisManagement` dipakai oleh service bersama aturan fase
tanam sebelum menghasilkan rekomendasi.
