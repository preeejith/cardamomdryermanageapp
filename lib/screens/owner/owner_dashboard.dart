import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_bloc.dart';
import 'package:cardamom_dryer_app/blocs/customer/customer_event.dart';
import 'package:cardamom_dryer_app/blocs/drying_entry/drying_entry_bloc.dart';
import 'package:cardamom_dryer_app/blocs/drying_entry/drying_entry_event.dart';
import 'package:cardamom_dryer_app/blocs/payment/payment_bloc.dart';
import 'package:cardamom_dryer_app/blocs/payment/payment_event.dart';
import 'package:cardamom_dryer_app/screens/tabs/customers_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/entries_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/reports_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/settings_tab.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    CustomersTab(),
    EntriesTab(),
    ReportsTab(),
    SettingsTab(),
  ];

  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final ownerId = authProvider.currentUser?.ownerId;

    if (ownerId != null && ownerId.isNotEmpty && !_dataLoaded) {
      _dataLoaded = true;
      // Trigger data loading once we have a valid ownerId
      context.read<CustomerBloc>().add(LoadCustomers(ownerId));
      context.read<DryingEntryBloc>().add(LoadEntries(ownerId));
      context.read<PaymentBloc>().add(LoadPayments(ownerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Entries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
