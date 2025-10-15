
// lib/domains/ingredients_model.dart
class IngredientModel {
  final String id;
  final String name;
  final double price;
  final int received;
  final int used;
  final int damaged;
  final int eat;
  final int balance;
  final String updatedAt;

  IngredientModel({
    required this.id,
    required this.name,
    required this.price,
    required this.received,
    required this.used,
    required this.damaged,
    required this.eat,
    required this.balance,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'received': received,
      'used': used,
      'damaged': damaged,
      'eat': eat,
      'balance': balance,
      'updated_at': updatedAt,
    };
  }

  factory IngredientModel.fromMap(String id, Map<String, dynamic> data) {
    return IngredientModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      received: data['received'] ?? 0,
      used: data['used'] ?? 0,
      damaged: data['damaged'] ?? 0,
      eat: data['eat'] ?? 0,
      balance: data['balance'] ?? 0,
      updatedAt: data['updated_at'] ?? '',
    );
  }
}
