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
                  Text(
                    'Mengenal teknologi kami',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ModelCard(),
                  const SizedBox(height: 14),
                  Text(
                    'Yang bisa Anda lakukan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const GlassSurface(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        _CapabilityRow(
                          icon: Icons.photo_camera_outlined,
                          title: 'Scan daun padi',
                          description: 'Foto dari kamera atau galeri',
                        ),
                        Divider(height: 1),
                        _CapabilityRow(
                          icon: Icons.history_outlined,
                          title: 'Pantau riwayat',
                          description: 'Simpan dan buka kembali hasil scan',
                        ),
                      ],
                    ),
                  ),
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

class _ModelCard extends StatelessWidget {
  const _ModelCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Icon(Icons.memory_rounded, color: colors.onPrimary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EfficientNetB0 + TensorFlow Lite',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'Model klasifikasi citra menganalisis foto langsung di perangkat. Data foto tidak perlu dikirim ke internet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mengenali 5 kondisi daun padi',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
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
