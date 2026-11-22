# Berkas model AI

Letakkan dua berkas hasil `tools/konversi_tflite.py` di folder ini:

- `model_image.tflite`  (salin dari `model_image_dynamic.tflite` atau `model_image_fp32.tflite`)
- `pemetaan.json`

Lihat `docs/MODEL_AI.md` untuk langkah lengkap. Tanpa kedua berkas ini aplikasi
dapat dijalankan dengan `flutter run --dart-define=SIMULATED_MODEL=true`.
