import 'package:equatable/equatable.dart';
import '../../models/customer_model.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;
  final List<Customer> filteredCustomers;

  const CustomerLoaded({
    required this.customers,
    this.filteredCustomers = const [],
  });

  @override
  List<Object> get props => [customers, filteredCustomers];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}
