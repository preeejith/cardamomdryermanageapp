import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  
  List<Payment> _payments = [];
  Payment? _selectedPayment;
  bool _isLoading = false;
  String? _errorMessage;

  List<Payment> get payments => _payments;
  Payment? get selectedPayment => _selectedPayment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToPayments(String ownerId) {
    _paymentService.getPaymentsStream(ownerId).listen(
      (payments) {
        _payments = payments;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void listenToCustomerPayments(String customerId) {
    _paymentService.getCustomerPaymentsStream(customerId).listen(
      (payments) {
        _payments = payments;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> loadPayment(String paymentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedPayment = await _paymentService.getPayment(paymentId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment(Payment payment) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _paymentService.addPayment(payment);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePayment(String paymentId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _paymentService.updatePayment(paymentId, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePayment(String paymentId, String customerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _paymentService.deletePayment(paymentId, customerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedPayment(Payment? payment) {
    _selectedPayment = payment;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<Payment> getPaymentsByCustomer(String customerId) {
    return _payments.where((p) => p.customerId == customerId).toList();
  }

  double getTotalPaymentsForCustomer(String customerId) {
    return _payments
        .where((p) => p.customerId == customerId)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }
}
