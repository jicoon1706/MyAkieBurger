class IngredientInventory {
  final String id;
  final String name;
  final String category;
  final int available;
  final int maxOrder;
  final double unitPrice;
  final String image;

  IngredientInventory({
    required this.id,
    required this.name,
    required this.category,
    required this.available,
    required this.maxOrder,
    required this.unitPrice,
    required this.image,
  });

  factory IngredientInventory.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return IngredientInventory(
      id: documentId,
      name: data['name'],
      category: data['category'],
      available: data['available'],
      maxOrder: data['max_order'],
      unitPrice: (data['unit_price'] as num).toDouble(),
      image: data['image'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'available': available,
      'max_order': maxOrder,
      'unit_price': unitPrice,
      'image': image,
    };
  }
}
