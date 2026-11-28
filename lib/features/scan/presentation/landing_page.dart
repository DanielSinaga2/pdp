import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_ui/material_ui.dart';

import '../../../presentation/padi_style.dart';
import 'app_navigation.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const scanRoute = '/scan';
  static const homeRoute = '/beranda';
  static const historyRoute = '/riwayat';
  static const settingsRoute = '/pengaturan';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final overlays = theme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlays.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        bottomNavigationBar: const AppNavigation(current: AppDestination.home),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/branding/padisehat_symbol.png',
                        key: const Key('padisehat-logo'),
                        width: 40,
                        height: 40,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'PadiSehat',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _RiceFieldHero(),
                  const SizedBox(height: 26),
                  const _TechnologyOverview(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiceFieldHero extends StatelessWidget {
  const _RiceFieldHero();

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: const Color(0xFF1B2E23),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/branding/padisehat_rice_field.webp',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xF014261E),
                      Color(0xBB14261E),
                      Color(0x3314261E),
                    ],
                    stops: [0, 0.60, 1],
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 190),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kenali kondisi\ndaun padi',
                      style: typography.headlineMedium?.copyWith(
                        color: const Color(0xFFF0F2E8),
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 225),
                      child: Text(
                        'Analisis foto langsung di perangkat, tanpa internet.',
                        style: typography.bodyMedium?.copyWith(
                          color: const Color(0xFFDFE8D9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnologyOverview extends StatelessWidget {
  const _TechnologyOverview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dari notebook ke aplikasi',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const GlassSurface(
          padding: EdgeInsets.all(18),
          child: _CapabilityRow(
            icon: Icons.science_outlined,
            title: 'Riset Paddy Doctor',
            description:
                'Notebook tim membandingkan model berbasis foto dengan model '
                'multimodal yang memakai foto, umur tanaman, dan varietas. '
                'PadiSehat memakai model berbasis foto agar scan bisa dimulai '
                'dari kamera atau galeri.',
          ),
        ),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CapabilityRow(
                icon: Icons.memory_outlined,
                title: 'EfficientNetB0 + TensorFlow Lite',
                description:
                    'Flutter menyiapkan foto RGB berukuran 224 × 224 piksel. '
                    'Model membaca pola pada daun dan menghitung skor untuk '
                    'setiap kelas langsung di HP, bahkan tanpa internet.',
              ),
              const Divider(height: 24),
              Text(
                'Kondisi yang ditampilkan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  Chip(label: Text('Hawar daun bakteri')),
                  Chip(label: Text('Blast')),
                  Chip(label: Text('Bercak coklat')),
                  Chip(label: Text('Tungro')),
                  Chip(label: Text('Sehat')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Cara membaca hasil',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const GlassSurface(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              _CapabilityRow(
                icon: Icons.photo_camera_outlined,
                title: 'Periksa hasil scan',
                description:
                    'Hasil menampilkan dugaan kondisi dan confidence model. '
                    'Kalau keyakinannya rendah, coba foto ulang dengan daun '
                    'terlihat jelas dan cahaya merata.',
              ),
              Divider(height: 16),
              _CapabilityRow(
                icon: Icons.fact_check_outlined,
                title: 'Tinjau gejala dengan Certainty Factor',
                description:
                    'Di Detail AI, jawaban tentang gejala memberi bukti '
                    'tambahan. Skor bukti dihitung terpisah dari prediksi foto.',
              ),
              Divider(height: 16),
              _CapabilityRow(
                icon: Icons.tune_outlined,
                title: 'Lihat panduan Fuzzy Sugeno',
                description:
                    'Keparahan, umur tanaman, kelembapan, dan dukungan '
                    'gejala membantu menentukan tindak lanjut ketika '
                    'datanya cukup.',
              ),
              Divider(height: 16),
              _CapabilityRow(
                icon: Icons.history_outlined,
                title: 'Buka kembali di Riwayat',
                description:
                    'Foto dan hasil scan yang tersimpan dapat dibuka kembali '
                    'di perangkat tanpa koneksi internet.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gunakan hasil sebagai petunjuk awal. Konfirmasi gejala di lapangan '
          'dengan penyuluh sebelum menentukan penanganan.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
