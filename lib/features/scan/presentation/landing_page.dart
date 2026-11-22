import 'package:material_ui/material_ui.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: colors.surfaceContainerLow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFCF4),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Image.asset(
                                  'assets/branding/padisehat_logo.png',
                                  key: const Key('padisehat-logo'),
                                  semanticLabel: 'PadiSehat',
                                  width: 108,
                                  height: 96,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Deteksi Penyakit Padi',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Kenali kondisi daun padi dari foto, langsung di perangkat.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScanFeature(onStart: onStart),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: const ExcludeSemantics(
                    child: SizedBox(
                      height: 186,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 65,
                            child: CustomPaint(painter: _FieldPainter()),
                          ),
                          CustomPaint(painter: _RiceLeafPainter()),
                        ],
                      ),
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
}

class _ScanFeature extends StatelessWidget {
  const _ScanFeature({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        onTap: onStart,
        leading: Icon(
          Icons.photo_camera_outlined,
          color: colors.onPrimaryContainer,
        ),
        title: Text(
          'Scan',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Analisis daun padi dari kamera atau galeri',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colors.onPrimaryContainer,
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
