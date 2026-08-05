/// Entry type mirrors DigiKhata's core ledger workflow:
/// - credit: "you gave" — increases what the customer owes you
/// - debit: "you received" — decreases what the customer owes you
enum LedgerEntryType { credit, debit }

class LedgerEntry {
  final String id;
  final String businessId;
  final String customerId;
  final LedgerEntryType type;
  final double amount;
  final double balanceAfter;
  final String? note;
  final String? category;
  final List<String> attachmentUrls;
  final DateTime entryDate;
  final DateTime createdAt;
  final String createdBy;

  const LedgerEntry({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.note,
    this.category,
    this.attachmentUrls = const [],
    required this.entryDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory LedgerEntry.fromMap(Map<String, dynamic> map) => LedgerEntry(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        customerId: map['customer_id'] as String,
        type: (map['type'] as String) == 'credit'
            ? LedgerEntryType.credit
            : LedgerEntryType.debit,
        amount: (map['amount'] as num).toDouble(),
        balanceAfter: (map['balance_after'] as num).toDouble(),
        note: map['note'] as String?,
        category: map['category'] as String?,
        attachmentUrls:
            (map['attachment_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        entryDate: DateTime.parse(map['entry_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        createdBy: map['created_by'] as String,
      );

  Map<String, dynamic> toInsertMap({required String createdByUserId}) => {
        'business_id': businessId,
        'customer_id': customerId,
        'type': type == LedgerEntryType.credit ? 'credit' : 'debit',
        'amount': amount,
        'note': note,
        'category': category,
        'attachment_urls': attachmentUrls,
        'entry_date': entryDate.toIso8601String(),
        'created_by': createdByUserId,
      };
}
