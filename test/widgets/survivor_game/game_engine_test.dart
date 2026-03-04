import 'package:flutter_test/flutter_test.dart';
import 'package:drg_mission_tracker/widgets/survivor_game/game_engine.dart';
import 'package:drg_mission_tracker/widgets/survivor_game/data/weapon_data.dart';

void main() {
  group('GameEngine initialization', () {
    test('starts at wave 1 with playing phase', () {
      final engine = GameEngine();
      expect(engine.wave, 1);
      expect(engine.phase, GamePhase.playing);
      expect(engine.killCount, 0);
      expect(engine.score, 0);
      expect(engine.gameTimer, 0);
    });

    test('player starts with default HP', () {
      final engine = GameEngine();
      expect(engine.player.hp, 100);
      expect(engine.player.maxHp, 100);
      expect(engine.player.level, 1);
      expect(engine.player.isDead, false);
    });

    test('player starts with GK2 primary weapon', () {
      final engine = GameEngine();
      expect(engine.player.primaryWeapon, WeaponId.gk2);
      expect(engine.player.secondaryWeapon, isNull);
    });
  });

  group('Wave progression', () {
    test('waveTimer advances during playing phase', () {
      final engine = GameEngine();
      engine.setScreenSize(400, 800);
      expect(engine.wave, 1);

      // A few updates should advance waveTimer
      engine.update(1.0, 0, 0);
      expect(engine.waveTimer, greaterThan(0));
    });
  });

  group('Enemy spawning', () {
    test('enemies spawn during wave', () {
      final engine = GameEngine();
      engine.setScreenSize(400, 800);

      // Simulate several seconds — enemies should spawn
      for (int i = 0; i < 100; i++) {
        engine.update(0.1, 0, 0);
      }
      // At least some enemies should have spawned (even if some died)
      expect(engine.killCount + engine.enemies.length, greaterThan(0));
    });
  });

  group('Player damage and game over', () {
    test('player takes damage', () {
      final engine = GameEngine();
      engine.player.takeDamage(30);
      expect(engine.player.hp, 70);
    });

    test('player death triggers game over', () {
      final engine = GameEngine();
      engine.setScreenSize(400, 800);
      engine.player.takeDamage(100);
      expect(engine.player.isDead, true);

      // One more update should transition to gameOver
      engine.update(0.016, 0, 0);
      expect(engine.phase, GamePhase.gameOver);
    });

    test('player invincibility prevents consecutive damage', () {
      final engine = GameEngine();
      engine.player.takeDamage(20);
      expect(engine.player.hp, 80);

      // Second hit during invincibility should not apply
      engine.player.takeDamage(20);
      expect(engine.player.hp, 80);
    });
  });

  group('Player heal and XP', () {
    test('heal restores HP up to max', () {
      final engine = GameEngine();
      engine.player.takeDamage(50);
      engine.player.invincibilityTimer = 0; // reset for testing
      expect(engine.player.hp, 50);

      engine.player.heal(30);
      expect(engine.player.hp, 80);

      engine.player.heal(100);
      expect(engine.player.hp, 100); // clamped to maxHp
    });

    test('adding XP causes level up', () {
      final engine = GameEngine();
      expect(engine.player.level, 1);

      final leveledUp = engine.player.addXp(15);
      expect(leveledUp, true);
      expect(engine.player.level, 2);
    });

    test('insufficient XP does not level up', () {
      final engine = GameEngine();
      final leveledUp = engine.player.addXp(5);
      expect(leveledUp, false);
      expect(engine.player.level, 1);
    });
  });

  group('Level-up choices', () {
    test('generates exactly 3 choices', () {
      final engine = GameEngine();
      final choices = engine.generateChoices();
      expect(choices.length, 3);
    });

    test('first level-up guarantees secondary weapon option', () {
      final engine = GameEngine();
      expect(engine.player.secondaryWeapon, isNull);

      final choices = engine.generateChoices();
      final hasWeapon = choices.any(
        (c) => c.type == LevelUpChoiceType.secondaryWeapon,
      );
      expect(hasWeapon, true);
    });

    test('applying damage up increases multiplier', () {
      final engine = GameEngine();
      final before = engine.player.damageMultiplier;

      engine.applyChoice(const LevelUpChoice(
        type: LevelUpChoiceType.damageUp,
        title: 'DAMAGE UP',
        description: '+20% damage',
      ));

      expect(engine.player.damageMultiplier, closeTo(before * 1.2, 0.01));
    });

    test('applying speed up increases speed', () {
      final engine = GameEngine();
      final before = engine.player.speed;

      engine.applyChoice(const LevelUpChoice(
        type: LevelUpChoiceType.speedUp,
        title: 'SPEED UP',
        description: '+10% move speed',
      ));

      expect(engine.player.speed, closeTo(before * 1.1, 0.01));
    });

    test('applying HP recovery restores HP', () {
      final engine = GameEngine();
      engine.player.takeDamage(50);
      engine.player.invincibilityTimer = 0;

      engine.applyChoice(const LevelUpChoice(
        type: LevelUpChoiceType.hpRecovery,
        title: 'HP RECOVERY',
        description: 'Restore 30 HP',
      ));

      expect(engine.player.hp, 80);
    });
  });

  group('Score calculation', () {
    test('final score includes kills and time', () {
      final engine = GameEngine();
      engine.setScreenSize(400, 800);

      // Simulate a few seconds
      for (int i = 0; i < 50; i++) {
        engine.update(0.1, 0, 0);
      }

      final score = engine.finalScore;
      // finalScore = score + killCount * 5 + gameTimer * 2
      expect(
        score,
        closeTo(
          engine.score + engine.killCount * 5 + engine.gameTimer * 2,
          0.01,
        ),
      );
    });
  });

  group('Player dash', () {
    test('dash activates and has cooldown', () {
      final engine = GameEngine();
      final result = engine.player.tryDash(1, 0);
      expect(result, true);
      expect(engine.player.isDashing, true);

      // Cannot dash again during cooldown
      final result2 = engine.player.tryDash(1, 0);
      expect(result2, false);
    });

    test('dash ends after duration', () {
      final engine = GameEngine();
      engine.player.tryDash(1, 0);
      expect(engine.player.isDashing, true);

      // Simulate past dash duration
      engine.player.update(0.3);
      expect(engine.player.isDashing, false);
    });
  });
}
