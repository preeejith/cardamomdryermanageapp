import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../models/drying_entry_model.dart';

abstract class DryingEntryEvent extends Equatable {
  const DryingEntryEvent();

  @override
  List<Object?> get props => [];
}

class LoadEntries extends DryingEntryEvent {
  final String ownerId;

  const LoadEntries(this.ownerId);

  @override
  List<Object> get props => [ownerId];
}

class UpdateEntries extends DryingEntryEvent {
  final List<DryingEntry> entries;

  const UpdateEntries(this.entries);

  @override
  List<Object> get props => [entries];
}

class UpdateEntryDrying extends DryingEntryEvent {
  final String entryId;
  final double driedWeightKg;
  final String? notes;

  const UpdateEntryDrying({
    required this.entryId,
    required this.driedWeightKg,
    this.notes,
  });

  @override
  List<Object?> get props => [entryId, driedWeightKg, notes];
}

class AddEntry extends DryingEntryEvent {
  final DryingEntry entry;
  final Completer<bool>? completer;

  const AddEntry(this.entry, {this.completer});

  @override
  List<Object?> get props => [entry, completer];
}
