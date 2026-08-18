class CareerProfile {
  CareerProfile({
    this.missionsCompleted = 0,
    this.totalTrials = 0,
    this.totalCorrect = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    this.bestCombo = 0,
    this.perfects = 0,
    this.bestMissionAccuracy = 0,
    this.wordsTried = 0,
    this.wordsCorrect = 0,
    this.sendsTried = 0,
    this.sendsCorrect = 0,
    this.copyTried = 0,
    this.copyCorrect = 0,
    this.copyAccuracyTotal = 0,
    this.currentPracticeStreak = 0,
    this.bestPracticeStreak = 0,
    this.lastPracticeDay = '',
    this.dailyBestDay = '',
    this.dailyBestScore = 0,
  });

  int missionsCompleted;
  int totalTrials;
  int totalCorrect;
  int totalScore;
  int bestScore;
  int bestCombo;
  int perfects;
  double bestMissionAccuracy;

  int wordsTried;
  int wordsCorrect;
  int sendsTried;
  int sendsCorrect;
  int copyTried;
  int copyCorrect;
  double copyAccuracyTotal;

  int currentPracticeStreak;
  int bestPracticeStreak;
  String lastPracticeDay;

  String dailyBestDay;
  int dailyBestScore;

  double get lifetimeAccuracy =>
      totalTrials == 0 ? 0 : totalCorrect / totalTrials;

  String get rank {
    final score = totalCorrect +
        (wordsCorrect * 3) +
        (sendsCorrect * 2) +
        (copyCorrect * 4);
    if (score >= 2500) return 'Master Operator';
    if (score >= 1200) return 'Senior Operator';
    if (score >= 500) return 'Radio Operator';
    if (score >= 150) return 'Signal Operator';
    if (score >= 40) return 'Cadet';
    return 'Recruit';
  }

  int get rankLevel {
    switch (rank) {
      case 'Master Operator':
        return 6;
      case 'Senior Operator':
        return 5;
      case 'Radio Operator':
        return 4;
      case 'Signal Operator':
        return 3;
      case 'Cadet':
        return 2;
      default:
        return 1;
    }
  }

  void recordPracticeDay(DateTime now) {
    final today = _dayKey(now);
    if (lastPracticeDay == today) return;

    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    if (lastPracticeDay == yesterday) {
      currentPracticeStreak += 1;
    } else {
      currentPracticeStreak = 1;
    }

    if (currentPracticeStreak > bestPracticeStreak) {
      bestPracticeStreak = currentPracticeStreak;
    }
    lastPracticeDay = today;
  }

  void recordMission({
    required DateTime now,
    required int trials,
    required int correct,
    required int score,
    required int bestComboInMission,
    required int perfectsInMission,
    required bool daily,
  }) {
    recordPracticeDay(now);

    missionsCompleted += 1;
    totalTrials += trials;
    totalCorrect += correct;
    totalScore += score;
    perfects += perfectsInMission;

    if (score > bestScore) bestScore = score;
    if (bestComboInMission > bestCombo) {
      bestCombo = bestComboInMission;
    }

    final accuracy = trials == 0 ? 0.0 : correct / trials;
    if (accuracy > bestMissionAccuracy) {
      bestMissionAccuracy = accuracy;
    }

    if (daily) {
      final today = _dayKey(now);
      if (dailyBestDay != today) {
        dailyBestDay = today;
        dailyBestScore = score;
      } else if (score > dailyBestScore) {
        dailyBestScore = score;
      }
    }
  }

  void recordWord({
    required DateTime now,
    required bool correct,
  }) {
    recordPracticeDay(now);
    wordsTried += 1;
    if (correct) wordsCorrect += 1;
  }

  void recordSend({
    required DateTime now,
    required bool correct,
  }) {
    recordPracticeDay(now);
    sendsTried += 1;
    if (correct) sendsCorrect += 1;
  }

  void recordCopy({
    required DateTime now,
    required bool exact,
    required double accuracy,
  }) {
    recordPracticeDay(now);
    copyTried += 1;
    if (exact) copyCorrect += 1;
    copyAccuracyTotal += accuracy.clamp(0.0, 1.0);
  }

  double get averageCopyAccuracy =>
      copyTried == 0 ? 0 : copyAccuracyTotal / copyTried;

  Map<String, dynamic> toJson() => {
        'missionsCompleted': missionsCompleted,
        'totalTrials': totalTrials,
        'totalCorrect': totalCorrect,
        'totalScore': totalScore,
        'bestScore': bestScore,
        'bestCombo': bestCombo,
        'perfects': perfects,
        'bestMissionAccuracy': bestMissionAccuracy,
        'wordsTried': wordsTried,
        'wordsCorrect': wordsCorrect,
        'sendsTried': sendsTried,
        'sendsCorrect': sendsCorrect,
        'copyTried': copyTried,
        'copyCorrect': copyCorrect,
        'copyAccuracyTotal': copyAccuracyTotal,
        'currentPracticeStreak': currentPracticeStreak,
        'bestPracticeStreak': bestPracticeStreak,
        'lastPracticeDay': lastPracticeDay,
        'dailyBestDay': dailyBestDay,
        'dailyBestScore': dailyBestScore,
      };

  factory CareerProfile.fromJson(Map<String, dynamic> json) => CareerProfile(
        missionsCompleted:
            (json['missionsCompleted'] as num?)?.toInt() ?? 0,
        totalTrials: (json['totalTrials'] as num?)?.toInt() ?? 0,
        totalCorrect: (json['totalCorrect'] as num?)?.toInt() ?? 0,
        totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
        bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
        bestCombo: (json['bestCombo'] as num?)?.toInt() ?? 0,
        perfects: (json['perfects'] as num?)?.toInt() ?? 0,
        bestMissionAccuracy:
            (json['bestMissionAccuracy'] as num?)?.toDouble() ?? 0,
        wordsTried: (json['wordsTried'] as num?)?.toInt() ?? 0,
        wordsCorrect: (json['wordsCorrect'] as num?)?.toInt() ?? 0,
        sendsTried: (json['sendsTried'] as num?)?.toInt() ?? 0,
        sendsCorrect: (json['sendsCorrect'] as num?)?.toInt() ?? 0,
        copyTried: (json['copyTried'] as num?)?.toInt() ?? 0,
        copyCorrect: (json['copyCorrect'] as num?)?.toInt() ?? 0,
        copyAccuracyTotal:
            (json['copyAccuracyTotal'] as num?)?.toDouble() ?? 0,
        currentPracticeStreak:
            (json['currentPracticeStreak'] as num?)?.toInt() ?? 0,
        bestPracticeStreak:
            (json['bestPracticeStreak'] as num?)?.toInt() ?? 0,
        lastPracticeDay: json['lastPracticeDay'] as String? ?? '',
        dailyBestDay: json['dailyBestDay'] as String? ?? '',
        dailyBestScore: (json['dailyBestScore'] as num?)?.toInt() ?? 0,
      );

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
