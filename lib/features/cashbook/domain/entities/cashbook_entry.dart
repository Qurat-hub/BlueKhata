/// Mirrors the `type` check constraint on `public.cashbook_entries`:
/// ('cash_in','cash_out','income','expense','transfer').
///
/// The Cash Book module (this feature) only writes/reads `cash_in` and
/// `cash_out` — DigiKhata's simple "add cash" / "reduce cash" flow. The
/// `income`/`expense`/`transfer` variants stay reserved for the future
/// Expense Book and Bank Book modules, which will read the same table
/// filtered to their own types rather than needing a new one.
enum CashbookEntryType { cashIn, cashOut, income, expense, transfer }

CashbookEntryType cashbookEntryTypeFromString(String value) {
  switch (value) {
    case 'cash_in':
      return CashbookEntryType.cashIn;
    case 'cash_out':
      return CashbookEntryType.cashOut;
    case 'income':
      return CashbookEntryType.income;
    case 'expense':
      return CashbookEntryType.expense;
    case 'transfer':
      return CashbookEntryType.transfer;
    default:
      throw ArgumentError('Unknown cashbook entry type: $value');
  }
}

String cashbookEntryTypeToString(CashbookEntryType type) {
  switch (type) {
    case CashbookEntryType.cashIn:
      return 'cash_in';
    case CashbookEntryType.cashOut:
      return 'cash_out';
    case CashbookEntryType.income:
      return 'income';
    case CashbookEntryType.expense:
      return 'expense';
    case CashbookEntryType.transfer:
      return 'transfer';
  }
}

/// `true` if this entry type adds to cash-in-hand, `false` if it reduces it.
bool cashbookEntryIsInflow(CashbookEntryType type) =>
    type == CashbookEntryType.cashIn || type == CashbookEntryType.income;

class CashbookEntry {
  final String id;
  final String businessId;
  final CashbookEntryType type;
  final double amount;
  final String? category;
  final String? note;
  final DateTime entryDate;
  final DateTime createdAt;
  final String createdBy;

  const CashbookEntry({
    required this.id,
    required this.businessId,
    required this.type,
    required this.amount,
    this.category,
    this.note,
    required this.entryDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory CashbookEntry.fromMap(Map<String, dynamic> map) => CashbookEntry(
        id: map['id'] as String,
        businessId: map['business_id'] as String,
        type: cashbookEntryTypeFromString(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String?,
        note: map['note'] as String?,
        entryDate: DateTime.parse(map['entry_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        createdBy: map['created_by'] as String,
      );

  Map<String, dynamic> toInsertMap({required String createdByUserId}) => {
        'business_id': businessId,
        'type': cashbookEntryTypeToString(type),
        'amount': amount,
        'category': category,
        'note': note,
        'entry_date': entryDate.toIso8601String(),
        'created_by': createdByUserId,
      };
}
