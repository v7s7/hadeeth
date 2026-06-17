import 'package:flutter/material.dart';

import '../models/app_characters.dart';

class CharacterAvatar extends StatelessWidget {
  final CharacterOption character;
  final double height;
  final double? width;
  final double opacity;

  const CharacterAvatar({
    super.key,
    required this.character,
    required this.height,
    this.width,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(width ?? height * 0.72, height),
        painter: _CharacterAvatarPainter(character.id),
      ),
    );
  }
}

class _CharacterAvatarPainter extends CustomPainter {
  final String id;

  const _CharacterAvatarPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512, size.height / 512);

    _ellipse(canvas, const Offset(256, 456), 92, 18, const Color(0x26000000));
    switch (id) {
      case 'male_bisht_gold':
        _drawMaleBisht(canvas);
        break;
      case 'male_shmagh_red':
        _drawMale(canvas, const Color(0xFFF6F2E5), shmagh: true);
        break;
      case 'male_ghutra_blue':
        _drawMale(canvas, const Color(0xFFAED3E5));
        break;
      case 'female_niqab':
        _drawWoman(
          canvas,
          dress: const Color(0xFF191C20),
          hijab: const Color(0xFF0E1014),
          niqab: true,
        );
        break;
      case 'female_hijab_teal':
        _drawWoman(
          canvas,
          dress: const Color(0xFF36645B),
          hijab: const Color(0xFF529A8C),
          decorated: true,
        );
        break;
      case 'female_hijab_pink':
      default:
        _drawWoman(
          canvas,
          dress: const Color(0xFF2A3442),
          hijab: const Color(0xFFD7809E),
        );
    }
    canvas.restore();
  }

  void _drawMaleBisht(Canvas canvas) {
    _drawMale(canvas, const Color(0xFFF6F2E5), ghutraOnly: true);
    _poly(canvas, [
      const Offset(196, 205),
      const Offset(256, 226),
      const Offset(316, 205),
      const Offset(360, 430),
      const Offset(295, 440),
      const Offset(256, 286),
      const Offset(217, 440),
      const Offset(152, 430),
    ], const Color(0xF5704E2D));
    _line(canvas, const Offset(202, 210), const Offset(217, 430), 8,
        const Color(0xFFD6AA4A));
    _line(canvas, const Offset(310, 210), const Offset(295, 430), 8,
        const Color(0xFFD6AA4A));
    _line(canvas, const Offset(256, 226), const Offset(256, 286), 6,
        const Color(0xFFD6AA4A));
  }

  void _drawMale(
    Canvas canvas,
    Color thobe, {
    bool shmagh = false,
    bool ghutraOnly = false,
  }) {
    _poly(canvas, [
      const Offset(205, 205),
      const Offset(307, 205),
      const Offset(335, 428),
      const Offset(177, 428),
    ], thobe);
    _poly(canvas, [
      const Offset(205, 214),
      const Offset(166, 310),
      const Offset(190, 330),
      const Offset(224, 245),
    ], thobe);
    _poly(canvas, [
      const Offset(307, 214),
      const Offset(346, 310),
      const Offset(322, 330),
      const Offset(288, 245),
    ], thobe);
    _line(canvas, const Offset(256, 212), const Offset(256, 414), 3,
        const Color(0xB4E6E2D7));
    _handsAndShoes(canvas);
    _ghutra(canvas, shmagh: shmagh);
  }

  void _drawWoman(
    Canvas canvas, {
    required Color dress,
    required Color hijab,
    bool decorated = false,
    bool niqab = false,
  }) {
    _poly(canvas, [
      const Offset(194, 205),
      const Offset(318, 205),
      const Offset(352, 430),
      const Offset(160, 430),
    ], dress);
    _poly(canvas, [
      const Offset(194, 230),
      const Offset(150, 322),
      const Offset(178, 346),
      const Offset(222, 252),
    ], dress);
    _poly(canvas, [
      const Offset(318, 230),
      const Offset(362, 322),
      const Offset(334, 346),
      const Offset(290, 252),
    ], dress);
    _handsAndShoes(canvas);
    _ellipse(canvas, const Offset(256, 144), 66, 74, hijab);
    if (niqab) {
      _ellipse(canvas, const Offset(256, 150), 47, 55, const Color(0xFF141619));
      _ellipse(canvas, const Offset(240, 146), 3, 3, const Color(0x99777777));
      _ellipse(canvas, const Offset(272, 146), 3, 3, const Color(0x99777777));
    } else {
      _ellipse(canvas, const Offset(256, 150), 43, 52, const Color(0xFFE2B188));
    }
    if (decorated) {
      for (final y in [250.0, 284.0, 318.0, 352.0, 386.0]) {
        _line(canvas, Offset(202, y), Offset(310, y + 10), 3,
            const Color(0xBED6AA4A));
        _ellipse(canvas, Offset(226, y + 4), 5, 5, const Color(0xDD70AE98));
        _ellipse(canvas, Offset(286, y + 8), 5, 5, const Color(0xDDB44D62));
      }
    }
  }

  void _ghutra(Canvas canvas, {bool shmagh = false}) {
    _poly(canvas, [
      const Offset(202, 88),
      const Offset(310, 88),
      const Offset(335, 232),
      const Offset(286, 210),
      const Offset(256, 238),
      const Offset(226, 210),
      const Offset(177, 232),
    ], const Color(0xFFF7F4EB));
    if (shmagh) {
      for (var offset = -70.0; offset <= 70; offset += 24) {
        _line(canvas, Offset(205 + offset, 90), Offset(330 + offset, 224), 3,
            const Color(0xBEBE3F35));
        _line(canvas, Offset(330 - offset, 90), Offset(205 - offset, 224), 3,
            const Color(0xA0BE3F35));
      }
    }
    _line(canvas, const Offset(210, 98), const Offset(302, 98), 13,
        const Color(0xFF1D1C1B));
    _ellipse(canvas, const Offset(256, 148), 50, 62, const Color(0xFFE2B188));
  }

  void _handsAndShoes(Canvas canvas) {
    _ellipse(canvas, const Offset(174, 314), 18, 24, const Color(0xFFE0AC80));
    _ellipse(canvas, const Offset(338, 314), 18, 24, const Color(0xFFE0AC80));
    _ellipse(canvas, const Offset(220, 435), 34, 14, const Color(0xFF3F3A36));
    _ellipse(canvas, const Offset(292, 435), 34, 14, const Color(0xFF3F3A36));
  }

  void _poly(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _ellipse(Canvas canvas, Offset center, double rx, double ry, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()..color = color,
    );
  }

  void _line(Canvas canvas, Offset start, Offset end, double width, Color color) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterAvatarPainter oldDelegate) =>
      oldDelegate.id != id;
}
