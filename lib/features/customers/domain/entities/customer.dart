class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? address;
  final String? cnic;
  final String? imageUrl;
  final double openingBalance;
  final double? creditLimit;
  final String? notes;
  final List<String> tags;
  final bool isFavorite;
  final bool isSupplier;
  final double currentBalance;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.address,
    this.cnic,
    this.imageUrl,
    this.openingBalance = 0,
    this.creditLimit,
    this.notes,
    this.tags = const [],
    this.isFavorite = false,
    this.isSupplier = false,
    this.currentBalance = 0,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        cnic: map['cnic'] as String?,
        imageUrl: map['image_url'] as String?,
        openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
        creditLimit: (map['credit_limit'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
        tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isFavorite: map['is_favorite'] as bool? ?? false,
        isSupplier: map['is_supplier'] as bool? ?? false,
        currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'business_id': businessId,
        'name': name,
        'phone': phone,
        'address': address,
        'cnic': cnic,
        'image_url': imageUrl,
        'opening_balance': openingBalance,
        'credit_limit': creditLimit,
        'notes': notes,
        'tags': tags,
        'is_favorite': isFavorite,
        'is_supplier': isSupplier,
      };

  /// Positive balance = customer owes you (credit). Negative = you owe them.
  bool get owesYou => currentBalance > 0;
}
