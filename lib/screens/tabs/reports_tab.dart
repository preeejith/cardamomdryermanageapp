import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/drying_entry_provider.dart';
import '../../../providers/payment_provider.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Consumer3<CustomerProvider, DryingEntryProvider, PaymentProvider>(
            builder: (context, customerProvider, entryProvider, paymentProvider, child) {
              final totalCustomers = customerProvider.customers.length;
              final totalEntries = entryProvider.entries.length;
              final pendingEntries = entryProvider.entries.where((e) => e.status == 'received').length;
              
              double totalRevenue = 0;
              double totalPending = 0;
              
              for (var customer in customerProvider.customers) {
                totalRevenue += customer.totalAmountPayable;
                totalPending += customer.balanceAmount;
              }

              return Column(
                children: [
                  _buildStatCard(
                    'Total Customers',
                    totalCustomers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Total Entries',
                    totalEntries.toString(),
                    Icons.inventory,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Pending Entries',
                    pendingEntries.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Total Revenue',
                    '₹${totalRevenue.toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Total Pending',
                    '₹${totalPending.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Outstanding Customers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Consumer<CustomerProvider>(
            builder: (context, customerProvider, child) {
              final outstandingCustomers = customerProvider.customers
                  .where((c) => c.balanceAmount > 0)
                  .toList()
                ..sort((a, b) => b.balanceAmount.compareTo(a.balanceAmount));

              if (outstandingCustomers.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No outstanding payments')),
                  ),
                );
              }

              return Column(
                children: outstandingCustomers.map((customer) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red[100],
                        child: Icon(Icons.person, color: Colors.red[700]),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      trailing: Text(
                        '₹${customer.balanceAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
