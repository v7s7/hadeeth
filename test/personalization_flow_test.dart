import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hadeeth/models/app_characters.dart';
import 'package:hadeeth/models/app_accessory.dart';
import 'package:hadeeth/models/app_user.dart';
import 'package:hadeeth/models/user_gender.dart';
import 'package:hadeeth/models/user_progress.dart';
import 'package:hadeeth/models/user_role.dart';
import 'package:hadeeth/services/font_size_service.dart';
import 'package:hadeeth/services/local_storage_service.dart';
import 'package:hadeeth/services/notification_service.dart';

void main() {
  group('Character selection', () {
    test('all male and female characters are available from level 1', () {
      for (final gender in UserGender.values) {
        final characters = AppCharacters.forGender(gender);

        expect(characters, hasLength(3));
        expect(AppCharacters.unlockedFor(gender, 1), characters);
        expect(AppCharacters.unlockedFor(gender, 99), characters);
        expect(characters.every((character) => character.unlockLevel == 1), isTrue);
        expect(characters.every((character) => character.isUnlockedAt(1)), isTrue);
        expect(characters.every((character) => character.isUnlockedAt(99)), isTrue);
      }
    });

    test('findById returns selected character and unknown IDs are safe', () {
      expect(AppCharacters.findById('male_bisht_gold'), AppCharacters.male2);
      expect(AppCharacters.findById('female_niqab'), AppCharacters.female2);
      expect(AppCharacters.findById('missing_character'), isNull);
      expect(AppCharacters.findById(null), isNull);
    });

    test('level-up no longer unlocks characters', () {
      expect(AppCharacters.newlyUnlocked(UserGender.male, 1, 10), isEmpty);
      expect(AppCharacters.newlyUnlocked(UserGender.female, 1, 10), isEmpty);
    });
  });

  group('Character accessories', () {
    test('default accessory is available and advanced items unlock by progress',
        () {
      final initial = UserProgress.initial();
      final advanced = initial.copyWith(totalXp: 300, currentStreak: 14);

      expect(AppAccessories.defaultAccessory().isUnlocked(initial), isTrue);
      expect(AppAccessories.woodMisbah.isUnlocked(initial), isFalse);
      expect(AppAccessories.woodMisbah.isUnlocked(advanced), isTrue);
      expect(AppAccessories.goldFrame.isUnlocked(initial), isFalse);
      expect(AppAccessories.goldFrame.isUnlocked(advanced), isTrue);
      expect(AppAccessories.findById('misbah_amber'),
          AppAccessories.amberMisbah);
    });
  });

  group('Preferred name storage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('trims, stores, caches, and clears the preferred name', () async {
      final storage = LocalStorageService();

      await storage.savePreferredName('  سارة  ');
      expect(LocalStorageService.cachedPreferredName, 'سارة');
      expect(await storage.loadPreferredName(), 'سارة');

      await storage.savePreferredName('   ');
      expect(LocalStorageService.cachedPreferredName, isNull);
      expect(await storage.loadPreferredName(), isNull);
    });

    test('preload warms character and preferred-name caches together', () async {
      SharedPreferences.setMockInitialValues({
        'character_id': 'female_hijab_teal',
        'preferred_name': 'فاطمة',
      });

      await LocalStorageService().preload();

      expect(LocalStorageService.cachedCharacterId, 'female_hijab_teal');
      expect(LocalStorageService.cachedPreferredName, 'فاطمة');
    });
  });

  group('Account personalization model', () {
    test('stores welcome, onboarding, gender and character on the user profile',
        () {
      final user = AppUser(
        id: 'u1',
        email: 'user@example.com',
        displayName: 'أحمد',
        role: UserRole.user,
        isDisabled: false,
        createdAt: DateTime(2026),
        gender: UserGender.male,
        characterId: AppCharacters.male2.id,
        activeAccessoryId: AppAccessories.amberMisbah.id,
        completedOnboarding: true,
        completedWelcome: true,
      );

      final map = user.toMap();

      expect(map['displayName'], 'أحمد');
      expect(map['gender'], UserGender.male.name);
      expect(map['characterId'], AppCharacters.male2.id);
      expect(map['activeAccessoryId'], AppAccessories.amberMisbah.id);
      expect(map['completedOnboarding'], isTrue);
      expect(map['completedWelcome'], isTrue);
    });
  });


  group('Notification personalization', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('daily reminder body includes trimmed preferred name and tone text', () {
      final body = NotificationService.buildDailyReminderBody(
        userName: '  أحمد  ',
        tone: NotificationTone.short,
      );

      expect(body.startsWith('أحمد، '), isTrue);
      expect(body, isNot(contains('  أحمد')));
    });

    test('notification tone is persisted and parsed safely', () async {
      final storage = LocalStorageService();

      await storage.saveNotificationTone(NotificationTone.motivational);
      expect(LocalStorageService.cachedNotificationTone,
          NotificationTone.motivational);
      expect(await storage.getNotificationTone(), NotificationTone.motivational);
      expect(NotificationTone.fromName('unknown'), NotificationTone.gentle);
    });
  });

  group('Font-size option boundaries', () {
    test('maps saved scale values into the expected option buckets', () {
      expect(FontScaleOption.fromScale(1.0), FontScaleOption.normal);
      expect(FontScaleOption.fromScale(1.24), FontScaleOption.normal);
      expect(FontScaleOption.fromScale(1.25), FontScaleOption.large);
      expect(FontScaleOption.fromScale(1.54), FontScaleOption.large);
      expect(FontScaleOption.fromScale(1.55), FontScaleOption.largest);
    });
  });

  group('Progress merge safety', () {
    test('merge keeps max counters and unions read/learned/saved items', () {
      final local = UserProgress.initial().copyWith(
        totalXp: 200,
        currentStreak: 3,
        longestStreak: 5,
        readHadithIds: {'h1'},
        learnedHadithIds: {'h2'},
        savedHadithIds: {'h3'},
        quizzesCompleted: 1,
        quizCorrectAnswers: 2,
        quizTotalAnswers: 3,
        streakFreezeCount: 1,
      );
      final cloud = UserProgress.initial().copyWith(
        totalXp: 150,
        currentStreak: 7,
        longestStreak: 4,
        readHadithIds: {'h4'},
        learnedHadithIds: {'h5'},
        savedHadithIds: {'h6'},
        quizzesCompleted: 3,
        quizCorrectAnswers: 1,
        quizTotalAnswers: 4,
        streakFreezeCount: 2,
      );

      final merged = local.merge(cloud);

      expect(merged.totalXp, 200);
      expect(merged.currentStreak, 7);
      expect(merged.longestStreak, 5);
      expect(merged.readHadithIds, {'h1', 'h4'});
      expect(merged.learnedHadithIds, {'h2', 'h5'});
      expect(merged.savedHadithIds, {'h3', 'h6'});
      expect(merged.quizzesCompleted, 3);
      expect(merged.quizCorrectAnswers, 2);
      expect(merged.quizTotalAnswers, 4);
      expect(merged.streakFreezeCount, 2);
    });
  });
}
