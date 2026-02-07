import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String ownerId;
  final String customerId;
  final double amount;
  final String paymentMode; // 'Cash', 'UPI', 'Bank'
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
    final String? mode;

  Payment({
    required this.id,
    required this.ownerId,
    required this.customerId,
    required this.amount,
    required this.paymentMode,
    required this.date,
    required this.mode,
    this.notes,
    required this.createdAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      customerId: data['customerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMode: data['paymentMode'] ?? 'Cash',
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      mode: data['mode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'customerId': customerId,
      'amount': amount,
      'paymentMode': paymentMode,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'mode': mode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
