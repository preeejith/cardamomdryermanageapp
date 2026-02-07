import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/drying_entry_provider.dart';
import '../../../providers/customer_provider.dart';

class EntriesTab extends StatelessWidget {
  const EntriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drying Entries'),
      ),
      body: Consumer2<DryingEntryProvider, CustomerProvider>(
        builder: (context, entryProvider, customerProvider, child) {
          final entries = entryProvider.entries;

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No entries yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final customer = customerProvider.getCustomerById(entry.customerId);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: entry.isDried ? Colors.green : Colors.orange,
                    child: Icon(
                      entry.isDried ? Icons.check_circle : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(customer?.name ?? 'Unknown Customer'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.freshWeightKg} KG → ${entry.driedWeightKg?.toStringAsFixed(2) ?? '?'} KG'),
                      Text(DateFormat('dd MMM yyyy').format(entry.date)),
                    ],
                  ),
                  trailing: entry.amount != null
                      ? Text('₹${entry.amount!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : TextButton(
                          onPressed: () {
                            _showUpdateDialog(context, entry);
                          },
                          child: const Text('Update'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, entry) {
    final driedWeightController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Dried Weight'),
        content: TextField(
          controller: driedWeightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Dried Weight (KG)',
            hintText: 'Enter dried weight',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final driedWeight = double.tryParse(driedWeightController.text);
              if (driedWeight != null) {
                final success = await Provider.of<DryingEntryProvider>(
                  context,
                  listen: false,
                ).updateEntryAfterDrying(
                  entryId: entry.id,
                  driedWeightKg: driedWeight,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Updated successfully' : 'Failed to update'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
