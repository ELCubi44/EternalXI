import 'dart:math' as math;
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Icono personalizado de la app.
class XiIcon extends StatelessWidget {
  const XiIcon(
    this.type, {
    super.key,
    this.size = 24.0,
    this.color,
    this.filled = false,
  });

  final XiIconType type;
  final double size;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).iconTheme.color ?? XiColors.techLightGray;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _XiIconPainter(type: type, color: c, filled: filled),
      ),
    );
  }
}

enum XiIconType {
  /// Estadio — pantalla de inicio de liga
  stadium,
  /// Podio — clasificación
  podium,
  /// Campo táctico — plantilla / alineación
  tacticalBoard,
  /// Transferencia — mercado
  transfer,
  /// Ajustes de liga — configuración
  leagueSettings,
  /// Escudo angular — equipo / perfil
  crest,
  /// Balón — fútbol
  ball,
  /// Campana con rayo — notificaciones
  bell,
  /// Monedas apiladas — presupuesto
  coins,
  /// Ficha de jugador — perfil jugador
  playerCard,
  /// Calendario de jornadas
  matchday,
  /// Estrella en explosión — recompensas / tokens
  burstStar,
  /// Flechas dobles — oferta / intercambio
  doubleArrow,
  /// Entrenador — pizarra técnica
  coach,
  /// Capitán — brazalete
  captain,
  /// Candado — liga cerrada
  lock,
  /// Lupa — buscar / catálogo
  search,
}

class _XiIconPainter extends CustomPainter {
  const _XiIconPainter({
    required this.type,
    required this.color,
    required this.filled,
  });

