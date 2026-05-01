enum UserRole { owner, clerk }

enum ExpenseKind { operating, withdrawal }

enum ServiceStatus { pending, completedUnpaid, completedPaid }

enum SaleChannel { pos, instant }

String userRoleLabel(UserRole role) {
  return role == UserRole.owner ? 'Owner' : 'Clerk';
}

String expenseKindLabel(ExpenseKind kind) {
  return kind == ExpenseKind.operating ? 'Operating' : 'Withdrawal';
}
