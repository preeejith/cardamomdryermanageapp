import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get customers stream for owner
  Stream<List<Customer>> getCustomersStream(String ownerId) {
    return _firestore
        .collection('customers')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    });
  }

  // Get single customer
  Future<Customer?> getCustomer(String customerId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('customers').doc(customerId).get();

      if (!doc.exists) return null;
      return Customer.fromFirestore(doc);
    } catch (e) {
      print('Error getting customer: $e');
      return null;
    }
  }

  // Add customer
  Future<String> addCustomer(Customer customer) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('customers').add(customer.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding customer: $e');
      rethrow;
    }
  }

  // Update customer
  Future<void> updateCustomer(
      String customerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('customers').doc(customerId).update(data);
    } catch (e) {
      print('Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _firestore.collection('customers').doc(customerId).delete();
    } catch (e) {
      print('Error deleting customer: $e');
      rethrow;
    }
  }

  // Search customers by name or phone
  Future<List<Customer>> searchCustomers(String ownerId, String query) async {
    try {
      // Search by name
      QuerySnapshot nameQuery = await _firestore
          .collection('customers')
          .where('ownerId', isEqualTo: ownerId)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Search by phone
      QuerySnapshot phoneQuery = await _firestore
          .collection('customers')
          .where('ownerId', isEqualTo: ownerId)
          .where('phone', isGreaterThanOrEqualTo: query)
          .where('phone', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      Set<Customer> customers = {};

      for (var doc in nameQuery.docs) {
        customers.add(Customer.fromFirestore(doc));
      }

      for (var doc in phoneQuery.docs) {
        customers.add(Customer.fromFirestore(doc));
      }

      return customers.toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // Update customer totals (called after adding entry or payment)
  Future<void> updateCustomerTotals(String customerId) async {
    try {
      // Get all drying entries for customer
      QuerySnapshot entriesSnapshot = await _firestore
          .collection('dryingEntries')
          .where('customerId', isEqualTo: customerId)
          .get();

      double totalStockGiven = 0;
      double totalDriedWeight = 0;
      double totalAmountPayable = 0;

      for (var doc in entriesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        totalStockGiven += (data['freshWeightKg'] ?? 0).toDouble();
        if (data['driedWeightKg'] != null) {
          totalDriedWeight += (data['driedWeightKg']).toDouble();
        }
        if (data['amount'] != null) {
          totalAmountPayable += (data['amount']).toDouble();
        }
      }

      // Get all payments for customer
      QuerySnapshot paymentsSnapshot = await _firestore
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .get();

      double paidAmount = 0;
      for (var doc in paymentsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        paidAmount += (data['amount'] ?? 0).toDouble();
      }

      // Get old pending amount
      DocumentSnapshot customerDoc =
          await _firestore.collection('customers').doc(customerId).get();

      double oldPendingAmount = 0;
      double oldStockKg = 0;
      if (customerDoc.exists) {
        var customerData = customerDoc.data() as Map<String, dynamic>;
        oldPendingAmount = (customerData['oldPendingAmount'] ?? 0).toDouble();
        oldStockKg = (customerData['oldStockKg'] ?? 0).toDouble();
      }

      double balanceAmount =
          (totalAmountPayable + oldPendingAmount) - paidAmount;

      // Update customer document
      await _firestore.collection('customers').doc(customerId).update({
        'totalStockGiven': totalStockGiven + oldStockKg,
        'totalDriedWeight': totalDriedWeight,
        'totalAmountPayable': totalAmountPayable,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
      });
    } catch (e) {
      print('Error updating customer totals: $e');
      rethrow;
    }
  }
}
