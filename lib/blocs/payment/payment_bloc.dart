import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/payment_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  StreamSubscription? _paymentSubscription;

  PaymentBloc({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService(),
        super(PaymentInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<UpdatePayments>(_onUpdatePayments);
    on<AddPayment>(_onAddPayment);
  }

  void _onLoadPayments(LoadPayments event, Emitter<PaymentState> emit) {
    print(
        'DEBUG: PaymentBloc - Loading payments for ownerId: ${event.ownerId}');
    emit(PaymentLoading());
    _paymentSubscription?.cancel();
    _paymentSubscription =
        _paymentService.getPaymentsStream(event.ownerId).listen(
      (payments) {
        print('DEBUG: PaymentBloc - Loaded ${payments.length} payments');
        add(UpdatePayments(payments));
      },
      onError: (error) {
        print('DEBUG: PaymentBloc - Error loading payments: $error');
        emit(PaymentError(error.toString()));
      },
    );
  }

  Future<void> _onAddPayment(
      AddPayment event, Emitter<PaymentState> emit) async {
    try {
      await _paymentService.addPayment(event.payment);
      event.completer?.complete(true);
    } catch (e) {
      event.completer?.complete(false);
      emit(PaymentError(e.toString()));
    }
  }

  void _onUpdatePayments(UpdatePayments event, Emitter<PaymentState> emit) {
    emit(PaymentLoaded(payments: event.payments));
  }

  @override
  Future<void> close() {
    _paymentSubscription?.cancel();
    return super.close();
  }
}
