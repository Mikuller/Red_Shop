import 'model_utils.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String sku;
  final String description;
  final String imageUrl;
  final double suggestedSellingPrice;
  final double averageCost;
  final int stock;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.description,
    required this.imageUrl,
    required this.suggestedSellingPrice,
    required this.averageCost,
    required this.stock,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      sku: map['sku']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      suggestedSellingPrice: readDouble(
        map['suggestedSellingPrice'] ?? map['price'],
      ),
      averageCost: readDouble(map['averageCost'] ?? map['purchasePrice']),
      stock: readInt(map['stock']),
      lowStockThreshold: readInt(map['lowStockThreshold'] ?? 3),
      createdAt: readDateTime(map['createdAt']),
      updatedAt: readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'sku': sku,
      'description': description,
      'imageUrl': imageUrl,
      'suggestedSellingPrice': suggestedSellingPrice,
      'averageCost': averageCost,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? sku,
    String? description,
    String? imageUrl,
    double? suggestedSellingPrice,
    double? averageCost,
    int? stock,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      suggestedSellingPrice:
          suggestedSellingPrice ?? this.suggestedSellingPrice,
      averageCost: averageCost ?? this.averageCost,
      stock: stock ?? this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double averageCostAfterRestock({
    required int addedQuantity,
    required double purchaseUnitCost,
  }) {
    if (addedQuantity <= 0) {
      throw ArgumentError.value(
        addedQuantity,
        'addedQuantity',
        'Restock quantity must be greater than zero.',
      );
    }

    if (purchaseUnitCost < 0) {
      throw ArgumentError.value(
        purchaseUnitCost,
        'purchaseUnitCost',
        'Purchase price cannot be negative.',
      );
    }

    if (stock <= 0) {
      return purchaseUnitCost;
    }

    final existingInventoryValue = stock * averageCost;
    final incomingInventoryValue = addedQuantity * purchaseUnitCost;
    final totalUnits = stock + addedQuantity;

    return (existingInventoryValue + incomingInventoryValue) / totalUnits;
  }

  double get marginPerUnit => suggestedSellingPrice - averageCost;

  bool get isLowStock => stock <= lowStockThreshold;
}

List<String> collectProductCategories(
  Iterable<Product> products, {
  Iterable<String> extra = const [],
  bool includeUncategorized = false,
}) {
  final categoriesByKey = <String, String>{};
  var hasUncategorized = false;

  void addCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      hasUncategorized = true;
      return;
    }

    categoriesByKey.putIfAbsent(trimmed.toLowerCase(), () => trimmed);
  }

  for (final product in products) {
    addCategory(product.category);
  }

  for (final category in extra) {
    addCategory(category);
  }

  final categories = categoriesByKey.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  if (includeUncategorized && hasUncategorized) {
    categories.add('');
  }

  return categories;
}
