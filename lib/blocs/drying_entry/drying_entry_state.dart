import 'package:equatable/equatable.dart';
import '../../models/drying_entry_model.dart';

abstract class DryingEntryState extends Equatable {
  const DryingEntryState();

  @override
  List<Object?> get props => [];
}

class DryingEntryInitial extends DryingEntryState {}

class DryingEntryLoading extends DryingEntryState {}

class DryingEntryLoaded extends DryingEntryState {
  final List<DryingEntry> entries;

  const DryingEntryLoaded({required this.entries});

  @override
  List<Object> get props => [entries];
}

class DryingEntryError extends DryingEntryState {
  final String message;

  const DryingEntryError(this.message);

  @override
  List<Object> get props => [message];
}
