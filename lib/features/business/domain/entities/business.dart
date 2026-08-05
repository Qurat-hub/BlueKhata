class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? logoUrl;
  final String? bannerUrl;
  final String businessType;
  final String currency;
  final String? address;
  final String? taxNumber;
  final String? phone;
  final String? email;
  final bool isArchived;
  final DateTime createdAt;

  const Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.logoUrl,
    this.bannerUrl,
    this.businessType = 'General',
    this.currency = 'PKR',
    this.address,
    this.taxNumber,
    this.phone,
    this.email,
    this.isArchived = false,
    required this.createdAt,
  });

  factory Business.fromMap(Map<String, dynamic> map) => Business(
        id: map['id'] as String,
        ownerId: map['owner_id'] as String,
        name: map['name'] as String,
        logoUrl: map['logo_url'] as String?,
        bannerUrl: map['banner_url'] as String?,
        businessType: map['business_type'] as String? ?? 'General',
        currency: map['currency'] as String? ?? 'PKR',
        address: map['address'] as String?,
        taxNumber: map['tax_number'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        isArchived: map['is_archived'] as bool? ?? false,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'owner_id': ownerId,
        'name': name,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
        'business_type': businessType,
        'currency': currency,
        'address': address,
        'tax_number': taxNumber,
        'phone': phone,
        'email': email,
      };
}
