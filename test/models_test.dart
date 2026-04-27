import 'package:flutter_test/flutter_test.dart';
import 'package:red_shop/models/models.dart';

void main() {
  Product buildProduct({
    double averageCost = 0,
    int stock = 0,
  }) {
    final now = DateTime(2026, 1, 1);
    return Product(
      id: 'product-1',
      name: 'Keyboard',
      category: 'Accessories',
      sku: 'KEY-001',
      description: '',
      imageUrl: '',
      suggestedSellingPrice: 1200,
      averageCost: averageCost,
      stock: stock,
      lowStockThreshold: 2,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('restocking empty stock resets average cost to purchase price', () {
    final product = buildProduct(averageCost: 350, stock: 0);

    final newAverageCost = product.averageCostAfterRestock(
      addedQuantity: 4,
      purchaseUnitCost: 500,
    );

    expect(newAverageCost, 500);
  });

  test('restocking existing stock applies moving average valuation', () {
    final product = buildProduct(averageCost: 100, stock: 10);

    final newAverageCost = product.averageCostAfterRestock(
      addedQuantity: 5,
      purchaseUnitCost: 160,
    );

    expect(newAverageCost, closeTo(120, 0.0001));
  });

  test('restocking rejects non-positive quantity', () {
    final product = buildProduct(averageCost: 100, stock: 10);

    expect(
      () => product.averageCostAfterRestock(
        addedQuantity: 0,
        purchaseUnitCost: 160,
      ),
      throwsArgumentError,
    );
  });
}
