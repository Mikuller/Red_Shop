import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:red_shop/models/models.dart';

class ShopService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _sales =>
      _db.collection('sales');
  CollectionReference<Map<String, dynamic>> get _purchases =>
      _db.collection('purchases');
  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<List<Product>> watchProducts() {
    return _products.snapshots().map((snapshot) {
      final products =
          snapshot.docs
              .map((doc) => Product.fromMap(doc.data(), doc.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      return products;
    });
  }

  Stream<List<SaleRecord>> watchSales() {
    return _sales.snapshots().map((snapshot) {
      final sales =
          snapshot.docs
              .map((doc) => SaleRecord.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sales;
    });
  }

  Stream<List<PurchaseRecord>> watchPurchases() {
    return _purchases.snapshots().map((snapshot) {
      final purchases =
          snapshot.docs
              .map((doc) => PurchaseRecord.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return purchases;
    });
  }

  Stream<List<ExpenseRecord>> watchExpenses() {
    return _expenses.snapshots().map((snapshot) {
      final expenses =
          snapshot.docs
              .map((doc) => ExpenseRecord.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return expenses;
    });
  }

  Stream<List<UserModel>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final users =
          snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      return users;
    });
  }

  Stream<DashboardSummary> watchDashboardSummary() {
    final controller = StreamController<DashboardSummary>();
    var products = <Product>[];
    var sales = <SaleRecord>[];
    var purchases = <PurchaseRecord>[];
    var expenses = <ExpenseRecord>[];

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          DashboardSummary.fromData(
            products: products,
            sales: sales,
            purchases: purchases,
            expenses: expenses,
          ),
        );
      }
    }

    final subscriptions = <StreamSubscription<dynamic>>[
      watchProducts().listen((value) {
        products = value;
        emit();
      }),
      watchSales().listen((value) {
        sales = value;
        emit();
      }),
      watchPurchases().listen((value) {
        purchases = value;
        emit();
      }),
      watchExpenses().listen((value) {
        expenses = value;
        emit();
      }),
    ];

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> saveProduct(Product product) async {
    final now = DateTime.now();
    final isNew = product.id.isEmpty;
    final doc = isNew ? _products.doc() : _products.doc(product.id);
    final payload = product
        .copyWith(createdAt: isNew ? now : product.createdAt, updatedAt: now)
        .toMap();

    await doc.set(payload, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    final snapshot = await _products.doc(productId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return;
    }

    final product = Product.fromMap(snapshot.data()!, snapshot.id);

    if (product.stock > 0) {
      throw StateError(
        'This product still has stock. Reduce it to zero before deleting it.',
      );
    }

    await _products.doc(productId).delete();
  }

  Future<void> recordPurchase({
    required List<PurchaseItem> items,
    required UserModel actor,
    String supplier = '',
    String note = '',
  }) async {
    if (items.isEmpty) {
      throw StateError('Add at least one product to the purchase.');
    }

    final normalizedItems = _collapsePurchaseItems(items);
    final purchaseRef = _purchases.doc();
    final now = DateTime.now();

    await _db.runTransaction((transaction) async {
      final savedItems = <PurchaseItem>[];

      for (final item in normalizedItems) {
        if (item.quantity <= 0) {
          throw StateError('Purchase quantities must be greater than zero.');
        }

        if (item.unitCost < 0) {
          throw StateError('Purchase price cannot be negative.');
        }

        final productRef = _products.doc(item.productId);
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists || snapshot.data() == null) {
          throw StateError('One of the selected products no longer exists.');
        }

        final product = Product.fromMap(snapshot.data()!, snapshot.id);
        final newStock = product.stock + item.quantity;
        final totalExistingValue = product.stock * product.averageCost;
        final totalIncomingValue = item.quantity * item.unitCost;
        final newAverageCost =
            (totalExistingValue + totalIncomingValue) / newStock;

        transaction.update(productRef, {
          'stock': newStock,
          'averageCost': newAverageCost,
          'updatedAt': now,
        });

        savedItems.add(
          PurchaseItem(
            productId: product.id,
            productName: product.name,
            quantity: item.quantity,
            unitCost: item.unitCost,
          ),
        );
      }

      final purchase = PurchaseRecord(
        id: purchaseRef.id,
        supplier: supplier.trim(),
        note: note.trim(),
        items: savedItems,
        totalCost: savedItems.fold<double>(
          0,
          (total, item) => total + item.lineTotal,
        ),
        createdAt: now,
        createdByUid: actor.uid,
        createdByName: actor.name,
      );

      transaction.set(purchaseRef, purchase.toMap());
    });
  }

  Future<void> recordSale({
    required List<SaleDraftItem> items,
    required UserModel actor,
  }) async {
    if (items.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    final normalizedItems = _collapseSaleItems(items);
    final saleRef = _sales.doc();
    final now = DateTime.now();

    await _db.runTransaction((transaction) async {
      final saleItems = <SaleItem>[];

      for (final draft in normalizedItems) {
        if (draft.quantity <= 0) {
          throw StateError('Sale quantities must be greater than zero.');
        }

        if (draft.unitPrice <= 0) {
          throw StateError('Set a selling price above zero before checkout.');
        }

        final productRef = _products.doc(draft.productId);
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists || snapshot.data() == null) {
          throw StateError('One of the selected products no longer exists.');
        }

        final product = Product.fromMap(snapshot.data()!, snapshot.id);

        if (product.stock < draft.quantity) {
          throw StateError(
            '${product.name} only has ${product.stock} units left in stock.',
          );
        }

        transaction.update(productRef, {
          'stock': product.stock - draft.quantity,
          'updatedAt': now,
        });

        saleItems.add(
          SaleItem(
            productId: product.id,
            productName: product.name,
            quantity: draft.quantity,
            unitPrice: draft.unitPrice,
            costPrice: product.averageCost,
          ),
        );
      }

      final totalRevenue = saleItems.fold<double>(
        0,
        (total, item) => total + item.lineTotal,
      );
      final totalCost = saleItems.fold<double>(
        0,
        (total, item) => total + (item.costPrice * item.quantity),
      );

      transaction.set(
        saleRef,
        SaleRecord(
          id: saleRef.id,
          items: saleItems,
          totalRevenue: totalRevenue,
          totalCost: totalCost,
          grossProfit: totalRevenue - totalCost,
          createdAt: now,
          processedByUid: actor.uid,
          processedByName: actor.name,
        ).toMap(),
      );
    });
  }

  Future<void> addExpense({
    required String description,
    required String category,
    required double amount,
    required ExpenseKind kind,
    required UserModel actor,
  }) async {
    if (amount <= 0) {
      throw StateError('Expense amount must be greater than zero.');
    }

    await _expenses.add(
      ExpenseRecord(
        id: '',
        description: description.trim(),
        category: category.trim().isEmpty ? 'General' : category.trim(),
        amount: amount,
        kind: kind,
        createdAt: DateTime.now(),
        createdByUid: actor.uid,
        createdByName: actor.name,
      ).toMap(),
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenses.doc(expenseId).delete();
  }

  Future<void> toggleUserActive(UserModel user) async {
    await _users.doc(user.uid).update({'active': !user.active});
  }

  List<PurchaseItem> _collapsePurchaseItems(List<PurchaseItem> items) {
    final merged = <String, PurchaseItem>{};

    for (final item in items) {
      final existing = merged[item.productId];
      if (existing == null) {
        merged[item.productId] = item;
        continue;
      }

      final totalQuantity = existing.quantity + item.quantity;
      final totalCost = existing.lineTotal + item.lineTotal;
      merged[item.productId] = PurchaseItem(
        productId: item.productId,
        productName: item.productName,
        quantity: totalQuantity,
        unitCost: totalCost / totalQuantity,
      );
    }

    return merged.values.toList();
  }

  List<SaleDraftItem> _collapseSaleItems(List<SaleDraftItem> items) {
    final merged = <String, SaleDraftItem>{};

    for (final item in items) {
      final existing = merged[item.productId];
      if (existing == null) {
        merged[item.productId] = item;
        continue;
      }

      final totalQuantity = existing.quantity + item.quantity;
      final totalRevenue =
          (existing.quantity * existing.unitPrice) +
          (item.quantity * item.unitPrice);
      merged[item.productId] = SaleDraftItem(
        productId: item.productId,
        productName: item.productName,
        quantity: totalQuantity,
        unitPrice: totalRevenue / totalQuantity,
      );
    }

    return merged.values.toList();
  }
}
