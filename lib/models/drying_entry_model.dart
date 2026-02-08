import 'package:cloud_firestore/cloud_firestore.dart';

class DryingEntry {
  final String id;
  final String ownerId;
  final String customerId;
  final DateTime date;
  final double freshWeightKg;
  final double? driedWeightKg;
  final int bagsCount;
  final double ratePerKg;
  final double? amount;
  final String status; // 'received' or 'dried'
  final double? dryingLoss;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DryingEntry({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.date,
    required this.freshWeightKg,
    this.driedWeightKg,
    required this.bagsCount,
    required this.ratePerKg,
    this.amount,
    required this.status,
    this.dryingLoss,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory DryingEntry.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Helper to safely parse doubles
      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is int) return value.toDouble();
        if (value is double) return value;
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Helper to safely parse DateTime
      DateTime parseDate(dynamic value) {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
        return DateTime.now();
      }

      return DryingEntry(
        id: doc.id,
        ownerId: data['ownerId']?.toString() ?? '',
        customerId: data['customerId']?.toString() ?? '',
        date: parseDate(data['date']),
        freshWeightKg: parseDouble(data['freshWeightKg']),
        driedWeightKg: data['driedWeightKg'] != null
            ? parseDouble(data['driedWeightKg'])
            : null,
        bagsCount: (data['bagsCount'] is int)
            ? data['bagsCount']
            : int.tryParse(data['bagsCount']?.toString() ?? '0') ?? 0,
        ratePerKg: parseDouble(data['ratePerKg']),
        amount: data['amount'] != null ? parseDouble(data['amount']) : null,
        status: data['status']?.toString() ?? 'received',
        dryingLoss:
            data['dryingLoss'] != null ? parseDouble(data['dryingLoss']) : null,
        notes: data['notes']?.toString(),
        createdAt: parseDate(data['createdAt']),
        updatedAt:
            data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
      );
    } catch (e) {
      print('ERROR: Failed to parse DryingEntry ${doc.id}: $e');
      print('Raw Data: ${doc.data()}');
      // Return a safe default or rethrow.
      // Returning a "corrupted" entry might be better than crashing the whole list.
      return DryingEntry(
        id: doc.id,
        ownerId: '',
        customerId: '',
        date: DateTime.now(),
        freshWeightKg: 0,
        bagsCount: 0,
        ratePerKg: 0,
        status: 'error',
        notes: 'Error parsing data: $e',
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'customerId': customerId,
      'date': Timestamp.fromDate(date),
      'freshWeightKg': freshWeightKg,
      'driedWeightKg': driedWeightKg,
      'bagsCount': bagsCount,
      'ratePerKg': ratePerKg,
      'amount': amount,
      'status': status,
      'dryingLoss': dryingLoss,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  DryingEntry copyWith({
    String? id,
    String? ownerId,
    String? customerId,
    DateTime? date,
    double? freshWeightKg,
    double? driedWeightKg,
    int? bagsCount,
    double? ratePerKg,
    double? amount,
    String? status,
    double? dryingLoss,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DryingEntry(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      freshWeightKg: freshWeightKg ?? this.freshWeightKg,
      driedWeightKg: driedWeightKg ?? this.driedWeightKg,
      bagsCount: bagsCount ?? this.bagsCount,
      ratePerKg: ratePerKg ?? this.ratePerKg,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dryingLoss: dryingLoss ?? this.dryingLoss,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isDried => status == 'dried';
  bool get isReceived => status == 'received';
}