  final XiIconType type;
  final Color color;
  final bool filled;

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  Paint _mixedPaint(bool useFill) => useFill ? _fill : _stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (type) {
      case XiIconType.stadium:
        _drawStadium(canvas, w, h);
      case XiIconType.podium:
        _drawPodium(canvas, w, h);
      case XiIconType.tacticalBoard:
        _drawTacticalBoard(canvas, w, h);
      case XiIconType.transfer:
        _drawTransfer(canvas, w, h);
      case XiIconType.leagueSettings:
        _drawLeagueSettings(canvas, w, h);
      case XiIconType.crest:
        _drawCrest(canvas, w, h);
      case XiIconType.ball:
        _drawBall(canvas, w, h);
      case XiIconType.bell:
        _drawBell(canvas, w, h);
      case XiIconType.coins:
        _drawCoins(canvas, w, h);
      case XiIconType.playerCard:
        _drawPlayerCard(canvas, w, h);
      case XiIconType.matchday:
        _drawMatchday(canvas, w, h);
      case XiIconType.burstStar:
        _drawBurstStar(canvas, w, h);
      case XiIconType.doubleArrow:
        _drawDoubleArrow(canvas, w, h);
      case XiIconType.coach:
        _drawCoach(canvas, w, h);
      case XiIconType.captain:
        _drawCaptain(canvas, w, h);
      case XiIconType.lock:
        _drawLock(canvas, w, h);
      case XiIconType.search:
        _drawSearch(canvas, w, h);
    }
  }

  // ─── Estadio ────────────────────────────────────────────────
  void _drawStadium(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Techo arqueado
    final roofPath = Path()
      ..moveTo(w * 0.08, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.06, w * 0.92, h * 0.50);
    canvas.drawPath(roofPath, p);
    // Tribuna izquierda
    canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(w * 0.08, h * 0.86), p);
    // Tribuna derecha
    canvas.drawLine(Offset(w * 0.92, h * 0.50), Offset(w * 0.92, h * 0.86), p);
    // Base
    canvas.drawLine(Offset(w * 0.08, h * 0.86), Offset(w * 0.92, h * 0.86), p);
    // Césped interior (rectángulo pequeño)
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.52, w * 0.48, h * 0.28),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, p);
    // Círculo central del campo
    canvas.drawCircle(Offset(w * 0.50, h * 0.66), w * 0.06, p);
    // Línea de mediocampo
    canvas.drawLine(Offset(w * 0.26, h * 0.66), Offset(w * 0.74, h * 0.66), p);
  }

  // ─── Podio ───────────────────────────────────────────────────
  void _drawPodium(Canvas canvas, double w, double h) {
    final p = _stroke;
    final fp = _fill;
    // Tres escalones
    // Escalón 2 (izquierda, bajo)
    final step2 = Path()
      ..moveTo(w * 0.06, h * 0.88)
      ..lineTo(w * 0.06, h * 0.62)
      ..lineTo(w * 0.35, h * 0.62)
      ..lineTo(w * 0.35, h * 0.88)
      ..close();
    canvas.drawPath(step2, p);
    // Escalón 1 (centro, alto)
    final step1 = Path()
      ..moveTo(w * 0.33, h * 0.88)
      ..lineTo(w * 0.33, h * 0.44)
      ..lineTo(w * 0.67, h * 0.44)
      ..lineTo(w * 0.67, h * 0.88)
      ..close();
    canvas.drawPath(step1, p);
    // Escalón 3 (derecha, bajo-medio)
    final step3 = Path()
      ..moveTo(w * 0.65, h * 0.88)
      ..lineTo(w * 0.65, h * 0.54)
      ..lineTo(w * 0.94, h * 0.54)
      ..lineTo(w * 0.94, h * 0.88)
      ..close();
    canvas.drawPath(step3, p);
    // Números: líneas simbólicas
    // "1" - centro
    canvas.drawLine(Offset(w * 0.50, h * 0.36), Offset(w * 0.50, h * 0.22), p);
    // "2" - izquierda: dos líneas
    final two = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.16, h * 0.52), Offset(w * 0.26, h * 0.52), two);
    canvas.drawLine(Offset(w * 0.14, h * 0.56), Offset(w * 0.28, h * 0.56), two);
    // Corona encima del 1
    final crown = Path()
      ..moveTo(w * 0.38, h * 0.20)
      ..lineTo(w * 0.43, h * 0.11)
      ..lineTo(w * 0.50, h * 0.17)
      ..lineTo(w * 0.57, h * 0.11)
      ..lineTo(w * 0.62, h * 0.20)
      ..close();
    canvas.drawPath(crown, filled ? fp : p);
  }

  // ─── Pizarra táctica ────────────────────────────────────────
  void _drawTacticalBoard(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Campo (rectángulo exterior)
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.80),
      const Radius.circular(3),
    );
    canvas.drawRRect(fieldRect, p);
    // Línea de mediocampo horizontal
    canvas.drawLine(Offset(w * 0.08, h * 0.50), Offset(w * 0.92, h * 0.50), p);
    // Círculo central
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.10, p);
    // Área superior (pequeña)
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.10, w * 0.40, h * 0.16), p);
    // Área inferior (pequeña)
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.74, w * 0.40, h * 0.16), p);
    // Jugadores: 3 puntos arriba, 2 puntos centro, 1 abajo
    final dp = Paint()..color = color..style = PaintingStyle.fill;
    const r = 2.2;
    for (final d in [
      [0.25, 0.22], [0.50, 0.22], [0.75, 0.22],
      [0.33, 0.39], [0.67, 0.39],
      [0.50, 0.64],
    ]) {
      canvas.drawCircle(Offset(w * d[0], h * d[1]), r, dp);
    }
  }

  // ─── Transferencia ──────────────────────────────────────────
  void _drawTransfer(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Flecha hacia la derecha (arriba)
    final arrowR = Path()
      ..moveTo(w * 0.10, h * 0.34)
      ..lineTo(w * 0.70, h * 0.34)
      ..lineTo(w * 0.60, h * 0.22)
      ..moveTo(w * 0.70, h * 0.34)
      ..lineTo(w * 0.60, h * 0.46);
    canvas.drawPath(arrowR, p);
    // Flecha hacia la izquierda (abajo)
    final arrowL = Path()
      ..moveTo(w * 0.90, h * 0.66)
      ..lineTo(w * 0.30, h * 0.66)
      ..lineTo(w * 0.40, h * 0.54)
      ..moveTo(w * 0.30, h * 0.66)
      ..lineTo(w * 0.40, h * 0.78);
    canvas.drawPath(arrowL, p);
    // Silueta de jugador (círculo + líneas)
    canvas.drawCircle(Offset(w * 0.50, h * 0.27), w * 0.07, p);
    canvas.drawLine(Offset(w * 0.50, h * 0.34), Offset(w * 0.50, h * 0.50), p);
  }

  // ─── Ajustes de liga ────────────────────────────────────────
  void _drawLeagueSettings(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Hexágono de engranaje simplificado: círculo exterior + círculo interior + 6 dientes
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.22, p);
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.10, p);
    // 6 dientes del engranaje
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final innerR = w * 0.22;
      final outerR = w * 0.36;
      final halfAngle = math.pi / 14;
      final path = Path()
        ..moveTo(
          w * 0.50 + innerR * math.cos(angle - halfAngle),
          h * 0.50 + innerR * math.sin(angle - halfAngle),
        )
        ..lineTo(
          w * 0.50 + outerR * math.cos(angle - halfAngle),
          h * 0.50 + outerR * math.sin(angle - halfAngle),
        )
        ..lineTo(
          w * 0.50 + outerR * math.cos(angle + halfAngle),
          h * 0.50 + outerR * math.sin(angle + halfAngle),
        )
        ..lineTo(
          w * 0.50 + innerR * math.cos(angle + halfAngle),
          h * 0.50 + innerR * math.sin(angle + halfAngle),
        );
      canvas.drawPath(path, p);
    }
  }

  // ─── Escudo angular ─────────────────────────────────────────
  void _drawCrest(Canvas canvas, double w, double h) {
    final p = _mixedPaint(filled);
    if (!filled) p.strokeWidth = 1.6;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.90, h * 0.18)
      ..lineTo(w * 0.90, h * 0.56)
      ..quadraticBezierTo(w * 0.90, h * 0.78, w * 0.50, h * 0.94)
      ..quadraticBezierTo(w * 0.10, h * 0.78, w * 0.10, h * 0.56)
      ..lineTo(w * 0.10, h * 0.18)
      ..close();
    canvas.drawPath(path, p);
    if (filled) {
      // Línea divisoria interna
      canvas.drawLine(Offset(w * 0.50, h * 0.06), Offset(w * 0.50, h * 0.94), _stroke..strokeWidth = 1.0);
      canvas.drawLine(Offset(w * 0.10, h * 0.46), Offset(w * 0.90, h * 0.46), _stroke..strokeWidth = 1.0);
    } else {
      // División interna ligera
      final inner = Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawLine(Offset(w * 0.50, h * 0.06), Offset(w * 0.50, h * 0.90), inner);
      canvas.drawLine(Offset(w * 0.10, h * 0.44), Offset(w * 0.90, h * 0.44), inner);
    }
  }

  // ─── Balón ──────────────────────────────────────────────────
  void _drawBall(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Círculo exterior
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.38, p);
    // Pentágono central
    _drawRegularPolygon(canvas, Offset(w * 0.50, h * 0.50), w * 0.13, 5, p);
    // 5 líneas desde el centro al borde (patrón balón)
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      final startR = w * 0.13;
      final endR = w * 0.30;
      canvas.drawLine(
        Offset(w * 0.50 + startR * math.cos(angle), h * 0.50 + startR * math.sin(angle)),
        Offset(w * 0.50 + endR * math.cos(angle), h * 0.50 + endR * math.sin(angle)),
        p,
      );
    }
  }

  void _drawRegularPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / sides;
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ─── Campana con rayo ───────────────────────────────────────
  void _drawBell(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Cuerpo de la campana
    final bell = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..quadraticBezierTo(w * 0.20, h * 0.12, w * 0.18, h * 0.56)
      ..lineTo(w * 0.82, h * 0.56)
      ..quadraticBezierTo(w * 0.80, h * 0.12, w * 0.50, h * 0.08);
    canvas.drawPath(bell, p);
    // Base / aldabón
    canvas.drawLine(Offset(w * 0.14, h * 0.58), Offset(w * 0.86, h * 0.58), p);
    // Badajo
    final arc = Path()
      ..addArc(Rect.fromCenter(center: Offset(w * 0.50, h * 0.64), width: w * 0.20, height: h * 0.12), 0, math.pi);
    canvas.drawPath(arc, p);
    // Rayo pequeño (notificación)
    final bolt = Path()
      ..moveTo(w * 0.60, h * 0.14)
      ..lineTo(w * 0.54, h * 0.26)
      ..lineTo(w * 0.58, h * 0.26)
      ..lineTo(w * 0.52, h * 0.38)
      ..lineTo(w * 0.64, h * 0.22)
      ..lineTo(w * 0.60, h * 0.22)
      ..close();
    canvas.drawPath(bolt, _fill);
  }

  // ─── Monedas apiladas ────────────────────────────────────────
  void _drawCoins(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Moneda del fondo (derecha)
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.60, h * 0.68), width: w * 0.42, height: h * 0.20), p);
    canvas.drawLine(Offset(w * 0.39, h * 0.68), Offset(w * 0.39, h * 0.58), p);
    canvas.drawLine(Offset(w * 0.81, h * 0.68), Offset(w * 0.81, h * 0.58), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.60, h * 0.58), width: w * 0.42, height: h * 0.20), p);
    // Moneda frontal (izquierda-centro)
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.40, h * 0.50), width: w * 0.42, height: h * 0.20), p);
    canvas.drawLine(Offset(w * 0.19, h * 0.50), Offset(w * 0.19, h * 0.34), p);
    canvas.drawLine(Offset(w * 0.61, h * 0.50), Offset(w * 0.61, h * 0.34), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.40, h * 0.34), width: w * 0.42, height: h * 0.20), p);
    // Símbolo "$" simplificado en moneda frontal
    canvas.drawLine(Offset(w * 0.40, h * 0.28), Offset(w * 0.40, h * 0.40), p..strokeWidth = 1.0);
  }

  // ─── Ficha de jugador ───────────────────────────────────────
  void _drawPlayerCard(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Tarjeta
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.72, h * 0.84),
      const Radius.circular(3),
    );
    canvas.drawRRect(card, p);
    // Cabeza del jugador
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), w * 0.14, p);
    // Cuerpo/silueta (triángulo invertido)
    final body = Path()
      ..moveTo(w * 0.30, h * 0.70)
      ..lineTo(w * 0.50, h * 0.46)
      ..lineTo(w * 0.70, h * 0.70)
      ..close();
    canvas.drawPath(body, p);
    // Línea de rating
    canvas.drawLine(Offset(w * 0.24, h * 0.78), Offset(w * 0.76, h * 0.78), p..strokeWidth = 1.0);
    // Pequeña estrella de valoración
    _drawSmallStar(canvas, Offset(w * 0.50, h * 0.85), w * 0.06, _fill);
  }

  void _drawSmallStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * 0.45;
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ─── Calendario de jornadas ─────────────────────────────────
  void _drawMatchday(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Marco del calendario
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.76),
      const Radius.circular(3),
    );
    canvas.drawRRect(frame, p);
    // Cabecera del calendario
    canvas.drawLine(Offset(w * 0.08, h * 0.38), Offset(w * 0.92, h * 0.38), p);
    // Argollas
    canvas.drawLine(Offset(w * 0.30, h * 0.10), Offset(w * 0.30, h * 0.26), p);
    canvas.drawLine(Offset(w * 0.70, h * 0.10), Offset(w * 0.70, h * 0.26), p);
    // Puntos del calendario (6 días)
    final dp = Paint()..color = color..style = PaintingStyle.fill;
    const positions = [
      [0.25, 0.52], [0.50, 0.52], [0.75, 0.52],
      [0.25, 0.70], [0.50, 0.70], [0.75, 0.70],
    ];
    for (final pos in positions) {
      canvas.drawCircle(Offset(w * pos[0], h * pos[1]), 2.5, dp);
    }
    // Balón pequeño (día destacado)
    canvas.drawCircle(Offset(w * 0.75, h * 0.52), w * 0.09, p..strokeWidth = 1.2);
  }

  // ─── Estrella en explosión ───────────────────────────────────
  void _drawBurstStar(Canvas canvas, double w, double h) {
    final fp = _fill;
    final p = _stroke;
    // Estrella de 8 puntas (recompensa)
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final r = i.isEven ? w * 0.40 : w * 0.22;
      final point = Offset(w * 0.50 + r * math.cos(angle), h * 0.50 + r * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, filled ? fp : p);
    // Círculo central
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.13, filled ? (Paint()..color = XiColors.background..style = PaintingStyle.fill) : p);
  }

  // ─── Doble flecha ───────────────────────────────────────────
  void _drawDoubleArrow(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Flecha superior derecha
    final a1 = Path()
      ..moveTo(w * 0.14, h * 0.36)
      ..lineTo(w * 0.70, h * 0.36)
      ..moveTo(w * 0.62, h * 0.24)
      ..lineTo(w * 0.70, h * 0.36)
      ..lineTo(w * 0.62, h * 0.48);
    canvas.drawPath(a1, p);
    // Flecha inferior izquierda
    final a2 = Path()
      ..moveTo(w * 0.86, h * 0.64)
      ..lineTo(w * 0.30, h * 0.64)
      ..moveTo(w * 0.38, h * 0.52)
      ..lineTo(w * 0.30, h * 0.64)
      ..lineTo(w * 0.38, h * 0.76);
    canvas.drawPath(a2, p);
    // Línea diagonal separadora
    canvas.drawLine(Offset(w * 0.80, h * 0.20), Offset(w * 0.20, h * 0.80), p..strokeWidth = 0.6..color = color.withValues(alpha: 0.4));
  }

  // ─── Entrenador / pizarra ───────────────────────────────────
  void _drawCoach(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Pizarra (rectángulo con esquinas redondeadas)
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.12, w * 0.80, h * 0.66),
      const Radius.circular(4),
    );
    canvas.drawRRect(board, p);
    // Soporte inferior
    canvas.drawLine(Offset(w * 0.38, h * 0.78), Offset(w * 0.32, h * 0.90), p);
    canvas.drawLine(Offset(w * 0.62, h * 0.78), Offset(w * 0.68, h * 0.90), p);
    canvas.drawLine(Offset(w * 0.30, h * 0.90), Offset(w * 0.70, h * 0.90), p);
    // Campo dibujado en pizarra
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.60, h * 0.46), p..strokeWidth = 1.0);
    canvas.drawLine(Offset(w * 0.20, h * 0.45), Offset(w * 0.80, h * 0.45), p);
    // Flechas tácticas
    final tactic = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.33, h * 0.32), Offset(w * 0.50, h * 0.38), tactic);
    canvas.drawLine(Offset(w * 0.67, h * 0.32), Offset(w * 0.50, h * 0.38), tactic);
    // Flecha final
    canvas.drawLine(Offset(w * 0.50, h * 0.38), Offset(w * 0.50, h * 0.56), tactic);
    canvas.drawLine(Offset(w * 0.44, h * 0.50), Offset(w * 0.50, h * 0.58), tactic);
    canvas.drawLine(Offset(w * 0.56, h * 0.50), Offset(w * 0.50, h * 0.58), tactic);
  }

  // ─── Capitán (brazalete C) ──────────────────────────────────
  void _drawCaptain(Canvas canvas, double w, double h) {
    final p = _stroke..strokeWidth = 1.8;
    // Círculo exterior del brazalete
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.38, p);
    // Letra "C" interior gruesa
    final arc = Path()..addArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.50), width: w * 0.44, height: h * 0.44),
      math.pi * 0.3,
      math.pi * 1.4,
    );
    canvas.drawPath(arc, p..strokeWidth = 2.4);
    // Decoración: dos pequeñas estrellas
    _drawSmallStar(canvas, Offset(w * 0.50, h * 0.16), w * 0.08, _fill);
    _drawSmallStar(canvas, Offset(w * 0.50, h * 0.84), w * 0.08, _fill);
  }

  // ─── Candado ─────────────────────────────────────────────────
  void _drawLock(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Cuerpo del candado
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.48, w * 0.64, h * 0.46),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, p);
    // Arco superior
    final arc = Path()
      ..moveTo(w * 0.30, h * 0.48)
      ..lineTo(w * 0.30, h * 0.34)
      ..quadraticBezierTo(w * 0.30, h * 0.12, w * 0.50, h * 0.12)
      ..quadraticBezierTo(w * 0.70, h * 0.12, w * 0.70, h * 0.34)
      ..lineTo(w * 0.70, h * 0.48);
    canvas.drawPath(arc, p);
    // Ojo del candado
    canvas.drawCircle(Offset(w * 0.50, h * 0.66), w * 0.08, p);
    canvas.drawLine(Offset(w * 0.50, h * 0.74), Offset(w * 0.50, h * 0.82), p);
  }

  // ─── Lupa / Búsqueda ────────────────────────────────────────
  void _drawSearch(Canvas canvas, double w, double h) {
    final p = _stroke;
    // Círculo de la lupa
    canvas.drawCircle(Offset(w * 0.40, h * 0.40), w * 0.26, p);
    // Mango
    final handle = Path()
      ..moveTo(w * 0.60, h * 0.60)
      ..lineTo(w * 0.84, h * 0.84);
    canvas.drawPath(handle, p..strokeWidth = 2.2);
    // Símbolo "+" en el interior (catálogo)
    canvas.drawLine(Offset(w * 0.40, h * 0.28), Offset(w * 0.40, h * 0.52), p..strokeWidth = 1.4);
    canvas.drawLine(Offset(w * 0.28, h * 0.40), Offset(w * 0.52, h * 0.40), p..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_XiIconPainter old) =>
      old.type != type || old.color != color || old.filled != filled;
}

/// Versión compacta para usar en [NavigationDestination].
class XiNavIcon extends StatelessWidget {
  const XiNavIcon(this.type, {super.key, this.selected = false});

  final XiIconType type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return XiIcon(
      type,
      size: 24,
      color: selected ? XiColors.techCyan : XiColors.steelGray,
      filled: selected,
    );
  }
}
