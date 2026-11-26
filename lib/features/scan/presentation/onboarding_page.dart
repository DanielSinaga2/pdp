import 'package:material_ui/material_ui.dart';

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
      color: Color(0xFF2F6B45),
    ),
    _IntroSlide(
      icon: Icons.document_scanner_rounded,
      eyebrow: 'SCAN CERDAS',
      title: 'Ambil foto,\ndapatkan petunjuk.',
      description: 'Pilih foto dari galeri atau gunakan kamera untuk menganalisis kondisi daun.',
      color: Color(0xFF497F59),
    ),
    _IntroSlide(
      icon: Icons.memory_rounded,
      eyebrow: 'AI DI PERANGKAT',
      title: 'Cepat, privat,\ndan siap di lapangan.',
      description: 'Model TensorFlow Lite bekerja langsung di perangkat Anda, bahkan tanpa internet.',
      color: Color(0xFF215C4A),
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
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _enterHome,
                child: const Text('Lewati'),
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
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 6),
                        width: index == _page ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
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
          ],
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
    required this.color,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(62),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .25),
                    blurRadius: 36,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Icon(icon, size: 96, color: const Color(0xFFF3F7EE)),
            ),
          ),
          const Spacer(),
          Text(
            eyebrow,
            style: text.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: text.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
