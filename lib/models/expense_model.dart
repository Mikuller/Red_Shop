import 'enums.dart';
import 'model_utils.dart';

class ExpenseRecord {
  final String id;
  final String description;
  final String category;
  final double amount;
  final ExpenseKind kind;
  final DateTime createdAt;
  final String createdByUid;
  final String createdByName;

  const ExpenseRecord({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.kind,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
  });

  factory ExpenseRecord.fromMap(Map<String, dynamic> map, String id) {
    final category = map['category']?.toString() ?? 'General';

    return ExpenseRecord(
      id: id,
      description: map['description']?.toString() ?? '',
      category: category,
      amount: readDouble(map['amount']),
      kind: readExpenseKind(map['kind'], category),
      createdAt: readDateTime(map['createdAt'] ?? map['date']),
      createdByUid: map['createdByUid']?.toString() ?? '',
      createdByName: map['createdByName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'category': category,
      'amount': amount,
      'kind': kind.name,
      'createdAt': createdAt,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
    };
  }
}
