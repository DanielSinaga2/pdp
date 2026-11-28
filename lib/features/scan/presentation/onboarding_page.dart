import 'package:material_ui/material_ui.dart';

import '../../../presentation/padi_style.dart';
import 'landing_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _page = 0;

  static const _slides = [
    _IntroSlide(
      icon: Icons.eco_rounded,
      eyebrow: 'PadiSehat',
      title: 'Daun padi sehat,\npanen lebih dekat.',
      description:
          'Teman praktis untuk mengenali kondisi daun padi langsung dari foto.',
      image: 'assets/branding/padisehat_rice_field.webp',
    ),
    _IntroSlide(
      icon: Icons.document_scanner_rounded,
      eyebrow: 'SCAN CERDAS',
      title: 'Ambil foto,\ndapatkan petunjuk.',
      description:
          'Pilih foto dari galeri atau gunakan kamera untuk menganalisis kondisi daun.',
      image: 'assets/branding/padisehat_intro_scan.webp',
    ),
    _IntroSlide(
      icon: Icons.memory_rounded,
      eyebrow: 'AI DI PERANGKAT',
      title: 'Cepat, privat,\ndan siap di lapangan.',
      description:
          'Model TensorFlow Lite bekerja langsung di perangkat Anda, bahkan tanpa internet.',
      image: 'assets/branding/padisehat_intro_offline.webp',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/branding/padisehat_symbol.png',
                        width: 36,
                        height: 36,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PadiSehat',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: _enterHome,
                        child: const Text('Lewati'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) => _slides[index],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
                  child: GlassSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      spacing: 12,
                      overflowSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            _slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(right: 6),
                              width: index == _page ? 22 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: index == _page
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: isLast
                              ? _enterHome
                              : () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: Icon(
                            isLast
                                ? Icons.arrow_forward_rounded
                                : Icons.navigate_next_rounded,
                          ),
                          label: Text(isLast ? 'Masuk ke Beranda' : 'Lanjut'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _enterHome() =>
      Navigator.of(context).pushReplacementNamed(LandingPage.homeRoute);
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.image,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: (constraints.maxHeight * .54)
                  .clamp(132.0, 310.0)
                  .toDouble(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GlassSurface(
                        radius: 16,
                        padding: const EdgeInsets.all(10),
                        child: Icon(icon, color: colors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GlassSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
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
