import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_ui/material_ui.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const scanRoute = '/scan';
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
                    'Fitur',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _FeatureCard(
                    label: 'Scan',
                    description: 'Ambil foto atau pilih dari galeri',
                    icon: Icons.document_scanner_outlined,
                    route: scanRoute,
                    primary: true,
                  ),
                  const SizedBox(height: 10),
                  const _SecondaryFeatures(),
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

class _SecondaryFeatures extends StatelessWidget {
  const _SecondaryFeatures();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final stack =
            constraints.maxWidth < 304 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        const history = _FeatureCard(
          label: 'Riwayat',
          description: 'Lihat hasil scan',
          icon: Icons.history,
          route: LandingPage.historyRoute,
        );
        const settings = _FeatureCard(
          label: 'Pengaturan',
          description: 'Tema dan ambang',
          icon: Icons.settings_outlined,
          route: LandingPage.settingsRoute,
        );

        if (stack) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [history, SizedBox(height: gap), settings],
          );
        }

        return const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: history),
              SizedBox(width: gap),
              Expanded(child: settings),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.route,
    this.primary = false,
  });

  final String label;
  final String description;
  final IconData icon;
  final String route;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final background = primary
        ? colors.primaryContainer
        : colors.surfaceContainerLow;
    final foreground = primary ? colors.onPrimaryContainer : colors.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: primary ? Colors.transparent : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed<void>(route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: primary ? colors.primary : colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    icon,
                    size: 20,
                    color: primary ? colors.onPrimary : colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary ? foreground : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (primary) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
