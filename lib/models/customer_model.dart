import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String ownerId;
  final String name;
  final String phone;
  final String address;
  final double defaultRate;
  final double oldStockKg;
  final double oldPendingAmount;
  final String? notes;
  final DateTime createdAt;

  // Calculated fields
  double totalStockGiven;
  double totalDriedWeight;
  double totalAmountPayable;
  double paidAmount;
  double balanceAmount;

  Customer({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.phone,
    required this.address,
    required this.defaultRate,
    this.oldStockKg = 0,
    this.oldPendingAmount = 0,
    this.notes,
    required this.createdAt,
    this.totalStockGiven = 0,
    this.totalDriedWeight = 0,
    this.totalAmountPayable = 0,
    this.paidAmount = 0,
    this.balanceAmount = 0,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      defaultRate: (data['defaultRate'] ?? 0).toDouble(),
      oldStockKg: (data['oldStockKg'] ?? 0).toDouble(),
      oldPendingAmount: (data['oldPendingAmount'] ?? 0).toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      totalStockGiven: (data['totalStockGiven'] ?? 0).toDouble(),
      totalDriedWeight: (data['totalDriedWeight'] ?? 0).toDouble(),
      totalAmountPayable: (data['totalAmountPayable'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      balanceAmount: (data['balanceAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'phone': phone,
      'address': address,
      'defaultRate': defaultRate,
      'oldStockKg': oldStockKg,
      'oldPendingAmount': oldPendingAmount,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalStockGiven': totalStockGiven,
      'totalDriedWeight': totalDriedWeight,
      'totalAmountPayable': totalAmountPayable,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
    };
  }

  Customer copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? phone,
    String? address,
    double? defaultRate,
    double? oldStockKg,
    double? oldPendingAmount,
    String? notes,
    DateTime? createdAt,
    double? totalStockGiven,
    double? totalDriedWeight,
    double? totalAmountPayable,
    double? paidAmount,
    double? balanceAmount,
  }) {
    return Customer(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      defaultRate: defaultRate ?? this.defaultRate,
      oldStockKg: oldStockKg ?? this.oldStockKg,
      oldPendingAmount: oldPendingAmount ?? this.oldPendingAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      totalStockGiven: totalStockGiven ?? this.totalStockGiven,
      totalDriedWeight: totalDriedWeight ?? this.totalDriedWeight,
      totalAmountPayable: totalAmountPayable ?? this.totalAmountPayable,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
    );
  }
}
