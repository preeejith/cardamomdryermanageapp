import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';
import '../../blocs/customer/customer_bloc.dart';
import '../../blocs/customer/customer_state.dart';
import '../../blocs/drying_entry/drying_entry_bloc.dart';
import '../../blocs/drying_entry/drying_entry_state.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_state.dart';
import '../../blocs/drying_entry/drying_entry_event.dart';
import '../../blocs/payment/payment_event.dart';
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
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging ||
          _tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    // Force load data if not already loaded (Just to be safe)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dryingBloc = context.read<DryingEntryBloc>();
      final paymentBloc = context.read<PaymentBloc>();

      // If state is initial, force load!
      if (dryingBloc.state is DryingEntryInitial) {
        print(
            'DEBUG: CustomerDetailScreen - Force Loading Entries for ${widget.customer.ownerId}');
        dryingBloc.add(LoadEntries(widget.customer.ownerId));
      }
      if (paymentBloc.state is PaymentInitial) {
        print(
            'DEBUG: CustomerDetailScreen - Force Loading Payments for ${widget.customer.ownerId}');
        paymentBloc.add(LoadPayments(widget.customer.ownerId));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPaymentDialog() {
    final paymentBloc = context.read<PaymentBloc>();
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: paymentBloc,
        child: PaymentDialog(
          customerId: widget.customer.id,
          ownerId: widget.customer.ownerId,
        ),
      ),
    );
  }

  void _navigateToAddEntry() {
    final dryingEntryBloc = context.read<DryingEntryBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: dryingEntryBloc,
          child: AddEntryScreen(customer: widget.customer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch CustomerBloc for updates to this specific customer
    final customerState = context.watch<CustomerBloc>().state;
    Customer currentCustomer = widget.customer;

    if (customerState is CustomerLoaded) {
      currentCustomer = customerState.customers.firstWhere(
        (c) => c.id == widget.customer.id,
        orElse: () => widget.customer,
      );
    }

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
                BlocBuilder<DryingEntryBloc, DryingEntryState>(
                  builder: (context, state) {
                    if (state is DryingEntryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is DryingEntryError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is DryingEntryInitial) {
                      return const Center(
                          child: Text(
                              'Initializing data...')); // Should auto-trigger load
                    } else if (state is DryingEntryLoaded) {
                      final entries = state.entries
                          .where((e) => e.customerId == widget.customer.id)
                          .toList();

                      if (entries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No entries found'),
                              const SizedBox(height: 8),
                              Text('Debug: Owner ${widget.customer.ownerId}',
                                  style: TextStyle(
                                      color: Colors.grey[300], fontSize: 10)),
                              Text('Total Loaded: ${state.entries.length}',
                                  style: TextStyle(
                                      color: Colors.grey[300], fontSize: 10)),
                            ],
                          ),
                        );
                      }

                      // Sort by date descending
                      entries.sort((a, b) => b.date.compareTo(a.date));

                      return ListView.builder(
                        itemCount: entries.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
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
                                                : Colors.orange
                                                    .withOpacity(0.1),
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
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Payments Tab
                BlocBuilder<PaymentBloc, PaymentState>(
                  builder: (context, state) {
                    if (state is PaymentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is PaymentError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is PaymentInitial) {
                      return const Center(
                          child: Text('Initializing payments...'));
                    } else if (state is PaymentLoaded) {
                      final payments = state.payments
                          .where((p) => p.customerId == widget.customer.id)
                          .toList();

                      if (payments.isEmpty) {
                        return const Center(child: Text('No payments found'));
                      }

                      // Sort by date descending
                      payments.sort((a, b) => b.date.compareTo(a.date));

                      return ListView.builder(
                        itemCount: payments.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final payment = payments[index];
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
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : FloatingActionButton.extended(
              onPressed: _showAddPaymentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Payment'),
              backgroundColor: Colors.green,
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
