import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../models/payment_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentEvent {
  final String ownerId;

  const LoadPayments(this.ownerId);

  @override
  List<Object> get props => [ownerId];
}

class UpdatePayments extends PaymentEvent {
  final List<Payment> payments;

  const UpdatePayments(this.payments);

  @override
  List<Object> get props => [payments];
}

class AddPayment extends PaymentEvent {
  final Payment payment;
  final Completer<bool>? completer;

  const AddPayment(this.payment, {this.completer});

  @override
  List<Object?> get props => [payment, completer];
}
