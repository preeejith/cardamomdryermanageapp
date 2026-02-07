import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';

class AddPaymentScreen extends StatefulWidget {
  final Customer customer;

  const AddPaymentScreen({super.key, required this.customer});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentMode = 'Cash';

  @override
  void dispose() {
    _amountController.dispose();
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

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.currentUser?.ownerId ?? '';

    final payment = Payment(
      id: '',
      ownerId: ownerId,
      customerId: widget.customer.id,
      amount: double.parse(_amountController.text),
      paymentMode: _paymentMode,
      mode: _paymentMode,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    final success = await Provider.of<PaymentProvider>(context, listen: false)
        .addPayment(payment);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment added successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<PaymentProvider>(context, listen: false).errorMessage ?? 'Failed to add payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Balance: ₹${widget.customer.balanceAmount.toStringAsFixed(2)}'),
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
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (double.tryParse(value) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMode,
              decoration: const InputDecoration(
                labelText: 'Payment Mode',
                prefixIcon: Icon(Icons.payment),
              ),
              items: ['Cash', 'UPI', 'Bank Transfer'].map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _paymentMode = value!;
                });
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
            Consumer<PaymentProvider>(
              builder: (context, paymentProvider, child) {
                return ElevatedButton(
                  onPressed: paymentProvider.isLoading ? null : _savePayment,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: paymentProvider.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Payment'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
