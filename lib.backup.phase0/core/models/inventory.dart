class InventoryItem {
  final String name;
  final int quantity;
  final String type; // ingredient, tool, pantry
  final String unit;
  final DateTime addedAt;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.type,
    required this.unit,
    required this.addedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      type: json['type'] ?? 'ingredient',
      unit: json['unit'] ?? 'unit',
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'type': type,
      'unit': unit,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  String get displayName => '$quantity $unit de $name';

  String get typeLabel {
    switch (type) {
      case 'ingredient':
        return 'Ingrediente';
      case 'tool':
        return 'Herramienta';
      case 'pantry':
        return 'Despensa';
      default:
        return type;
    }
  }
}

class Inventory {
  final List<InventoryItem> items;
  final DateTime lastUpdated;

  Inventory({required this.items, required this.lastUpdated});

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      items:
          (json['inventory'] as List?)
              ?.map((item) => InventoryItem.fromJson(item))
              .toList() ??
          [],
      lastUpdated: DateTime.now(),
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  List<InventoryItem> get ingredients =>
      items.where((i) => i.type == 'ingredient').toList();

  List<InventoryItem> get tools =>
      items.where((i) => i.type == 'tool').toList();

  List<InventoryItem> get pantry =>
      items.where((i) => i.type == 'pantry').toList();

  bool hasItem(String itemName, {int? requiredQuantity}) {
    final item = items.firstWhere(
      (i) => i.name.toLowerCase() == itemName.toLowerCase(),
      orElse: () => InventoryItem(
        name: itemName,
        quantity: 0,
        type: 'ingredient',
        unit: 'unit',
        addedAt: DateTime.now(),
      ),
    );

    if (requiredQuantity != null) {
      return item.quantity >= requiredQuantity;
    }

    return item.quantity > 0;
  }

  int getItemQuantity(String itemName) {
    final item = items.firstWhere(
      (i) => i.name.toLowerCase() == itemName.toLowerCase(),
      orElse: () => InventoryItem(
        name: itemName,
        quantity: 0,
        type: 'ingredient',
        unit: 'unit',
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }
}
