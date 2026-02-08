import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../models/customer_model.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final String ownerId;

  const LoadCustomers(this.ownerId);

  @override
  List<Object> get props => [ownerId];
}

class UpdateCustomers extends CustomerEvent {
  final List<Customer> customers;

  const UpdateCustomers(this.customers);

  @override
  List<Object> get props => [customers];
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class AddCustomer extends CustomerEvent {
  final Customer customer;
  final Completer<bool>? completer;

  const AddCustomer(this.customer, {this.completer});

  @override
  List<Object?> get props => [customer, completer];
}
