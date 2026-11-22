"""
Konversi model Keras hasil notebook Paddy Doctor -> TensorFlow Lite (Android / iOS / Flutter).

Pemakaian:
    python konversi_tflite.py hasil_paddy/model_fusion.keras hasil_paddy/pemetaan.json keluaran/
Hasil:
    keluaran/model_fusion_fp32.tflite   (akurasi sama dengan Keras, ukuran terbesar)
    keluaran/model_fusion_dynamic.tflite (bobot 8-bit, ~4x lebih kecil; WAJIB diuji akurasinya)
    keluaran/pemetaan.json              (urutan kelas, varietas, mean/std umur -> dipakai aplikasi)
"""
import sys, json, shutil
from pathlib import Path
import numpy as np
import tensorflow as tf, keras

def konversi(path_keras, path_json, out_dir):
    out = Path(out_dir); out.mkdir(parents=True, exist_ok=True)
    model = keras.saving.load_model(path_keras)
    nama = Path(path_keras).stem

    # 1) float32
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    (out / f"{nama}_fp32.tflite").write_bytes(conv.convert())
    # 2) kuantisasi dynamic-range (bobot int8, aktivasi float)
    conv = tf.lite.TFLiteConverter.from_keras_model(model)
    conv.optimizations = [tf.lite.Optimize.DEFAULT]
    (out / f"{nama}_dynamic.tflite").write_bytes(conv.convert())
    shutil.copy(path_json, out / "pemetaan.json")

    # 3) verifikasi: keluaran TFLite harus sama dengan Keras
    peta = json.load(open(path_json)); img = peta["img"]
    r = np.random.default_rng(0); n = 8
    x = {"img": r.uniform(0, 255, (n, img, img, 3)).astype("float32"),
         "variety": r.integers(0, len(peta["varietas"]), (n, 1)).astype("int32"),
         "age": r.normal(0, 1, (n, 1)).astype("float32")}
    x = {k: x[k] for k in [t.name for t in model.inputs]}
    ref = model.predict(x, verbose=0)
    for tag in ("fp32", "dynamic"):
        it = tf.lite.Interpreter(model_path=str(out / f"{nama}_{tag}.tflite")); it.allocate_tensors()
        detail = it.get_input_details(); hasil = []
        for i in range(n):
            for d in detail:                       # cocokkan masukan berdasarkan NAMA, bukan urutan
                kunci = next(k for k in x if k in d["name"])
                it.set_tensor(d["index"], x[kunci][i:i + 1].astype(d["dtype"]))
            it.invoke(); hasil.append(it.get_tensor(it.get_output_details()[0]["index"])[0])
        hasil = np.array(hasil)
        print(f"{tag:8s} ukuran {(out / f'{nama}_{tag}.tflite').stat().st_size / 1e6:6.2f} MB | "
              f"selisih maks vs Keras {np.abs(hasil - ref).max():.5f} | kelas teratas sama {np.mean(hasil.argmax(1) == ref.argmax(1)):.0%}")
    print("nama & bentuk masukan TFLite:", [(d["name"], d["shape"].tolist(), np.dtype(d["dtype"]).name) for d in detail])

if __name__ == "__main__":
    if len(sys.argv) != 4: sys.exit(__doc__)
    konversi(*sys.argv[1:])
