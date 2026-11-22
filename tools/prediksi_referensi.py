"""
Prediksi referensi (Keras dan TFLite) untuk SATU foto, dipakai untuk memeriksa
bahwa praproses di aplikasi cocok dengan pelatihan.

    python tools/prediksi_referensi.py hasil_paddy/model_image.keras \
        hasil_paddy/pemetaan.json foto.jpg [keluaran/model_image_dynamic.tflite]

Bandingkan angka yang tercetak dengan hasil aplikasi untuk foto yang SAMA
(simpan foto ke galeri ponsel). Selisih beberapa persen wajar (resize berbeda);
jika kelas teratasnya berbeda jauh, periksa urutan kelas, ukuran gambar, dan
skala piksel (harus 0..255).
"""
import json, sys
import numpy as np
from PIL import Image


def siapkan(path_foto, ukuran):
    # Sama dengan notebook: RGB, resize persegi tanpa menjaga rasio, bilinear, nilai 0..255.
    im = Image.open(path_foto).convert("RGB").resize((ukuran, ukuran), Image.BILINEAR)
    return np.asarray(im, dtype="float32")[None]


def cetak(judul, kelas, p):
    print(f"\n{judul}")
    for i in np.argsort(p)[::-1][:5]:
        print(f"  {kelas[i]:28s} {p[i]:.3f}")


def main(argv):
    if len(argv) not in (4, 5):
        sys.exit(__doc__)
    model_path, json_path, foto = argv[1:4]
    peta = json.load(open(json_path)); kelas, ukuran = peta["kelas"], peta["img"]
    x = siapkan(foto, ukuran)

    import keras
    model = keras.saving.load_model(model_path)
    nama = [t.name for t in model.inputs]
    if nama != ["img"]:
        sys.exit(f"Skrip ini untuk model citra-saja (masukan 'img'); model punya {nama}.")
    cetak("Keras", kelas, model.predict({"img": x}, verbose=0)[0])

    if len(argv) == 5:
        import tensorflow as tf
        it = tf.lite.Interpreter(model_path=argv[4]); it.allocate_tensors()
        d = it.get_input_details()[0]; it.set_tensor(d["index"], x.astype(d["dtype"])); it.invoke()
        cetak("TFLite", kelas, it.get_tensor(it.get_output_details()[0]["index"])[0])


if __name__ == "__main__":
    main(sys.argv)
