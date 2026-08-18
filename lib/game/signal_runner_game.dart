import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Alignment, LinearGradient;

class BattleSnapshot {
  const BattleSnapshot({
    this.enemyHealth = 3,
    this.lives = 3,
    this.defeated = 0,
    this.flash = 0,
    this.perfectFlash = false,
    this.enemyVariant = 0,
  });

  /// Compatibility field: now represents remaining stabilization steps
  /// for the active relay instead of enemy health.
  final int enemyHealth;

  /// Compatibility field: now represents command-network integrity.
  final int lives;

  /// Compatibility field: now represents restored relays.
  final int defeated;

  final double flash;
  final bool perfectFlash;

  /// Compatibility field used as a procedural route variant.
  final int enemyVariant;

  int get relayStrengthRemaining => enemyHealth;
  int get networkIntegrity => lives;
  int get relaysRestored => defeated;
  int get routeVariant => enemyVariant;

  BattleSnapshot copyWith({
    int? enemyHealth,
    int? lives,
    int? defeated,
    double? flash,
    bool? perfectFlash,
    int? enemyVariant,
  }) =>
      BattleSnapshot(
        enemyHealth: enemyHealth ?? this.enemyHealth,
        lives: lives ?? this.lives,
        defeated: defeated ?? this.defeated,
        flash: flash ?? this.flash,
        perfectFlash: perfectFlash ?? this.perfectFlash,
        enemyVariant: enemyVariant ?? this.enemyVariant,
      );
}

/// Code-only tactical communications map.
///
/// Morse targets are never encoded into node position, shape, route, color,
/// animation, or interference behavior. The visual layer reacts only after
/// the player has answered.
class SignalRunnerGame extends FlameGame {
  final ValueNotifier<BattleSnapshot> battle =
      ValueNotifier(const BattleSnapshot());

  final Random _random = Random();

  double _interferenceFront = 0.86;
  double _clock = 0;
  double _signalPulse = 0;
  double _restoreFlash = 0;
  double _flowGlow = 0;
  double _routeSpark = 0;
  int _lastCombo = 0;

  static const List<Offset> _normalizedRelays = [
    Offset(0.29, 0.46),
    Offset(0.39, 0.68),
    Offset(0.49, 0.34),
    Offset(0.58, 0.57),
    Offset(0.68, 0.29),
    Offset(0.75, 0.61),
    Offset(0.84, 0.41),
    Offset(0.91, 0.64),
  ];

  void correct({
    required bool perfect,
    required bool flowMode,
    required int combo,
  }) {
    final old = battle.value;
    final stabilization = perfect ? 2 : 1;
    final remaining = old.enemyHealth - stabilization;

    _signalPulse = 1;
    _routeSpark = 1;
    _restoreFlash = perfect ? 1 : 0.55;
    _lastCombo = combo;
    _interferenceFront = min(0.92, _interferenceFront + 0.025);

    if (flowMode) {
      _flowGlow = 1;
      _interferenceFront = min(0.94, _interferenceFront + 0.018);
    }

    if (remaining <= 0) {
      battle.value = old.copyWith(
        enemyHealth: 3,
        defeated: old.defeated + 1,
        flash: 1,
        perfectFlash: perfect,
        enemyVariant: _random.nextInt(4),
      );
    } else {
      battle.value = old.copyWith(
        enemyHealth: remaining,
        flash: 1,
        perfectFlash: perfect,
      );
    }
  }

  void wrong() {
    final old = battle.value;

    _interferenceFront -= 0.14;
    _signalPulse = 0;
    _routeSpark = 0;
    _lastCombo = 0;
    _flowGlow = 0;

    if (_interferenceFront <= 0.20) {
      battle.value = old.copyWith(
        lives: max(0, old.lives - 1),
        enemyHealth: 3,
        flash: 1,
        perfectFlash: false,
        enemyVariant: _random.nextInt(4),
      );
      _interferenceFront = 0.82;
    } else {
      battle.value = old.copyWith(
        flash: 1,
        perfectFlash: false,
      );
    }
  }

