import 'package:cardamom_dryer_app/screens/owner/add_entry_screen.dart';
import 'package:cardamom_dryer_app/screens/owner/add_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer_model.dart';
import '../../blocs/drying_entry/drying_entry_bloc.dart';
import '../../blocs/drying_entry/drying_entry_state.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_state.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppMessage() async {
    final phone = widget.customer.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final message =
        'Hello ${widget.customer.name}, your current balance is ₹${widget.customer.balanceAmount.toStringAsFixed(2)}';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: _sendWhatsAppMessage,
            tooltip: 'Send WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit customer screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Stock',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                              '${widget.customer.totalStockGiven.toStringAsFixed(2)} KG',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dried',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                              '${widget.customer.totalDriedWeight.toStringAsFixed(2)} KG',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                              '₹${widget.customer.totalAmountPayable.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                              '₹${widget.customer.paidAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Balance: ',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text(
                          '₹${widget.customer.balanceAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.customer.balanceAmount > 0
                                ? Colors.red
                                : Colors.green,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Entries'),
              Tab(text: 'Payments'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEntriesTab(),
                _buildPaymentsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEntryScreen(customer: widget.customer),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddPaymentScreen(customer: widget.customer),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add Entry' : 'Add Payment'),
      ),
    );
  }

  Widget _buildEntriesTab() {
    return BlocBuilder<DryingEntryBloc, DryingEntryState>(
      builder: (context, state) {
        if (state is DryingEntryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DryingEntryLoaded) {
          // Filter entries for this customer
          final entries = state.entries
              .where((e) => e.customerId == widget.customer.id)
              .toList();

          if (entries.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }

          // Sort by date descending
          entries.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        entry.isDried ? Colors.green : Colors.orange,
                    child: Icon(
                      entry.isDried ? Icons.check : Icons.pending,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                      '${entry.freshWeightKg} KG → ${entry.driedWeightKg?.toStringAsFixed(2) ?? '?'} KG'),
                  subtitle: Text(DateFormat('dd MMM yyyy').format(entry.date)),
                  trailing: entry.amount != null
                      ? Text('₹${entry.amount!.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
              );
            },
          );
        }

        if (state is DryingEntryError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        return const Center(child: Text('No entries available'));
      },
    );
  }

  Widget _buildPaymentsTab() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PaymentLoaded) {
          // Filter payments for this customer
          final payments = state.payments
              .where((p) => p.customerId == widget.customer.id)
              .toList();

          if (payments.isEmpty) {
            return const Center(child: Text('No payments yet'));
          }

          // Sort by date descending
          payments.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.payment, color: Colors.white),
                  ),
                  title: Text('₹${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${payment.paymentMode} - ${DateFormat('dd MMM yyyy').format(payment.date)}'),
                ),
              );
            },
          );
        }

        if (state is PaymentError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        return const Center(child: Text('No payments available'));
      },
    );
  }
}
