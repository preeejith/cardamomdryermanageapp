import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/drying_entry_model.dart';
import 'customer_service.dart';

class DryingEntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CustomerService _customerService = CustomerService();

  // Get entries stream for owner
  Stream<List<DryingEntry>> getEntriesStream(String ownerId) {
    // Client-side sorting to avoid Index issues
    print(
        'DEBUG: DryingEntryService - Requesting entries for ownerId: $ownerId');
    return _firestore
        .collection('dryingEntries')
        .where('ownerId', isEqualTo: ownerId)
        // .orderBy('date', descending: true) // REMOVED to avoid Index Lockout
        .snapshots()
        .map((snapshot) {
      print(
          'DEBUG: DryingEntryService - Found ${snapshot.docs.length} documents (Unordered)');
      final entries =
          snapshot.docs.map((doc) => DryingEntry.fromFirestore(doc)).toList();

      // Sort in Dart
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    }).handleError((error) {
      print('ERROR: DryingEntryService - Query failed: $error');
      throw error;
    });
  }

  // Get entries for specific customer
  Stream<List<DryingEntry>> getCustomerEntriesStream(String customerId) {
    return _firestore
        .collection('dryingEntries')
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DryingEntry.fromFirestore(doc))
          .toList();
    });
  }

  // Get single entry
  Future<DryingEntry?> getEntry(String entryId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('dryingEntries').doc(entryId).get();

      if (!doc.exists) return null;
      return DryingEntry.fromFirestore(doc);
    } catch (e) {
      print('Error getting entry: $e');
      return null;
    }
  }

  // Add new drying entry
  Future<String> addEntry(DryingEntry entry) async {
    try {
      print('DEBUG: Starting addEntry for customer ${entry.customerId}');
      DocumentReference docRef =
          await _firestore.collection('dryingEntries').add(entry.toMap());
      print('DEBUG: Entry added to Firestore with ID: ${docRef.id}');

      // Update customer totals
      print('DEBUG: Calling updateCustomerTotals');
      await _customerService.updateCustomerTotals(entry.customerId);
      print('DEBUG: updateCustomerTotals completed');

      return docRef.id;
    } catch (e) {
      print('Error adding entry: $e');
      rethrow;
    }
  }

  // Update entry (when drying is completed)
  Future<void> updateEntryAfterDrying({
    required String entryId,
    required double driedWeightKg,
    String? notes,
  }) async {
    try {
      // Get the entry first
      DocumentSnapshot doc =
          await _firestore.collection('dryingEntries').doc(entryId).get();

      if (!doc.exists) throw Exception('Entry not found');

      var data = doc.data() as Map<String, dynamic>;
      double freshWeightKg = (data['freshWeightKg'] ?? 0).toDouble();
      double ratePerKg = (data['ratePerKg'] ?? 0).toDouble();
      String customerId = data['customerId'] ?? '';

      // Calculate loss and amount
      double dryingLoss = freshWeightKg - driedWeightKg;
      double amount = freshWeightKg * ratePerKg;

      // Update entry
      await _firestore.collection('dryingEntries').doc(entryId).update({
        'driedWeightKg': driedWeightKg,
        'dryingLoss': dryingLoss,
        'amount': amount,
        'status': 'dried',
        'updatedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'notes': notes,
      });

      // Update customer totals
      await _customerService.updateCustomerTotals(customerId);
    } catch (e) {
      print('Error updating entry: $e');
      rethrow;
    }
  }

  // Update entry
  Future<void> updateEntry(String entryId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('dryingEntries').doc(entryId).update(data);
    } catch (e) {
      print('Error updating entry: $e');
      rethrow;
    }
  }

  // Delete entry
  Future<void> deleteEntry(String entryId, String customerId) async {
    try {
      await _firestore.collection('dryingEntries').doc(entryId).delete();

      // Update customer totals
      await _customerService.updateCustomerTotals(customerId);
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  // Get entries by date range
  Future<List<DryingEntry>> getEntriesByDateRange({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dryingEntries')
          .where('ownerId', isEqualTo: ownerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DryingEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries by date: $e');
      return [];
    }
  }

  // Get pending entries (not yet dried)
  Future<List<DryingEntry>> getPendingEntries(String ownerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dryingEntries')
          .where('ownerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'received')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DryingEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pending entries: $e');
      return [];
    }
  }
}
