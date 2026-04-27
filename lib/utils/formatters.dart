import 'package:firebase_auth/firebase_auth.dart';

const String kCurrencyCode = 'ETB';

String formatCurrency(num amount, {String currencyCode = kCurrencyCode}) {
  final isNegative = amount < 0;
  final absolute = amount.abs();
  final fixed = absolute.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimal = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    buffer.write(whole[index]);
    final remaining = whole.length - index - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  final prefix = isNegative ? '-' : '';
  return '$prefix$currencyCode ${buffer.toString()}.$decimal';
}

String formatDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatDate(value)} - $hour:$minute';
}

String formatDateRange(DateTime start, DateTime endExclusive) {
  final inclusiveEnd = endExclusive.subtract(const Duration(days: 1));
  return '${formatDate(start)} - ${formatDate(inclusiveEnd)}';
}

String formatPercentChange(double value) {
  final percent = (value * 100).toStringAsFixed(0);
  if (value > 0) {
    return '+$percent%';
  }

  return '$percent%';
}

String describeError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'That email address is already being used.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Network request failed. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  if (error is StateError) {
    return error.message.toString();
  }

  return error.toString();
}
