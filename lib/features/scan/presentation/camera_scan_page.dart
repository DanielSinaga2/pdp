import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' as camera;
import 'package:material_ui/material_ui.dart';

import 'scan_viewfinder.dart';

class CameraScanPage extends StatefulWidget {
  const CameraScanPage({super.key});

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage>
    with WidgetsBindingObserver {
  camera.CameraController? _controller;
  Future<void> _cameraWork = Future.value();
  bool _foreground = true;
  bool _closing = false;
  bool _takingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A permission dialog can temporarily remove focus without backgrounding.
    if (state == AppLifecycleState.inactive) return;
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    _syncCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closing = true;
    _syncCamera();
    super.dispose();
  }

  void _syncCamera() {
    _cameraWork = _cameraWork.then((_) async {
      if (_closing || !_foreground) {
        final controller = _controller;
        _controller = null;
        if (!_closing) setState(() => _takingPhoto = false);
        if (controller != null) await _disposeCamera(controller);
        return;
      }
      if (_controller != null) return;

      camera.CameraController? opening;
      try {
        final cameras = await camera.availableCameras();
        if (_closing || !_foreground) return;
        if (cameras.isEmpty) {
          setState(() => _error = 'Kamera tidak tersedia di perangkat ini.');
          return;
        }
        final rear = cameras.firstWhere(
          (item) => item.lensDirection == camera.CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        opening = camera.CameraController(
          rear,
          camera.ResolutionPreset.medium,
          enableAudio: false,
        );
        await opening.initialize();
        if (_closing || !_foreground) return;
        final ready = opening;
        setState(() {
          _controller = ready;
          _error = null;
        });
        opening = null;
      } on camera.CameraException catch (error) {
        if (_closing || !_foreground) return;
        setState(() {
          _error = switch (error.code) {
            'CameraAccessDenied' ||
            'CameraAccessDeniedWithoutPrompt' ||
            'CameraAccessRestricted' =>
              'Akses kamera ditolak. Izinkan kamera di pengaturan perangkat.',
            _ => 'Kamera gagal dibuka. Silakan coba lagi.',
          };
        });
      } on Exception {
        if (_closing || !_foreground) return;
        setState(() => _error = 'Kamera gagal dibuka. Silakan coba lagi.');
      } finally {
        if (opening != null) await _disposeCamera(opening);
      }
    });
  }

  Future<void> _disposeCamera(camera.CameraController controller) async {
    try {
      await controller.dispose();
    } on Exception {
      // The camera can already have been closed by the platform.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !_foreground || _closing || _takingPhoto) return;

    setState(() {
      _takingPhoto = true;
      _error = null;
    });
    camera.XFile? photo;
    try {
      photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) throw const FormatException('Foto kosong.');
      if (!mounted ||
          _closing ||
          !_foreground ||
          _controller != controller ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      Navigator.of(context).pop<Uint8List>(bytes);
    } on Exception {
      if (!mounted || _controller != controller) return;
      setState(() => _error = 'Foto gagal diambil. Silakan coba lagi.');
    } finally {
      if (photo != null) {
        try {
          await File(photo.path).delete();
        } on FileSystemException {
          // This copy is in the camera cache and can expire independently.
        }
      }
      if (mounted && _controller == controller) {
        setState(() => _takingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _error;

    return Scaffold(
      appBar: AppBar(title: const Text('Kamera daun padi')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: controller != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: camera.CameraPreview(
                          controller,
                          child: ScanOverlay(showLine: !_takingPhoto),
                        ),
                      )
                    : error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(error, textAlign: TextAlign.center),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (controller != null) ...[
                    Text(
                      error ?? 'Arahkan kamera ke daun padi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (controller == null && error != null)
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _syncCamera();
                      },
                      child: const Text('Coba lagi'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: controller == null || _takingPhoto
                          ? null
                          : _capture,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_takingPhoto ? 'Mengambil foto…' : 'Ambil Foto'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
