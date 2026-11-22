import 'package:material_ui/material_ui.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const scanRoute = '/scan';
  static const historyRoute = '/riwayat';
  static const settingsRoute = '/pengaturan';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PadiSehat'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
          child: Image.asset(
            'assets/branding/padisehat_logo.png',
            key: const Key('padisehat-logo'),
            excludeFromSemantics: true,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: colors.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kenali kondisi daun padi',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Analisis foto langsung di perangkat.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const ExcludeSemantics(
                          child: SizedBox(
                            height: 116,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 44,
                                  child: CustomPaint(painter: _FieldPainter()),
                                ),
                                CustomPaint(painter: _RiceLeafPainter()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Fitur', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final wideTiles =
                        MediaQuery.textScalerOf(context).scale(14) > 19 ||
                        constraints.maxWidth < 258;
                    final width = wideTiles
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 2 * gap) / 3;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: width,
                          child: const _FeatureTile(
                            label: 'Scan',
                            icon: Icons.camera_alt_outlined,
                            route: scanRoute,
                            primary: true,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: const _FeatureTile(
                            label: 'Riwayat',
                            icon: Icons.history,
                            route: historyRoute,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: const _FeatureTile(
                            label: 'Pengaturan',
                            icon: Icons.settings_outlined,
                            route: settingsRoute,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.label,
    required this.icon,
    required this.route,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = primary ? colors.onPrimary : colors.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      color: primary ? colors.primary : colors.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed<void>(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiceLeafPainter extends CustomPainter {
  const _RiceLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final widthScale = size.width / 400;
    final heightScale = size.height / 280;
    final scale = widthScale < heightScale ? widthScale : heightScale;
    canvas.save();
    canvas.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 280 * scale) / 2,
    );
    canvas.scale(scale);

    final haloPaint = Paint()..color = const Color(0xFFEAF4D6);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(188, 198), width: 350, height: 130),
      haloPaint,
    );

    _drawLeaf(
      canvas,
      const Offset(184, 254),
      const Offset(52, 94),
      const Color(0xFF70B82A),
      const Offset(145, 180),
    );
    _drawLeaf(
      canvas,
      const Offset(190, 254),
      const Offset(116, 35),
      const Color(0xFF8ACB2D),
      const Offset(154, 153),
    );
    _drawLeaf(
      canvas,
      const Offset(204, 254),
      const Offset(248, 20),
      const Color(0xFF63B32A),
      const Offset(222, 154),
    );
    _drawLeaf(
      canvas,
      const Offset(214, 254),
      const Offset(353, 111),
      const Color(0xFF82C62A),
      const Offset(265, 172),
    );
    _drawLeaf(
      canvas,
      const Offset(184, 254),
      const Offset(40, 211),
      const Color(0xFF5CA82B),
      const Offset(117, 229),
    );
    _drawLeaf(
      canvas,
      const Offset(201, 254),
      const Offset(326, 211),
      const Color(0xFF78B936),
      const Offset(267, 229),
    );

    final stalkPaint = Paint()
      ..color = const Color(0xFF388A2B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(194, 252), const Offset(252, 45), stalkPaint);
    for (var index = 0; index < 5; index++) {
      final y = 72.0 + index * 24;
      final x = 245.0 - index * 9;
      _drawGrain(canvas, Offset(x, y), 1);
    }

    final handlePaint = Paint()
      ..color = const Color(0xFF064B33)
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(260, 173),
      const Offset(318, 230),
      handlePaint,
    );

    canvas.drawCircle(
      const Offset(224, 139),
      72,
      Paint()..color = const Color(0xFF064B33),
    );
    canvas.drawCircle(
      const Offset(224, 139),
      59,
      Paint()..color = const Color(0xFFFAFCF4),
    );
    canvas.drawCircle(
      const Offset(224, 139),
      51,
      Paint()..color = const Color(0x5589C83D),
    );
    _drawLeaf(
      canvas,
      const Offset(209, 178),
      const Offset(253, 95),
      const Color(0xFF8FCB35),
      const Offset(223, 142),
    );
    final spotsPaint = Paint()..color = const Color(0xFF9A5A24);
    for (final spot in const [
      Offset(218, 145),
      Offset(229, 132),
      Offset(225, 153),
      Offset(239, 124),
      Offset(236, 145),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: spot, width: 5, height: 9),
        spotsPaint,
      );
    }
    canvas.drawCircle(
      const Offset(224, 139),
      54,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final raysPaint = Paint()
      ..color = const Color(0xFF9ACB39)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(307, 74), const Offset(317, 55), raysPaint);
    canvas.drawLine(const Offset(324, 91), const Offset(344, 80), raysPaint);
    canvas.drawLine(const Offset(331, 110), const Offset(352, 110), raysPaint);
    canvas.restore();
  }

  void _drawLeaf(
    Canvas canvas,
    Offset base,
    Offset tip,
    Color color,
    Offset control,
  ) {
    final direction = tip - base;
    final perpendicular = Offset(-direction.dy * 0.13, direction.dx * 0.13);
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        control.dx - perpendicular.dx,
        control.dy - perpendicular.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        control.dx + perpendicular.dx,
        control.dy + perpendicular.dy,
        base.dx,
        base.dy,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = const Color(0x55366F26)
        ..strokeWidth = 2,
    );
  }

  void _drawGrain(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = const Color(0xFFE9B923);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.65);
    for (var index = 0; index < 3; index++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(index * 9 * scale, index * 11 * scale),
          width: 11 * scale,
          height: 21 * scale,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RiceLeafPainter oldDelegate) => false;
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final back = Path()
      ..moveTo(0, height * 0.42)
      ..quadraticBezierTo(
        width * 0.25,
        height * 0.02,
        width * 0.53,
        height * 0.48,
      )
      ..quadraticBezierTo(width * 0.8, height * 0.9, width, height * 0.28)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFFD8EFA6));

    final front = Path()
      ..moveTo(0, height * 0.65)
      ..quadraticBezierTo(
        width * 0.35,
        height * 0.34,
        width * 0.67,
        height * 0.72,
      )
      ..quadraticBezierTo(width * 0.85, height * 0.9, width, height * 0.62)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF9CCB4B));
    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.85, width, height * 0.15),
      Paint()..color = const Color(0xFF78B83B),
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) => false;
}
