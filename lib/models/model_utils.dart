import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

double readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime readDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}

UserRole readRole(dynamic value) {
  return value == 'owner' ? UserRole.owner : UserRole.clerk;
}

ExpenseKind readExpenseKind(dynamic value, String category) {
  if (value == 'withdrawal') {
    return ExpenseKind.withdrawal;
  }
  if (category.toLowerCase().contains('withdraw')) {
    return ExpenseKind.withdrawal;
  }
  return ExpenseKind.operating;
}

ServiceStatus readServiceStatus(dynamic value) {
  switch (value?.toString()) {
    case 'completedPaid':
    case 'paid':
      return ServiceStatus.completedPaid;
    case 'completedUnpaid':
    case 'unpaid':
      return ServiceStatus.completedUnpaid;
    default:
      return ServiceStatus.pending;
  }
}

SaleChannel readSaleChannel(dynamic value) {
  return value?.toString() == 'instant' ? SaleChannel.instant : SaleChannel.pos;
}
