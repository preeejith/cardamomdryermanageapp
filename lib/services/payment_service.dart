import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import 'customer_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerService _customerService = CustomerService();

  // Get payments stream for owner
  Stream<List<Payment>> getPaymentsStream(String ownerId) {
    print('DEBUG: PaymentService - Requesting payments for ownerId: $ownerId');
    return _firestore
        .collection('payments')
        .where('ownerId', isEqualTo: ownerId)
        // .orderBy('date', descending: true) // REMOVED to avoid Index Lockout
        .snapshots()
        .map((snapshot) {
      print(
          'DEBUG: PaymentService - Found ${snapshot.docs.length} documents (Unordered)');
      final payments =
          snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

      // Sort in Dart
      payments.sort((a, b) => b.date.compareTo(a.date));
      return payments;
    });
  }

  // Get payments for specific customer
  Stream<List<Payment>> getCustomerPaymentsStream(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    });
  }

  // Get single payment
  Future<Payment?> getPayment(String paymentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) return null;
      return Payment.fromFirestore(doc);
    } catch (e) {
      print('Error getting payment: $e');
      return null;
    }
  }

  // Add payment
  Future<String> addPayment(Payment payment) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('payments').add(payment.toMap());

      // Update customer totals
      await _customerService.updateCustomerTotals(payment.customerId);

      return docRef.id;
    } catch (e) {
      print('Error adding payment: $e');
      rethrow;
    }
  }

  // Update payment
  Future<void> updatePayment(
      String paymentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update(data);
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  // Delete payment
  Future<void> deletePayment(String paymentId, String customerId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();

      // Update customer totals
      await _customerService.updateCustomerTotals(customerId);
    } catch (e) {
      print('Error deleting payment: $e');
      rethrow;
    }
  }

  // Get payments by date range
  Future<List<Payment>> getPaymentsByDateRange({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('payments')
          .where('ownerId', isEqualTo: ownerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting payments by date: $e');
      return [];
    }
  }

  // Get total payments for customer
  Future<double> getTotalPayments(String customerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error getting total payments: $e');
      return 0;
    }
  }
}
