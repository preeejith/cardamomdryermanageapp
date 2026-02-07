import 'package:cardamom_dryer_app/screens/tabs/customers_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/entries_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/reports_tab.dart';
import 'package:cardamom_dryer_app/screens/tabs/settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/drying_entry_provider.dart';
import '../../providers/payment_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.currentUser?.ownerId ?? '';

    if (ownerId.isNotEmpty) {
      Provider.of<CustomerProvider>(context, listen: false)
          .listenToCustomers(ownerId);
      Provider.of<DryingEntryProvider>(context, listen: false)
          .listenToEntries(ownerId);
      Provider.of<PaymentProvider>(context, listen: false)
          .listenToPayments(ownerId);
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
