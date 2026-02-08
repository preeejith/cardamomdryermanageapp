import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/drying_entry/drying_entry_bloc.dart';
import '../../blocs/drying_entry/drying_entry_event.dart';
import '../../blocs/drying_entry/drying_entry_state.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/customer/customer_state.dart';
import '../../models/customer_model.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EntriesTab extends StatelessWidget {
  const EntriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drying Entries'),
      ),
      body: BlocBuilder<DryingEntryBloc, DryingEntryState>(
        builder: (context, entryState) {
          if (entryState is DryingEntryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (entryState is DryingEntryError) {
            return Center(child: Text('Error: ${entryState.message}'));
          } else if (entryState is DryingEntryLoaded) {
            final entries = entryState.entries;

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No entries yet',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) => Text(
                          'Debug: Owner ID: ${auth.currentUser?.ownerId ?? "None"}',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final ownerId =
                            context.read<AuthProvider>().currentUser?.ownerId ??
                                '';
                        if (ownerId.isNotEmpty) {
                          context
                              .read<DryingEntryBloc>()
                              .add(LoadEntries(ownerId));
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Data'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // TODO: Implement emergency load specific to this button?
                        // For now, let's just guide them to check logs.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please check app logs for "Found X documents"')),
                        );
                      },
                      child: const Text('Troubleshoot: Check Logs'),
                    ),
                  ],
                ),
              );
            }

            return BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, customerState) {
                // We'll use the customer list to find names
                final customers = customerState is CustomerLoaded
                    ? customerState.customers
                    : <Customer>[];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final customer = customers.isEmpty
                        ? null
                        : customers.firstWhere(
                            (c) => c.id == entry.customerId,
                            orElse: () => Customer(
                                id: '',
                                ownerId: '',
                                name: 'Unknown',
                                phone: '',
                                address: '',
                                defaultRate: 0,
                                balanceAmount: 0,
                                totalStockGiven: 0,
                                totalDriedWeight: 0,
                                paidAmount: 0,
                                createdAt: DateTime.now()),
                          );

                    // If we couldn't find the customer and list wasn't empty, checks if it's "Unknown"
                    final customerName =
                        (customer != null && customer.id.isNotEmpty)
                            ? customer.name
                            : (customers.isEmpty
                                ? 'Loading...'
                                : 'Unknown Customer');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              entry.isDried ? Colors.green : Colors.orange,
                          child: Icon(
                            entry.isDried ? Icons.check_circle : Icons.pending,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(customerName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${entry.freshWeightKg} KG → ${entry.driedWeightKg?.toStringAsFixed(2) ?? '?'} KG'),
                            Text(DateFormat('dd MMM yyyy').format(entry.date)),
                          ],
                        ),
                        trailing: entry.amount != null
                            ? Text('₹${entry.amount!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))
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
            );
          }
          return const SizedBox.shrink();
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
            onPressed: () {
              final driedWeight = double.tryParse(driedWeightController.text);
              if (driedWeight != null) {
                // Dispatch event to BLoC
                // We need to access the Bloc from the context that provided it.
                // Since this dialog is a new route, it might strictly not have access to the Provider *above* it
                // unless passed or if using standard Navigator.push which keeps context chain?
                // Actually `MultiBlocProvider` is in `OwnerDashboard`.
                // If `EntriesTab` is in `OwnerDashboard`, it has the providers.
                // But `showDialog` creates a new tree node.
                // We should capture the bloc before showing dialog.

                // Correction: `showDialog` *does* share the widget tree context if using `context` from build,
                // BUT the `builder` context is different.
                // We should use the *outer* context to find the BLoC.
                // But wait, `_showUpdateDialog` is called with `context` from `build`.
                // So we can use that context.
                context.read<DryingEntryBloc>().add(
                      UpdateEntryDrying(
                        entryId: entry.id,
                        driedWeightKg: driedWeight,
                      ),
                    );
                Navigator.pop(context); // Close the dialog immediately
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
