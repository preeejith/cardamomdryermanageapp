import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../providers/drying_entry_provider.dart';
import '../../providers/payment_provider.dart';
import '../common/payment_dialog.dart';
import 'add_entry_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Refresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerId = widget.customer.id;
      final ownerId = widget.customer.ownerId;

      Provider.of<DryingEntryProvider>(context, listen: false)
          .listenToCustomerEntries(customerId);
      Provider.of<PaymentProvider>(context, listen: false)
          .listenToCustomerPayments(customerId);
      // Refresh customer to get latest totals
      Provider.of<CustomerProvider>(context, listen: false)
          .listenToCustomers(ownerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        customerId: widget.customer.id,
        ownerId: widget.customer.ownerId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get latest customer data from provider to show updated totals
    final customerProvider = Provider.of<CustomerProvider>(context);
    final currentCustomer =
        customerProvider.getCustomerById(widget.customer.id) ?? widget.customer;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCustomer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit customer
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Drying Entries'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      'Total Stock',
                      '${currentCustomer.totalStockGiven.toStringAsFixed(1)} kg',
                      Icons.inventory_2_outlined,
                      Colors.blue,
                    ),
                    _buildSummaryItem(
                      context,
                      'Balance',
                      '₹${currentCustomer.balanceAmount.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_outlined,
                      currentCustomer.balanceAmount > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      'Total Dried',
                      '${currentCustomer.totalDriedWeight.toStringAsFixed(1)} kg',
                      Icons.local_fire_department_outlined,
                      Colors.orange,
                    ),
                    _buildSummaryItem(
                      context,
                      'Paid',
                      '₹${currentCustomer.paidAmount.toStringAsFixed(0)}',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Drying Entries Tab
                Consumer<DryingEntryProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.entries.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.entries.isEmpty) {
                      return const Center(child: Text('No entries found'));
                    }

                    return ListView.builder(
                      itemCount: provider.entries.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final entry = provider.entries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              // Show details or edit
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(entry.date),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: entry.status == 'dried'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          entry.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: entry.status == 'dried'
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Fresh: ${entry.freshWeightKg} kg',
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                            ),
                                            if (entry.status == 'dried')
                                              Text(
                                                'Dried: ${entry.driedWeightKg} kg',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rate: ₹${entry.ratePerKg}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                          if (entry.amount != null &&
                                              entry.amount! > 0)
                                            Text(
                                              '₹${entry.amount!.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Payments Tab
                Consumer<PaymentProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.payments.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.payments.isEmpty) {
                      return const Center(child: Text('No payments found'));
                    }

                    return ListView.builder(
                      itemCount: provider.payments.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final payment = provider.payments[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.green),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(payment.date),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        payment.paymentMode,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13),
                                      ),
                                      if (payment.notes != null)
                                        Text(
                                          payment.notes!,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                              fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${payment.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Payment'),
        backgroundColor:
            Colors.green, // Explicitly green as requested for payment
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
