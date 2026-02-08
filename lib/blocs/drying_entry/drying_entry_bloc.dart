import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/drying_entry_service.dart';
import 'drying_entry_event.dart';
import 'drying_entry_state.dart';

class DryingEntryBloc extends Bloc<DryingEntryEvent, DryingEntryState> {
  final DryingEntryService _entryService;
  StreamSubscription? _entrySubscription;

  DryingEntryBloc({DryingEntryService? entryService})
      : _entryService = entryService ?? DryingEntryService(),
        super(DryingEntryInitial()) {
    on<LoadEntries>(_onLoadEntries);
    on<UpdateEntries>(_onUpdateEntries);
    on<UpdateEntryDrying>(_onUpdateEntryDrying);
    on<AddEntry>(_onAddEntry);
  }

  void _onLoadEntries(LoadEntries event, Emitter<DryingEntryState> emit) {
    print(
        'DEBUG: DryingEntryBloc - Loading entries for ownerId: ${event.ownerId}');
    emit(DryingEntryLoading());
    _entrySubscription?.cancel();
    _entrySubscription = _entryService.getEntriesStream(event.ownerId).listen(
      (entries) {
        print('DEBUG: DryingEntryBloc - Loaded ${entries.length} entries');
        add(UpdateEntries(entries));
      },
      onError: (error) {
        print('DEBUG: DryingEntryBloc - Error loading entries: $error');
        emit(DryingEntryError(error.toString()));
      },
    );
  }

  void _onUpdateEntries(UpdateEntries event, Emitter<DryingEntryState> emit) {
    emit(DryingEntryLoaded(entries: event.entries));
  }

  Future<void> _onUpdateEntryDrying(
      UpdateEntryDrying event, Emitter<DryingEntryState> emit) async {
    try {
      await _entryService.updateEntryAfterDrying(
        entryId: event.entryId,
        driedWeightKg: event.driedWeightKg,
        notes: event.notes,
      );
      // Success is handled by the stream update
    } catch (e) {
      emit(DryingEntryError(e.toString()));
    }
  }

  Future<void> _onAddEntry(
      AddEntry event, Emitter<DryingEntryState> emit) async {
    try {
      // Add entry with 10 second timeout
      await _entryService.addEntry(event.entry).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Operation timed out. Please check your connection.');
        },
      );
      event.completer?.complete(true);
    } catch (e) {
      event.completer?.complete(false);
      emit(DryingEntryError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _entrySubscription?.cancel();
    return super.close();
  }
}
