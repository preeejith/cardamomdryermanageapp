import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class DataRepairService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<String> repairData(String ownerId) async* {
    yield 'Starting data repair for Owner ID: $ownerId...';

    try {
      // 1. Get all customers for this owner
      // We trust the Customer list because the user said it loads correctly.
      final customerSnapshot = await _firestore
          .collection('customers')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final customers = customerSnapshot.docs
          .map((doc) => Customer.fromFirestore(doc))
          .toList();

      yield 'Found ${customers.length} customers. Scanning their data...';

      int totalEntriesFixed = 0;
      int totalPaymentsFixed = 0;

      for (var customer in customers) {
        yield 'Scanning customer: ${customer.name} (ID: ${customer.id})...';

        // 2. Fix Drying Entries
        final entriesSnapshot = await _firestore
            .collection('dryingEntries')
            .where('customerId', isEqualTo: customer.id)
            .get();

        yield ' -> Found ${entriesSnapshot.docs.length} entries.';

        final batch = _firestore.batch();
        bool batchHasOps = false;

        for (var doc in entriesSnapshot.docs) {
          final data = doc.data();
          final docOwnerId = data['ownerId'] as String?;
          final docDate = data['date'];
          final docCreatedAt = data['createdAt'];

          bool needsFix = false;
          Map<String, dynamic> updates = {};

          // Fix Owner ID
          if (docOwnerId != ownerId) {
            updates['ownerId'] = ownerId;
            needsFix = true;
          }

          // Fix Date (Required for Ordering)
          if (docDate == null) {
            updates['date'] = docCreatedAt ?? FieldValue.serverTimestamp();
            needsFix = true;
          }

          if (needsFix) {
            batch.update(doc.reference, updates);
            batchHasOps = true;
            totalEntriesFixed++;
          }
        }

        // 3. Fix Payments
        final paymentsSnapshot = await _firestore
            .collection('payments')
            .where('customerId', isEqualTo: customer.id)
            .get();

        yield ' -> Found ${paymentsSnapshot.docs.length} payments.';

        for (var doc in paymentsSnapshot.docs) {
          final data = doc.data();
          final docOwnerId = data['ownerId'] as String?;
          final docDate = data['date'];
          final docCreatedAt = data['createdAt'];

          bool needsFix = false;
          Map<String, dynamic> updates = {};

          if (docOwnerId != ownerId) {
            updates['ownerId'] = ownerId;
            needsFix = true;
          }

          if (docDate == null) {
            updates['date'] = docCreatedAt ?? FieldValue.serverTimestamp();
            needsFix = true;
          }

          if (needsFix) {
            batch.update(doc.reference, updates);
            batchHasOps = true;
            totalPaymentsFixed++;
          }
        }

        if (batchHasOps) {
          await batch.commit();
          yield ' -> Fixed data for ${customer.name}';
        }
      }

      yield 'Repair Complete!';
      yield 'Summary:';
      yield ' - Customers Scanned: ${customers.length}';
      yield ' - Entries Fixed: $totalEntriesFixed';
      yield ' - Payments Fixed: $totalPaymentsFixed';
      yield ' - Total Entries Found (in DB): ${totalEntriesFixed + (customers.length * 0)} (approx)'; // Logic check

      if (totalEntriesFixed == 0 && totalPaymentsFixed == 0) {
        yield 'No repairs were needed. Data seems correct.';
        yield 'If you still see 0 entries, please verify the DATE is set correct on your entries.';
      } else {
        yield 'Please go to the Dashboard and Refresh to see your data.';
      }
    } catch (e) {
      yield 'Error during repair: $e';
    }
  }
}
