import 'package:flutter_test/flutter_test.dart';
import 'package:morsebound/profile/career_profile.dart';

void main() {
  test('career rank rises from actual learning activity', () {
    final profile = CareerProfile();
    expect(profile.rank, 'Recruit');

    profile.totalCorrect = 160;
    expect(profile.rank, 'Signal Operator');

    profile.totalCorrect = 1300;
    expect(profile.rank, 'Senior Operator');
  });

  test('practice streak advances on consecutive days only', () {
    final profile = CareerProfile();
    profile.recordPracticeDay(DateTime(2026, 8, 10));
    profile.recordPracticeDay(DateTime(2026, 8, 11));
    profile.recordPracticeDay(DateTime(2026, 8, 12));

    expect(profile.currentPracticeStreak, 3);
    expect(profile.bestPracticeStreak, 3);

    profile.recordPracticeDay(DateTime(2026, 8, 14));
    expect(profile.currentPracticeStreak, 1);
    expect(profile.bestPracticeStreak, 3);
  });

  test('real copy contributes to career progress', () {
    final profile = CareerProfile();

    profile.recordCopy(
      now: DateTime(2026, 8, 18),
      exact: false,
      accuracy: 0.8,
    );
    profile.recordCopy(
      now: DateTime(2026, 8, 18),
      exact: true,
      accuracy: 1,
    );

    expect(profile.copyTried, 2);
    expect(profile.copyCorrect, 1);
    expect(profile.averageCopyAccuracy, closeTo(0.9, 0.001));
  });

  test('daily challenge keeps best score for the same day', () {
    final profile = CareerProfile();

    profile.recordMission(
      now: DateTime(2026, 8, 18),
      trials: 12,
      correct: 10,
      score: 1500,
      bestComboInMission: 5,
      perfectsInMission: 2,
      daily: true,
    );

    profile.recordMission(
      now: DateTime(2026, 8, 18),
      trials: 12,
      correct: 11,
      score: 1300,
      bestComboInMission: 6,
      perfectsInMission: 3,
      daily: true,
    );

    expect(profile.dailyBestScore, 1500);
  });
}
