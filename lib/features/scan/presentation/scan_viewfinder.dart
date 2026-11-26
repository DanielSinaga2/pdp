import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'scan_result_page.dart';

class ScanViewfinder extends StatelessWidget {
  const ScanViewfinder({super.key, this.photo, required this.isAnalyzing});

  final Uint8List? photo;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = photo;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          if (image != null)
            ScanPhotoPreview(photo: image)
          else
            ColoredBox(
              color: colors.surfaceContainerHighest,
              child: SizedBox(
                width: double.infinity,
                height: 240,
                child: Icon(
                  Icons.photo_outlined,
                  size: 56,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          Positioned.fill(
            child: ScanOverlay(
              frameColor: image == null ? colors.onSurfaceVariant : Colors.white,
              showLine: image != null && isAnalyzing,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    super.key,
    this.frameColor = Colors.white,
    required this.showLine,
  });

  final Color frameColor;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FramePainter(frameColor)),
            if (showLine) const _ScanLine(),
          ],
        ),
      ),
    );
  }
}

class _ScanLine extends StatefulWidget {
  const _ScanLine();

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.stop();
      _position.value = 0.5;
    } else if (!_position.isAnimating) {
      _position.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(19),
      child: AnimatedBuilder(
        animation: _position,
        builder: (context, child) => Align(
          alignment: Alignment(0, _position.value * 2 - 1),
          child: child,
        ),
        child: Container(
          key: const Key('scan-line'),
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5252),
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(color: Color(0xB3FF3030), blurRadius: 10, spreadRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 18.0;
    if (size.shortestSide < inset * 2 + 36) return;

    final frame = Rect.fromLTWH(
      inset,
      inset,
      size.width - 2 * inset,
      size.height - 2 * inset,
    );
    final corners = [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ];
    final path = Path();
    for (final (corner, dx, dy) in corners) {
      path
        ..moveTo(corner.dx, corner.dy + dy * 17)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx + dx * 17, corner.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x88000000)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => color != oldDelegate.color;
}
