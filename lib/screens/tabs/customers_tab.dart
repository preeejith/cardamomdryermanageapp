import 'package:cardamom_dryer_app/screens/owner/add_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_event.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_state.dart';
import 'package:cardamom_dryer_app/blocs/drying_entry/drying_entry_bloc.dart';
import 'package:cardamom_dryer_app/blocs/payment/payment_bloc.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../owner/customer_detail_screen.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final ownerId = authProvider.currentUser?.ownerId ?? '';
              context.read<CustomerBloc>().add(LoadCustomers(ownerId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<CustomerBloc>()
                              .add(const SearchCustomers(''));
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<CustomerBloc>().add(SearchCustomers(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CustomerError) {
                  return Center(child: Text('Error: ${state.message}'));
                } else if (state is CustomerLoaded) {
                  final customers = state.filteredCustomers;

                  if (customers.isEmpty) {
                    if (_searchController.text.isNotEmpty) {
                      return const Center(
                        child: Text(
                          'No customers found matching search',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first customer',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: customers.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.phone),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Balance: ₹${customer.balanceAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: customer.balanceAmount > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final customerBloc = context.read<CustomerBloc>();
                            final dryingEntryBloc =
                                context.read<DryingEntryBloc>();
                            final paymentBloc = context.read<PaymentBloc>();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(value: customerBloc),
                                    BlocProvider.value(value: dryingEntryBloc),
                                    BlocProvider.value(value: paymentBloc),
                                  ],
                                  child: CustomerDetailScreen(
                                    customer: customer,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCustomerScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
