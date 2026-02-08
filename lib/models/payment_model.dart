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

      return Payment(
        id: doc.id,
        ownerId: data['ownerId']?.toString() ?? '',
        customerId: data['customerId']?.toString() ?? '',
        amount: parseDouble(data['amount']),
        paymentMode: data['paymentMode']?.toString() ?? 'Cash',
        date: parseDate(data['date']),
        notes: data['notes']?.toString(),
        mode: data['mode']?.toString(),
        createdAt: parseDate(data['createdAt']),
      );
    } catch (e) {
      print('ERROR: Failed to parse Payment ${doc.id}: $e');
      print('Raw Data: ${doc.data()}');
      return Payment(
        id: doc.id,
        ownerId: '',
        customerId: '',
        amount: 0,
        paymentMode: 'Error',
        mode: 'Error',
        date: DateTime.now(),
        notes: 'Error parsing data: $e',
        createdAt: DateTime.now(),
      );
    }
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
