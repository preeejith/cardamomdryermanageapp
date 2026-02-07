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
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DryingEntry(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      customerId: data['customerId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      freshWeightKg: (data['freshWeightKg'] ?? 0).toDouble(),
      driedWeightKg: data['driedWeightKg'] != null 
          ? (data['driedWeightKg']).toDouble() 
          : null,
      bagsCount: data['bagsCount'] ?? 0,
      ratePerKg: (data['ratePerKg'] ?? 0).toDouble(),
      amount: data['amount'] != null ? (data['amount']).toDouble() : null,
      status: data['status'] ?? 'received',
      dryingLoss: data['dryingLoss'] != null 
          ? (data['dryingLoss']).toDouble() 
          : null,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
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