  void restartBattle() {
    battle.value = BattleSnapshot(enemyVariant: _random.nextInt(4));
    _interferenceFront = 0.86;
    _signalPulse = 0;
    _restoreFlash = 0;
    _flowGlow = 0;
    _routeSpark = 0;
    _lastCombo = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _clock += dt;
    _signalPulse = max(0.0, _signalPulse - dt * 2.2);
    _restoreFlash = max(0.0, _restoreFlash - dt * 1.5);
    _flowGlow = max(0.0, _flowGlow - dt * 0.72);
    _routeSpark = max(0.0, _routeSpark - dt * 1.7);

    final current = battle.value;
    if (current.flash > 0) {
      battle.value = current.copyWith(
        flash: max(0.0, current.flash - dt * 2.8),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final bounds = Rect.fromLTWH(0, 0, w, h);

    _drawBackground(canvas, bounds);
    _drawTopographicGrid(canvas, w, h);
    _drawRadarSweep(canvas, w, h);
    _drawNetwork(canvas, w, h);
    _drawInterference(canvas, w, h);

    if (_flowGlow > 0) {
      canvas.drawRect(
        bounds,
        Paint()
          ..color = const Color(0xFF55D6BE).withValues(
            alpha: 0.025 + (_flowGlow * 0.07),
          ),
      );
    }
  }

  void _drawBackground(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF06141D),
          Color(0xFF091A22),
          Color(0xFF071016),
        ],
      ).createShader(bounds);

    canvas.drawRect(bounds, paint);

