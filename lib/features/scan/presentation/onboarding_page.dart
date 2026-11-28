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
    final typography = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    excludeFromSemantics: true,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x0015291D),
                          Color(0x1A15291D),
                          Color(0x9915291D),
                        ],
                        stops: [0, .36, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: (constraints.maxHeight * .40)
                            .clamp(110.0, 260.0)
                            .toDouble(),
                      ),
                      GlassSurface(
                        radius: 20,
                        tint: const Color(0xB31B3022),
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 20,
                                  color: const Color(0xFFD2E6C7),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    eyebrow,
                                    style: typography.labelLarge?.copyWith(
                                      color: const Color(0xFFD2E6C7),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              title,
                              style: typography.headlineSmall?.copyWith(
                                color: const Color(0xFFF4F8F0),
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              description,
                              style: typography.bodyMedium?.copyWith(
                                color: const Color(0xFFE5EFE3),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
