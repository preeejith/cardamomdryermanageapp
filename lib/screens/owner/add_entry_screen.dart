import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/drying_entry_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer_model.dart';
import '../../models/drying_entry_model.dart';

class AddEntryScreen extends StatefulWidget {
  final Customer customer;

  const AddEntryScreen({super.key, required this.customer});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _freshWeightController = TextEditingController();
  final _bagsController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _rateController.text = widget.customer.defaultRate.toString();
  }

  @override
  void dispose() {
    _freshWeightController.dispose();
    _bagsController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.currentUser?.ownerId ?? '';

    final entry = DryingEntry(
      id: '',
      ownerId: ownerId,
      customerId: widget.customer.id,
      date: _selectedDate,
      freshWeightKg: double.parse(_freshWeightController.text),
      bagsCount: int.parse(_bagsController.text),
      ratePerKg: double.parse(_rateController.text),
      status: 'received',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    final success = await Provider.of<DryingEntryProvider>(context, listen: false)
        .addEntry(entry);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry added successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<DryingEntryProvider>(context, listen: false).errorMessage ?? 'Failed to add entry'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Drying Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.customer.phone),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[100],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _freshWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Fresh Stock Weight (KG) *',
                prefixIcon: Icon(Icons.scale),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bagsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Bags *',
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (int.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rate per KG (₹) *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 24),
            Consumer<DryingEntryProvider>(
              builder: (context, entryProvider, child) {
                return ElevatedButton(
                  onPressed: entryProvider.isLoading ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: entryProvider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Entry'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