    // Stable procedural "terrain / RF heat" bands.
    final haze = Paint()
      ..color = const Color(0xFF1B4E5F).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var band = 0; band < 6; band++) {
      final path = Path();
      for (var step = 0; step <= 40; step++) {
        final x = bounds.width * step / 40;
        final baseY =
            bounds.height * (0.23 + band * 0.105);
        final y = baseY +
            sin((step * 0.52) + band * 1.3) * 12 +
            cos((step * 0.23) - band) * 5;

        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, haze);
    }
  }

  void _drawTopographicGrid(Canvas canvas, double w, double h) {
    final grid = Paint()
      ..color = const Color(0xFF3C7180).withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (double x = 0; x <= w; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (double y = 0; y <= h; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final diagonal = Paint()
      ..color = const Color(0xFF55D6BE).withValues(alpha: 0.035)
      ..strokeWidth = 1;

    final drift = (_clock * 12) % 80;
    for (double x = -h + drift; x < w + h; x += 80) {
      canvas.drawLine(
        Offset(x, h),
        Offset(x + h, 0),
        diagonal,
      );
    }
  }

  void _drawRadarSweep(Canvas canvas, double w, double h) {
    final command = Offset(w * 0.11, h * 0.62);
    final maxRadius = min(w, h) * 0.72;

    final ring = Paint()
      ..color = const Color(0xFF55D6BE).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final factor in [0.24, 0.42, 0.60, 0.78]) {
      canvas.drawCircle(command, maxRadius * factor, ring);
    }

    final angle = (_clock * 0.55) % (pi * 2);
    final sweepEnd = Offset(
      command.dx + cos(angle) * maxRadius,
      command.dy + sin(angle) * maxRadius,
    );

    canvas.drawLine(
      command,
      sweepEnd,
      Paint()
        ..color = const Color(0xFF8FFFEA).withValues(alpha: 0.16)
        ..strokeWidth = 2,
    );
  }

  void _drawNetwork(Canvas canvas, double w, double h) {
    final snapshot = battle.value;
    final command = Offset(w * 0.11, h * 0.62);
    final relays = [
      for (final p in _normalizedRelays)
        Offset(w * p.dx, h * p.dy),
    ];

    _drawCommandStation(canvas, command);

    var previous = command;
    for (var i = 0; i < relays.length; i++) {
      final node = relays[i];
      final restored = i < snapshot.relaysRestored;
      final active = i == snapshot.relaysRestored &&
          snapshot.relaysRestored < relays.length;

      final routePaint = Paint()
        ..color = (restored
                ? const Color(0xFF55D6BE)
                : active
                    ? const Color(0xFF90AEB8)
                    : const Color(0xFF35505A))
            .withValues(alpha: restored ? 0.60 : active ? 0.34 : 0.16)
        ..strokeWidth = restored ? 3.2 : 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(previous, node, routePaint);

      if ((restored || active) && _routeSpark > 0) {
        _drawRoutePulse(
          canvas,
          previous,
          node,
          i,
          restored: restored,
        );
      }

      _drawRelay(
        canvas,
        node,
        restored: restored,
        active: active,
        strengthRemaining: active
            ? snapshot.relayStrengthRemaining
            : restored
                ? 0
                : 3,
        index: i,
      );

      previous = node;
    }
  }

  void _drawCommandStation(Canvas canvas, Offset center) {
    final pulse = 1 + sin(_clock * 2.6) * 0.035;
    final activeColor = const Color(0xFF55D6BE);

    canvas.drawCircle(
      center,
      34 * pulse + (_flowGlow * 5),
      Paint()
        ..color = activeColor.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    final tower = Path()
      ..moveTo(center.dx, center.dy - 26)
      ..lineTo(center.dx - 17, center.dy + 23)
      ..lineTo(center.dx + 17, center.dy + 23)
      ..close();

    canvas.drawPath(
      tower,
      Paint()..color = activeColor.withValues(alpha: 0.85),
    );

    canvas.drawCircle(
      Offset(center.dx, center.dy - 16),
      5,
      Paint()..color = const Color(0xFFB8FFF3),
    );
  }

  void _drawRelay(
    Canvas canvas,
    Offset center, {
    required bool restored,
    required bool active,
    required int strengthRemaining,
    required int index,
  }) {
    final pulse = 1 + sin((_clock * 3.2) + index) * 0.04;
    final baseRadius = restored ? 13.0 : active ? 15.0 : 10.0;

    final color = restored
        ? const Color(0xFF55D6BE)
        : active
            ? const Color(0xFFFFD166)
            : const Color(0xFF607882);

    if (active) {
      final completion =
          ((3 - strengthRemaining) / 3).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        27 + (_restoreFlash * 7),
        Paint()
          ..color = color.withValues(
            alpha: 0.16 + (_restoreFlash * 0.12),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 22),
        -pi / 2,
        pi * 2 * completion,
        false,
        Paint()
          ..color = const Color(0xFF55D6BE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      center,
      baseRadius * pulse,
      Paint()..color = color.withValues(alpha: restored ? 0.92 : 0.72),
    );

    canvas.drawCircle(
      center,
      4.5,
      Paint()
        ..color = restored
            ? const Color(0xFFE6FFF9)
            : active
                ? const Color(0xFFFFF2C0)
                : const Color(0xFF99A9AF),
    );
  }

  void _drawRoutePulse(
    Canvas canvas,
    Offset start,
    Offset end,
    int index, {
    required bool restored,
  }) {
    final phase =
        ((_clock * (0.75 + min(0.35, _lastCombo * 0.02))) +
                index * 0.17) %
            1.0;

    final position = Offset.lerp(start, end, phase)!;
    final color = restored
        ? const Color(0xFFB8FFF3)
        : const Color(0xFFFFE7A6);

    canvas.drawCircle(
      position,
      4 + (_signalPulse * 4),
      Paint()
        ..color = color.withValues(
          alpha: 0.45 + (_signalPulse * 0.45),
        ),
    );
  }

  void _drawInterference(Canvas canvas, double w, double h) {
    final x = w * _interferenceFront;
    final danger =
        ((0.88 - _interferenceFront) / 0.68).clamp(0.0, 1.0);

    final field = Paint()
      ..color = const Color(0xFFFF5D73).withValues(
        alpha: 0.035 + (danger * 0.10),
      );

    canvas.drawRect(
      Rect.fromLTWH(x, 0, max(0.0, w - x), h),
      field,
    );

    final frontPaint = Paint()
      ..color = const Color(0xFFFF7A8E).withValues(
        alpha: 0.26 + (danger * 0.30),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    for (var step = 0; step <= 30; step++) {
      final y = h * step / 30;
      final waveX = x +
          sin((step * 0.82) + (_clock * 4.5)) * (7 + danger * 12) +
          cos((step * 0.31) - (_clock * 2.2)) * 4;

      if (step == 0) {
        path.moveTo(waveX, y);
      } else {
        path.lineTo(waveX, y);
      }
    }
    canvas.drawPath(path, frontPaint);

    for (var i = 0; i < 14; i++) {
      final seed = i * 19.0;
      final particleX =
          x + 18 + ((seed * 13 + _clock * (22 + i)) % max(30.0, w - x));
      final particleY =
          ((seed * 29) + _clock * (17 + i * 0.8)) % max(1.0, h);

      canvas.drawCircle(
        Offset(particleX, particleY),
        1.3 + (i % 3),
        Paint()
          ..color = const Color(0xFFFF8FA0).withValues(
            alpha: 0.08 + danger * 0.18,
          ),
      );
    }
  }

  @override
  void onRemove() {
    battle.dispose();
    super.onRemove();
  }
}
