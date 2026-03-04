import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_engine.dart';
import 'entities/enemy.dart';
import 'entities/projectile.dart';
import 'entities/pickup.dart';
import 'data/enemy_data.dart';
import 'data/sprite_data.dart';
import 'ui/game_hud.dart';
import 'ui/levelup_modal.dart';
import 'ui/game_over_screen.dart';
import '../../utils/game_colors.dart';

class SurvivorGame extends StatefulWidget {
  final String lang;
  final VoidCallback onBack;

  const SurvivorGame({
    super.key,
    required this.lang,
    required this.onBack,
  });

  @override
  State<SurvivorGame> createState() => _SurvivorGameState();
}

class _SurvivorGameState extends State<SurvivorGame>
    with TickerProviderStateMixin {
  // Terminal colors (GameColors에서 참조)
  static const Color _termGreen = GameColors.survivorGreen;
  static const Color _termBg = GameColors.survivorBg;

  // Game engine
  late GameEngine _engine;

  // Game loop
  late AnimationController _gameLoopController;
  DateTime _lastFrameTime = DateTime.now();
  int _blinkCounter = 0;

  // Joystick state
  Offset? _joystickStart;
  Offset _joystickCurrent = Offset.zero;
  double _joystickX = 0;
  double _joystickY = 0;
  DateTime? _joystickTouchStart;

  // Level-up choices
  List<LevelUpChoice> _levelUpChoices = [];

  // Scores
  List<int> _topScores = [];
  static const String _topScoresKey = 'survivor_top_scores';

  // Game state flags
  bool _isStarted = false;
  bool _showDebug = false;
  bool _screenSizeReady = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _loadScores();

    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _gameLoopController.repeat();
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    super.dispose();
  }

  void _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_topScoresKey);
    if (str != null && str.isNotEmpty) {
      _topScores = str
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();
    }
  }

  void _saveScore(int score) async {
    _topScores.add(score);
    _topScores.sort((a, b) => b.compareTo(a));
    if (_topScores.length > 5) _topScores = _topScores.sublist(0, 5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topScoresKey, _topScores.join(','));
  }

  void _startGame() {
    _engine = GameEngine();
    _isStarted = true;
    _screenSizeReady = false;
    _lastFrameTime = DateTime.now();
    _levelUpChoices.clear();
    // Give 2 seconds of invincibility at start
    _engine.player.invincibilityTimer = 2.0;
    setState(() {});
  }

  void _gameLoop() {
    final now = DateTime.now();
    final dt =
        (now.difference(_lastFrameTime).inMicroseconds / 1000000.0).clamp(0.0, 0.1);
    _lastFrameTime = now;
    _blinkCounter++;

    // Always call setState for UI animations (blink, etc.)
    setState(() {
      if (!_isStarted || !_screenSizeReady) return;

      _engine.update(dt, _joystickX, _joystickY);

      // Handle phase transitions
      if (_engine.phase == GamePhase.levelUp && _levelUpChoices.isEmpty) {
        _levelUpChoices = _engine.generateChoices();
      }
      if (_engine.phase == GamePhase.gameOver) {
        _gameLoopController.stop();
        _saveScore(_engine.finalScore.toInt());
      }
    });
  }

  void _onLevelUpChoice(LevelUpChoice choice) {
    setState(() {
      _engine.applyChoice(choice);
      _levelUpChoices.clear();
      if (_engine.phase == GamePhase.levelUp) {
        _levelUpChoices = _engine.generateChoices();
      }
    });
  }

  void _restartGame() {
    _gameLoopController.repeat();
    _startGame();
  }

  // — Joystick handlers —

  void _onJoystickDown(DragStartDetails details) {
    _joystickStart = details.localPosition;
    _joystickCurrent = details.localPosition;
    _joystickTouchStart = DateTime.now();
  }

  void _onJoystickUpdate(DragUpdateDetails details) {
    if (_joystickStart == null) return;
    _joystickCurrent = details.localPosition;
    final delta = _joystickCurrent - _joystickStart!;
    const maxRadius = 50.0;
    final distance = delta.distance.clamp(0.0, maxRadius);
    if (distance > 5) {
      final normalized = delta / delta.distance;
      final clamped = normalized * (distance / maxRadius);
      _joystickX = clamped.dx;
      _joystickY = clamped.dy;
    } else {
      _joystickX = 0;
      _joystickY = 0;
    }
  }

  void _onJoystickUp(DragEndDetails details) {
    // Flick detection for dash
    if (_joystickStart != null && _joystickTouchStart != null) {
      final touchDuration =
          DateTime.now().difference(_joystickTouchStart!).inMilliseconds;
      final velocity = details.velocity.pixelsPerSecond;
      if (touchDuration < 200 && velocity.distance > 500) {
        final dir = velocity / velocity.distance;
        _engine.player.tryDash(dir.dx, dir.dy);
      }
    }
    _joystickStart = null;
    _joystickX = 0;
    _joystickY = 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: Container(
        color: _termBg,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _isStarted ? _buildGameView() : _buildStartScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 32,
      color: _termBg,
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '< BACK',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: _termGreen.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onDoubleTap: () => setState(() => _showDebug = !_showDebug),
            child: const Text(
              'HOXXES SURVIVAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _termGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startGame,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scout wireframe preview
              SizedBox(
                width: 80,
                height: 100,
                child: CustomPaint(
                  painter: _ScoutPreviewPainter(blinkCounter: _blinkCounter),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'HOXXES SURVIVAL',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: _termGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Survive the Glyphid swarm!',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: _termGreen.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              _blinkCounter % 60 < 40
                  ? Text(
                      '[ TAP TO START ]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _termGreen.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        _engine.setScreenSize(w, h);

        // Mark screen ready on first valid layout
        if (!_screenSizeReady && w > 0 && h > 0) {
          _screenSizeReady = true;
        }

        return Stack(
          children: [
            // Game canvas + joystick input — BOTTOM of stack, receives all touch
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onJoystickDown,
              onPanUpdate: _onJoystickUpdate,
              onPanEnd: _onJoystickUp,
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: _GamePainter(
                    engine: _engine,
                    blinkCounter: _blinkCounter,
                    joystickStart: _joystickStart,
                    joystickCurrent: _joystickCurrent,
                  ),
                ),
              ),
            ),

            // HUD overlay — IgnorePointer so touches pass through
            IgnorePointer(
              child: CustomPaint(
                painter: GameHudPainter(
                  hp: _engine.player.hp,
                  maxHp: _engine.player.maxHp,
                  xp: _engine.player.xp,
                  xpToNextLevel: _engine.player.xpToNextLevel,
                  level: _engine.player.level,
                  wave: _engine.wave,
                  gameTime: _engine.gameTimer,
                  killCount: _engine.killCount,
                  dashReady: _engine.player.dashCooldown <= 0,
                ),
                size: Size(w, h),
              ),
            ),

            // CRT scanlines overlay
            IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinePainter(),
                size: Size(w, h),
              ),
            ),

            // Level-up modal (blocks input intentionally)
            if (_engine.phase == GamePhase.levelUp && _levelUpChoices.isNotEmpty)
              LevelUpModal(
                level: _engine.player.level,
                choices: _levelUpChoices,
                onSelect: _onLevelUpChoice,
              ),

            // Debug overlay
            if (_showDebug)
              IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Text(
                      'P: ${_engine.player.x.toInt()},${_engine.player.y.toInt()}\n'
                      'E: ${_engine.enemies.length}  B: ${_engine.projectiles.length}\n'
                      'PK: ${_engine.pickups.length}  JOY: ${_joystickX.toStringAsFixed(1)},${_joystickY.toStringAsFixed(1)}\n'
                      'Phase: ${_engine.phase.name}  Dash: ${_engine.player.dashCooldown.toStringAsFixed(1)}\n'
                      'HP: ${_engine.player.hp.toInt()}/${_engine.player.maxHp.toInt()}  INV: ${_engine.player.invincibilityTimer.toStringAsFixed(1)}\n'
                      'Screen: ${w.toInt()}x${h.toInt()}  Ready: $_screenSizeReady',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        color: Color(0xFF00FF41),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

            // Game over screen
            if (_engine.phase == GamePhase.gameOver)
              GameOverScreen(
                killCount: _engine.killCount,
                wave: _engine.wave,
                gameTime: _engine.gameTimer,
                score: _engine.finalScore,
                level: _engine.player.level,
                topScores: _topScores,
                onRestart: _restartGame,
                onBack: widget.onBack,
              ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════
//  Game Painter — renders all game entities
// ═════════════════════════════════════════════

class _GamePainter extends CustomPainter {
  final GameEngine engine;
  final int blinkCounter;
  final Offset? joystickStart;
  final Offset joystickCurrent;

  static const Color _termGreen = Color(0xFF00FF41);
  static const Color _termGreenFaint = Color(0xFF00FF41);
  static const Color _termAmber = Color(0xFFFFB000);
  static const Color _termRed = Color(0xFFFF3333);
  static const Color _termBg = Color(0xFF0A0E0A);
  static const Color _xpColor = Color(0xFF00CCFF);
  static const Color _goldColor = Color(0xFFFFD700);

  _GamePainter({
    required this.engine,
    required this.blinkCounter,
    required this.joystickStart,
    required this.joystickCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final px = engine.player.x;
    final py = engine.player.y;

    // Camera offset: player is always at center
    final camX = px - cx;
    final camY = py - cy;

    // Background CRT grid
    _drawCrtGrid(canvas, size, camX, camY);

    // Pickups
    for (final pickup in engine.pickups) {
      _drawPickup(canvas, pickup, camX, camY);
    }

    // Enemies
    for (final enemy in engine.enemies) {
      _drawEnemy(canvas, enemy, camX, camY, size);
    }

    // Projectiles
    for (final proj in engine.projectiles) {
      _drawProjectile(canvas, proj, camX, camY);
    }

    // Player (always at screen center)
    _drawPlayer(canvas, cx, cy);

    // Damage numbers
    for (final dmg in engine.damageNumbers) {
      _drawDamageNumber(canvas, dmg, camX, camY);
    }

    // Joystick visual
    if (joystickStart != null) {
      _drawJoystick(canvas);
    }
  }

  void _drawCrtGrid(Canvas canvas, Size size, double camX, double camY) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _termBg,
    );

    final gridPaint = Paint()
      ..color = _termGreenFaint.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;
    final offsetX = -(camX % gridSize);
    final offsetY = -(camY % gridSize);

    for (double x = offsetX; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = offsetY; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawAsciiSprite(Canvas canvas, List<String> lines, double sx, double sy,
      Color color, {double? fontSize, double? fitRadius}) {
    double size;
    if (fontSize != null) {
      size = fontSize;
    } else if (fitRadius != null) {
      final maxW = lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
      final byW = (2 * fitRadius) / (maxW * 0.55);
      final byH = (2 * fitRadius) / (lines.length * 1.1);
      size = (byW < byH ? byW : byH).clamp(4.0, 16.0);
    } else {
      size = 8.0;
    }
    final text = lines.join('\n');
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: size,
          color: color,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(sx - tp.width / 2, sy - tp.height / 2));
  }

  void _drawPlayer(Canvas canvas, double screenX, double screenY) {
    final p = engine.player;
    // Invincibility blink
    if (p.isInvincible && blinkCounter % 6 < 3) return;

    final color = p.isDashing ? _termAmber : _termGreen;

    // Dash trail
    if (p.isDashing) {
      canvas.drawCircle(
        Offset(screenX, screenY),
        20,
        Paint()
          ..color = _termAmber.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // ASCII scout sprite with headlamp blink
    final sprite = (blinkCounter % 30 < 15) ? scoutSprite : scoutLampOffSprite;
    _drawAsciiSprite(canvas, sprite, screenX, screenY, color, fontSize: 9.0);

    // Facing direction indicator
    final fx = cos(p.facingAngle) * 18;
    final fy = sin(p.facingAngle) * 18;
    canvas.drawLine(
      Offset(screenX, screenY),
      Offset(screenX + fx, screenY + fy),
      Paint()
        ..color = _termGreen.withValues(alpha: 0.25)
        ..strokeWidth = 1,
    );
  }

  void _drawEnemy(Canvas canvas, Enemy e, double camX, double camY, Size size) {
    final sx = e.x - camX;
    final sy = e.y - camY;

    // Culling: skip if off-screen
    if (sx < -40 || sx > size.width + 40 || sy < -40 || sy > size.height + 40) {
      return;
    }

    final color = e.hitFlashTimer > 0 ? Colors.white : _getEnemyColor(e.type);

    // Bulk Detonator glow pulse
    final pulse = e.type == EnemyType.bulkDetonator && blinkCounter % 20 < 10;
    final sprite = getEnemySprite(e.type, pulse: pulse);

    _drawAsciiSprite(canvas, sprite, sx, sy, color, fitRadius: e.radius);

    // HP bar for bosses or tough enemies
    if (e.isBoss || e.maxHp > 50) {
      _drawEnemyHpBar(canvas, e, sx, sy);
    }
  }

  void _drawEnemyHpBar(Canvas canvas, Enemy e, double sx, double sy) {
    final barWidth = e.radius * 2;
    const barHeight = 3.0;
    final barY = sy - e.radius - 6;
    final ratio = (e.hp / e.maxHp).clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(sx - barWidth / 2, barY, barWidth, barHeight),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawRect(
      Rect.fromLTWH(sx - barWidth / 2, barY, barWidth * ratio, barHeight),
      Paint()..color = e.isBoss ? _termAmber : _termRed,
    );
  }

  Color _getEnemyColor(EnemyType type) {
    switch (type) {
      case EnemyType.grunt:
        return _termRed;
      case EnemyType.swarmer:
        return const Color(0xFFFF6666);
      case EnemyType.guard:
        return _termAmber;
      case EnemyType.praetorian:
        return const Color(0xFFFF00FF);
      case EnemyType.oppressor:
        return const Color(0xFFFF4400);
      case EnemyType.dreadnought:
        return const Color(0xFFFF0000);
      case EnemyType.bulkDetonator:
        return const Color(0xFFFF8800);
    }
  }

  void _drawProjectile(Canvas canvas, Projectile p, double camX, double camY) {
    final sx = p.x - camX;
    final sy = p.y - camY;

    // Boltshark projectiles are white; others are amber
    final color = p.weaponId == 'boltshark' ? Colors.white : _termAmber;

    // Small bright line in direction of travel
    const len = 6.0;
    canvas.drawLine(
      Offset(sx - cos(p.angle) * len, sy - sin(p.angle) * len),
      Offset(sx, sy),
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );

    // Glow
    canvas.drawCircle(
      Offset(sx, sy),
      2,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawPickup(Canvas canvas, Pickup p, double camX, double camY) {
    final sx = p.displayX - camX;
    final sy = p.displayY - camY;

    final color = p.type == PickupType.xp ? _xpColor : _goldColor;
    final symbol = p.type == PickupType.xp ? '\u25C7' : '\u25CF';

    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: p.type == PickupType.xp ? 8.0 : 10.0,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(sx - tp.width / 2, sy - tp.height / 2));

    // Glow
    canvas.drawCircle(
      Offset(sx, sy),
      4,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawDamageNumber(Canvas canvas, DamageNumber d, double camX, double camY) {
    final sx = d.x - camX;
    final sy = d.y - camY;
    final alpha = (d.timer / 0.6).clamp(0.0, 1.0);

    final tp = TextPainter(
      text: TextSpan(
        text: d.damage.toInt().toString(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: _termAmber.withValues(alpha: alpha),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(sx - tp.width / 2, sy));
  }

  void _drawJoystick(Canvas canvas) {
    if (joystickStart == null) return;

    // Outer ring
    canvas.drawCircle(
      joystickStart!,
      50,
      Paint()
        ..color = _termGreen.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Center dot
    canvas.drawCircle(
      joystickStart!,
      3,
      Paint()..color = _termGreen.withValues(alpha: 0.2),
    );

    // Inner knob
    final delta = joystickCurrent - joystickStart!;
    final dist = delta.distance.clamp(0.0, 50.0);
    final clampedPos = dist > 0
        ? joystickStart! + (delta / delta.distance) * dist
        : joystickStart!;

    canvas.drawCircle(
      clampedPos,
      12,
      Paint()..color = _termGreen.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      clampedPos,
      12,
      Paint()
        ..color = _termGreen.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}

// ═════════════════════════════════════════════
//  CRT Scanline overlay
// ═════════════════════════════════════════════

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.06);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═════════════════════════════════════════════
//  Scout preview painter (start screen)
// ═════════════════════════════════════════════

class _ScoutPreviewPainter extends CustomPainter {
  final int blinkCounter;
  static const Color _termGreen = Color(0xFF00FF41);

  _ScoutPreviewPainter({required this.blinkCounter});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Headlamp blink
    final sprite = (blinkCounter % 40 < 30)
        ? scoutPreviewSprite
        : scoutPreviewLampOffSprite;

    final text = sprite.join('\n');
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: _termGreen,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ScoutPreviewPainter old) =>
      blinkCounter ~/ 40 != old.blinkCounter ~/ 40;
}
