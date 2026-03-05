import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_engine.dart';
import 'entities/enemy.dart';
import 'entities/projectile.dart';
import 'entities/pickup.dart';
import 'data/enemy_data.dart';
import 'data/weapon_data.dart';
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

  // Hazard selection
  int _selectedHazard = 2; // 0-indexed, default Hazard 3 (Dangerous)

  // Weapon loadout
  WeaponId _selectedPrimary = WeaponId.gk2;
  int _totalKills = 0;
  static const String _totalKillsKey = 'survivor_total_kills';

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
    _totalKills = prefs.getInt(_totalKillsKey) ?? 0;
  }

  void _saveScore(int score, int killsThisRun) async {
    _topScores.add(score);
    _topScores.sort((a, b) => b.compareTo(a));
    if (_topScores.length > 5) _topScores = _topScores.sublist(0, 5);
    _totalKills += killsThisRun;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topScoresKey, _topScores.join(','));
    await prefs.setInt(_totalKillsKey, _totalKills);
  }

  void _startGame() {
    _engine = GameEngine(
      primaryWeapon: _selectedPrimary,
      hazard: hazardLevels[_selectedHazard],
    );
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
        _saveScore(_engine.finalScore.toInt(), _engine.killCount);
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
    return Container(
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
              const SizedBox(height: 16),
              // Weapon selection
              Text(
                'PRIMARY WEAPON',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _termGreen.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              ...primaryWeapons.entries.map((entry) {
                final wId = entry.key;
                final wData = entry.value;
                final unlockKills = weaponUnlockKills[wId] ?? 0;
                final isUnlocked = _totalKills >= unlockKills;
                final isSelected = _selectedPrimary == wId;
                return GestureDetector(
                  onTap: isUnlocked
                      ? () => setState(() => _selectedPrimary = wId)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFB000)
                            : isUnlocked
                                ? _termGreen.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                      color: isSelected
                          ? const Color(0xFFFFB000).withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          wData.name,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: isUnlocked
                                ? (isSelected ? const Color(0xFFFFB000) : _termGreen)
                                : Colors.white.withValues(alpha: 0.25),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${unlockKills - _totalKills} kills',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 8,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              // Hazard selection
              Text(
                'HAZARD LEVEL',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _termGreen.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final isSelected = _selectedHazard == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedHazard = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFB000)
                              : _termGreen.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 0.5,
                        ),
                        color: isSelected
                            ? const Color(0xFFFFB000).withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      child: Text(
                        'H${i + 1}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isSelected
                              ? const Color(0xFFFFB000)
                              : _termGreen.withValues(alpha: 0.5),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                hazardLevels[_selectedHazard].name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: const Color(0xFFFFB000).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _startGame,
                child: _blinkCounter % 60 < 40
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
              ),
            ],
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
                  nitra: _engine.nitra,
                  hazardLevel: _engine.hazard.level,
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

            // Grenade button (bottom-right)
            if (_engine.phase == GamePhase.playing)
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => _engine.throwGrenade(),
                  onLongPress: () => _engine.throwSuperGrenade(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _engine.nitra >= 40
                          ? const Color(0xFFAA1111).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: _engine.nitra >= 40
                            ? const Color(0xFFAA1111)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _engine.nitra >= 80 ? 'S-G' : 'GRN',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _engine.nitra >= 40
                              ? const Color(0xFFAA1111)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 스냅 스턴 오버레이
            if (_engine.isPlayerSnapped)
              IgnorePointer(
                child: Container(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  child: Center(
                    child: Text(
                      'SNAPPED!',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
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
                totalKills: _totalKills,
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

    // Pit Jaws
    for (final jaw in engine.pitJaws) {
      final sx = jaw.x - camX;
      final sy = jaw.y - camY;
      if (sx < -60 || sx > size.width + 60 || sy < -60 || sy > size.height + 60) continue;

      // ── 스냅 애니메이션 (턱이 닫힘) ──
      if (jaw.isSnapping) {
        final t = jaw.snapProgress.clamp(0.0, 1.0);
        final jawColor = const Color(0xFF5C3A1E);
        // 턱이 닫히는 동작: 위아래 턱이 모임
        final openOffset = 12.0 * (1.0 - t);
        final shakeX = t > 0.5 ? sin(t * 40) * 2.0 * (1.0 - t) : 0.0;

        // 상단 턱
        final topJaw = Path()
          ..moveTo(sx - 12 + shakeX, sy - openOffset)
          ..lineTo(sx - 4 + shakeX, sy - openOffset + 5)
          ..lineTo(sx + 4 + shakeX, sy - openOffset)
          ..lineTo(sx + 12 + shakeX, sy - openOffset + 5);
        canvas.drawPath(topJaw, Paint()
          ..color = jawColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

        // 하단 턱
        final botJaw = Path()
          ..moveTo(sx - 12 + shakeX, sy + openOffset)
          ..lineTo(sx - 4 + shakeX, sy + openOffset - 4)
          ..lineTo(sx + 4 + shakeX, sy + openOffset)
          ..lineTo(sx + 12 + shakeX, sy + openOffset - 4);
        canvas.drawPath(botJaw, Paint()
          ..color = jawColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

        // SNAP! 텍스트 (닫힌 후)
        if (t > 0.5) {
          final textAlpha = ((t - 0.5) * 2).clamp(0.0, 1.0);
          final tp = TextPainter(
            text: TextSpan(
              text: 'SNAP!',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: jawColor.withValues(alpha: textAlpha),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(sx - tp.width / 2, sy - 22));
        }

        // 위험 반경
        canvas.drawCircle(Offset(sx, sy), jaw.damageRadius,
          Paint()..color = _termRed.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        continue;
      }

      // ── 스턴 중 표시 ──
      if (jaw.snapStunTimer > 0) {
        _drawAsciiSprite(canvas, pitJawRevealedSprite, sx, sy,
            const Color(0xFF5C3A1E), fontSize: 10.0);
        // "STUNNED" 표시
        final alpha = (jaw.snapStunTimer).clamp(0.0, 1.0);
        final tp = TextPainter(
          text: TextSpan(
            text: 'STUNNED',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: _termRed.withValues(alpha: alpha * 0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(sx - tp.width / 2, sy - 22));
        continue;
      }

      // ── 예고 페이즈: 땅 흔들림 ──
      if (jaw.warningTimer > 0 && jaw.warningDuration > 0) {
        final warnProgress = 1.0 - (jaw.warningTimer / jaw.warningDuration);
        final shakeAmp = 1.0 + warnProgress * 3.0;
        final shakeOffset = sin(blinkCounter * 1.5) * shakeAmp;
        // 흔들리는 핏죠 이빨
        _drawAsciiSprite(canvas, pitJawRevealedSprite, sx + shakeOffset, sy,
            const Color(0xFF5C3A1E).withValues(alpha: 0.4 + warnProgress * 0.6),
            fontSize: 8.0 + warnProgress * 3.0);
        // 위험 반경 (점점 진해짐)
        canvas.drawCircle(Offset(sx, sy), jaw.damageRadius,
          Paint()..color = _termRed.withValues(alpha: 0.05 + warnProgress * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        // 먼지 파티클
        if (warnProgress > 0.3) {
          final dustAlpha = (warnProgress - 0.3) * 0.4;
          final rng = Random(blinkCounter ~/ 3);
          for (int i = 0; i < 3; i++) {
            final dx = (rng.nextDouble() - 0.5) * 20;
            final dy = (rng.nextDouble() - 0.5) * 10;
            canvas.drawCircle(Offset(sx + dx, sy + dy - 4), 1.2,
              Paint()..color = _termRed.withValues(alpha: dustAlpha));
          }
        }
        continue;
      }

      if (jaw.revealed) {
        // Revealed: red/orange jaw ASCII + danger radius
        _drawAsciiSprite(canvas, pitJawRevealedSprite, sx, sy,
            const Color(0xFF5C3A1E), fontSize: 10.0);
        canvas.drawCircle(
          Offset(sx, sy),
          jaw.damageRadius,
          Paint()
            ..color = _termRed.withValues(alpha: 0.1)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(sx, sy),
          jaw.damageRadius,
          Paint()
            ..color = _termRed.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      } else {
        // Hidden: faint dot
        _drawAsciiSprite(canvas, pitJawHiddenSprite, sx, sy,
            Colors.white.withValues(alpha: 0.08), fontSize: 6.0);
      }
    }

    // Nitra nodes — 빨간 광맥 결정 클러스터
    for (final node in engine.nitraNodes) {
      final sx = node.x - camX;
      final sy = node.y - camY;
      if (sx < -60 || sx > size.width + 60 || sy < -60 || sy > size.height + 60) continue;

      const nitraColor = Color(0xFF8B0000);
      const nitraDark = Color(0xFF5C0000);
      final depletion = node.maxNitra > 0
          ? (node.nitraRemaining / node.maxNitra).clamp(0.0, 1.0)
          : 0.0;
      // 잔량에 따라 투명도 감소
      final baseAlpha = 0.3 + 0.7 * depletion;

      // 배경 글로우 (잔량 비례)
      canvas.drawCircle(
        Offset(sx, sy),
        10 + 6 * depletion,
        Paint()
          ..color = nitraColor.withValues(alpha: 0.12 * depletion)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // 결정 클러스터: 불규칙 다각형 3~5개
      final rng = Random(node.x.toInt() ^ node.y.toInt()); // 고정 시드
      final crystalCount = 3 + (depletion * 2).round(); // 잔량 줄면 결정 수 감소
      for (int i = 0; i < crystalCount; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final dist = 2.0 + rng.nextDouble() * 6.0;
        final cx = sx + cos(angle) * dist;
        final cy = sy + sin(angle) * dist;
        final cAngle = rng.nextDouble() * pi;
        final cw = 2.0 + rng.nextDouble() * 3.0;
        final ch = 4.0 + rng.nextDouble() * 5.0;

        // 결정 다각형 (날카로운 육각형)
        final crystal = Path();
        crystal.moveTo(cx + cos(cAngle) * cw, cy + sin(cAngle) * cw);
        crystal.lineTo(cx + cos(cAngle + 1.2) * ch, cy + sin(cAngle + 1.2) * ch);
        crystal.lineTo(cx + cos(cAngle + 2.5) * cw * 0.6, cy + sin(cAngle + 2.5) * cw * 0.6);
        crystal.lineTo(cx + cos(cAngle + pi) * cw, cy + sin(cAngle + pi) * cw);
        crystal.lineTo(cx + cos(cAngle + pi + 1.2) * ch * 0.7, cy + sin(cAngle + pi + 1.2) * ch * 0.7);
        crystal.close();

        // 채우기
        final fillAlpha = (baseAlpha * (0.5 + rng.nextDouble() * 0.5)).clamp(0.0, 1.0);
        canvas.drawPath(crystal, Paint()
          ..color = (i % 2 == 0 ? nitraColor : nitraDark).withValues(alpha: fillAlpha));
        // 테두리
        canvas.drawPath(crystal, Paint()
          ..color = nitraColor.withValues(alpha: baseAlpha * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
      }

      // 결정 하이라이트 선 (광택)
      final hlPaint = Paint()
        ..color = const Color(0xFFCC3333).withValues(alpha: baseAlpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(sx - 3, sy - 5), Offset(sx - 1, sy - 2), hlPaint);
      canvas.drawLine(Offset(sx + 2, sy + 1), Offset(sx + 4, sy + 4), hlPaint);

      // 채굴 반경 (가까이 있을 때만)
      final pdx = px - node.x;
      final pdy = py - node.y;
      if (pdx * pdx + pdy * pdy < node.mineRadius * node.mineRadius * 4) {
        canvas.drawCircle(
          Offset(sx, sy),
          node.mineRadius,
          Paint()
            ..color = nitraColor.withValues(alpha: 0.08 + 0.07 * depletion)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
        // 잔량 바
        final barW = 20.0;
        final barX = sx - barW / 2;
        final barY = sy + 14;
        canvas.drawRect(Rect.fromLTWH(barX, barY, barW, 2),
          Paint()..color = nitraDark.withValues(alpha: 0.3));
        canvas.drawRect(Rect.fromLTWH(barX, barY, barW * depletion, 2),
          Paint()..color = nitraColor.withValues(alpha: 0.7));
      }
    }

    // Red Sugar nodes — 비정형 V자 결정 (한쪽이 더 김)
    for (final node in engine.redSugarNodes) {
      final sx = node.x - camX;
      final sy = node.y - camY;
      if (sx < -40 || sx > size.width + 40 || sy < -40 || sy > size.height + 40) continue;

      const sugarColor = Color(0xFFFF3355);
      const sugarGlow = Color(0xFFFF6688);
      final rng = Random(node.x.toInt() * 31 + node.y.toInt());
      final tilt = rng.nextDouble() * 0.6 - 0.3; // 약간 기울기

      // 글로우
      canvas.drawCircle(Offset(sx, sy), 10,
        Paint()..color = sugarGlow.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // V자 형태: 왼쪽 가지(짧음) + 오른쪽 가지(긺)
      final leftLen = 5.0 + rng.nextDouble() * 3.0;
      final rightLen = 8.0 + rng.nextDouble() * 4.0;
      final spread = 0.4 + rng.nextDouble() * 0.3; // V자 벌어짐 각도

      final crystalPaint = Paint()
        ..color = sugarColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      final crystalFill = Paint()
        ..color = sugarColor.withValues(alpha: 0.4);

      // 왼쪽 가지
      final lPath = Path();
      final lx = sx + cos(pi / 2 + spread + tilt) * leftLen;
      final ly = sy + sin(pi / 2 + spread + tilt) * leftLen;
      lPath.moveTo(sx, sy);
      lPath.lineTo(lx - 1.5, ly);
      lPath.lineTo(lx + 1.5, ly);
      lPath.close();
      canvas.drawPath(lPath, crystalFill);
      canvas.drawPath(lPath, crystalPaint);

      // 오른쪽 가지 (더 긺)
      final rPath = Path();
      final rx = sx + cos(pi / 2 - spread + tilt) * rightLen;
      final ry = sy + sin(pi / 2 - spread + tilt) * rightLen;
      rPath.moveTo(sx, sy);
      rPath.lineTo(rx - 2.0, ry);
      rPath.lineTo(rx + 2.0, ry);
      rPath.close();
      canvas.drawPath(rPath, crystalFill);
      canvas.drawPath(rPath, crystalPaint);

      // 하이라이트 점
      canvas.drawCircle(Offset(sx, sy - 2), 1.5,
        Paint()..color = Colors.white.withValues(alpha: 0.5));

      // 수집 반경 (가까이 있을 때)
      final pdx2 = px - node.x;
      final pdy2 = py - node.y;
      if (pdx2 * pdx2 + pdy2 * pdy2 < node.collectRadius * node.collectRadius * 4) {
        canvas.drawCircle(Offset(sx, sy), node.collectRadius,
          Paint()..color = sugarColor.withValues(alpha: 0.1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
      }
    }

    // Poison auras (draw behind enemies)
    for (final enemy in engine.enemies) {
      if (enemy.poisonAuraRadius > 0 && !enemy.isDead) {
        final sx = enemy.x - camX;
        final sy = enemy.y - camY;
        canvas.drawCircle(
          Offset(sx, sy),
          enemy.poisonAuraRadius,
          Paint()
            ..color = const Color(0xFF00FF00).withValues(alpha: 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        canvas.drawCircle(
          Offset(sx, sy),
          enemy.poisonAuraRadius,
          Paint()
            ..color = const Color(0xFF00FF00).withValues(alpha: 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Pending explosions (warning circles)
    for (final exp in engine.pendingExplosions) {
      final sx = exp.x - camX;
      final sy = exp.y - camY;
      final progress = 1.0 - (exp.delay / exp.maxDelay);
      canvas.drawCircle(
        Offset(sx, sy),
        exp.radius * progress,
        Paint()
          ..color = _termRed.withValues(alpha: 0.12 + progress * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(sx, sy),
        exp.radius * progress,
        Paint()
          ..color = _termRed.withValues(alpha: 0.4 + progress * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
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

  static const Color _scoutBlue = Color(0xFF4488FF);

  void _drawPlayer(Canvas canvas, double screenX, double screenY) {
    final p = engine.player;
    // Invincibility blink
    if (p.isInvincible && blinkCounter % 6 < 3) return;

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

    // 스카웃 스프라이트: 머리=녹색(또는 앰버), 몸통=파란색, 다리=녹색
    final sprite = (blinkCounter % 30 < 15) ? scoutSprite : scoutLampOffSprite;
    final headColor = p.isDashing ? _termAmber : _termGreen;
    const bodyColor = _scoutBlue;
    final legColor = p.isDashing ? _termAmber : _termGreen;
    final colors = [headColor, bodyColor, legColor];

    // 줄 단위로 다른 색상으로 렌더링
    const fontSize = 9.0;
    final lineHeight = fontSize * 1.1;
    final totalH = sprite.length * lineHeight;
    final startY = screenY - totalH / 2;

    for (int i = 0; i < sprite.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: sprite[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            color: colors[i % colors.length],
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(canvas, Offset(screenX - tp.width / 2, startY + i * lineHeight));
    }

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

    Color baseColor = _getEnemyColor(e.type);
    // Dreadnought phase 2: orange-red pulsing
    if (e.type == EnemyType.dreadnought && e.phase == 2) {
      baseColor = blinkCounter % 10 < 5
          ? const Color(0xFF5C3A1E)
          : const Color(0xFFFF0000);
    }
    final color = e.hitFlashTimer > 0 ? Colors.white : baseColor;

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
        return const Color(0xFF5C3A1E);
      case EnemyType.dreadnought:
        return const Color(0xFFFF0000);
      case EnemyType.bulkDetonator:
        return const Color(0xFFFF8800);
    }
  }

  void _drawProjectile(Canvas canvas, Projectile p, double camX, double camY) {
    final sx = p.x - camX;
    final sy = p.y - camY;

    // Enemy projectiles are red; Boltshark white; others amber
    final color = p.isEnemyProjectile
        ? _termRed
        : p.weaponId == 'boltshark'
            ? Colors.white
            : _termAmber;

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
