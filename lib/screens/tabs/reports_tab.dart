import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_state.dart';
import 'package:cardamom_dryer_app/blocs/drying_entry/drying_entry_bloc.dart';
import 'package:cardamom_dryer_app/blocs/drying_entry/drying_entry_state.dart';
import 'package:cardamom_dryer_app/blocs/payment/payment_bloc.dart';
import 'package:cardamom_dryer_app/blocs/payment/payment_state.dart';
import '../../models/customer_model.dart';
import '../../models/drying_entry_model.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final customerState = context.watch<CustomerBloc>().state;
    final entryState = context.watch<DryingEntryBloc>().state;
    // PaymentBloc also needs to be watched if used (conceptually revenue logic usually involves payments,
    // but the original code calculated revenue from 'customer.totalAmountPayable' which is likely derived from entries/payments in the backend or service?
    // Wait, original code:
    // Consumer3<CustomerProvider, DryingEntryProvider, PaymentProvider>
    // totalRevenue += customer.totalAmountPayable;
    // totalPending += customer.balanceAmount;
    // It didn't explicitly use PaymentProvider data in the loop, but it CONSUMED it.
    // Maybe to ensure it rebuilds if payments change (which updates customer balance).
    final paymentState = context.watch<PaymentBloc>().state;

    List<Customer> customers = [];
    List<DryingEntry> entries = [];
    // payments unused directly but ensuring we are up to date.

    if (customerState is CustomerLoaded) customers = customerState.customers;
    if (entryState is DryingEntryLoaded) entries = entryState.entries;

    // Loading state check could be here, but maybe we just show 0 until loaded to avoid flickering or if one loads faster.
    // Or simpler:
    final isLoading = customerState is CustomerLoading ||
        entryState is DryingEntryLoading ||
        paymentState is PaymentLoading;
    if (isLoading && customers.isEmpty && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalCustomers = customers.length;
    final totalEntries = entries.length;
    final pendingEntries = entries.where((e) => e.status == 'received').length;

    double totalRevenue = 0;
    double totalPending = 0;

    for (var customer in customers) {
      totalRevenue += customer.totalAmountPayable;
      totalPending += customer.balanceAmount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
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
          ),
          const SizedBox(height: 24),
          const Text(
            'Outstanding Customers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final outstandingCustomers = customers
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
