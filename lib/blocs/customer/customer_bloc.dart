import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/customer_service.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerService _customerService;
  StreamSubscription? _customerSubscription;

  CustomerBloc({CustomerService? customerService})
      : _customerService = customerService ?? CustomerService(),
        super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<UpdateCustomers>(_onUpdateCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<AddCustomer>(_onAddCustomer);
  }

  void _onLoadCustomers(LoadCustomers event, Emitter<CustomerState> emit) {
    emit(CustomerLoading());
    _customerSubscription?.cancel();
    _customerSubscription =
        _customerService.getCustomersStream(event.ownerId).listen(
              (customers) => add(UpdateCustomers(customers)),
              onError: (error) => emit(CustomerError(error
                  .toString())), // This might need to be an event if we want to emit error from stream
            );
  }

  Future<void> _onAddCustomer(
      AddCustomer event, Emitter<CustomerState> emit) async {
    try {
      await _customerService.addCustomer(event.customer);
      event.completer?.complete(true);
    } catch (e) {
      event.completer?.complete(false);
      emit(CustomerError(e.toString()));
    }
  }

  void _onUpdateCustomers(UpdateCustomers event, Emitter<CustomerState> emit) {
    emit(CustomerLoaded(
        customers: event.customers, filteredCustomers: event.customers));
  }

  void _onSearchCustomers(SearchCustomers event, Emitter<CustomerState> emit) {
    final currentState = state;
    if (currentState is CustomerLoaded) {
      if (event.query.isEmpty) {
        emit(CustomerLoaded(
          customers: currentState.customers,
          filteredCustomers: currentState.customers,
        ));
      } else {
        final filtered = currentState.customers.where((customer) {
          return customer.name
                  .toLowerCase()
                  .contains(event.query.toLowerCase()) ||
              customer.phone.contains(event.query);
        }).toList();

        emit(CustomerLoaded(
          customers: currentState.customers,
          filteredCustomers: filtered,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _customerSubscription?.cancel();
    return super.close();
  }
}
