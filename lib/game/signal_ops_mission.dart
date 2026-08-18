class SignalOpsMission {
  const SignalOpsMission._();

  static String phaseFor({
    required int completed,
    required int total,
  }) {
    if (total <= 0) return 'ACQUIRE';

    final progress = (completed / total).clamp(0.0, 1.0);

    if (progress < 0.25) return 'ACQUIRE';
    if (progress < 0.50) return 'STABILIZE';
    if (progress < 0.75) return 'ROUTE';
    return 'SECURE';
  }

  static int relayGoalFor(int trials) {
    if (trials <= 0) return 0;
    return (trials / 3).ceil();
  }

  static String operationName({
    required bool daily,
  }) =>
      daily ? 'DAILY DISPATCH' : 'SIGNAL OPS';
}
