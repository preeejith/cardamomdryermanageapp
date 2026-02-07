import 'package:flutter/material.dart';
import '../models/drying_entry_model.dart';
import '../services/drying_entry_service.dart';

class DryingEntryProvider with ChangeNotifier {
  final DryingEntryService _entryService = DryingEntryService();
  
  List<DryingEntry> _entries = [];
  DryingEntry? _selectedEntry;
  bool _isLoading = false;
  String? _errorMessage;

  List<DryingEntry> get entries => _entries;
  DryingEntry? get selectedEntry => _selectedEntry;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToEntries(String ownerId) {
    _entryService.getEntriesStream(ownerId).listen(
      (entries) {
        _entries = entries;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  void listenToCustomerEntries(String customerId) {
    _entryService.getCustomerEntriesStream(customerId).listen(
      (entries) {
        _entries = entries;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> loadEntry(String entryId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedEntry = await _entryService.getEntry(entryId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEntry(DryingEntry entry) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _entryService.addEntry(entry);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEntryAfterDrying({
    required String entryId,
    required double driedWeightKg,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _entryService.updateEntryAfterDrying(
        entryId: entryId,
        driedWeightKg: driedWeightKg,
        notes: notes,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEntry(String entryId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _entryService.updateEntry(entryId, data);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEntry(String entryId, String customerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _entryService.deleteEntry(entryId, customerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DryingEntry>> getPendingEntries(String ownerId) async {
    try {
      return await _entryService.getPendingEntries(ownerId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void setSelectedEntry(DryingEntry? entry) {
    _selectedEntry = entry;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<DryingEntry> getEntriesByCustomer(String customerId) {
    return _entries.where((e) => e.customerId == customerId).toList();
  }

  List<DryingEntry> getPendingEntriesForCustomer(String customerId) {
    return _entries
        .where((e) => e.customerId == customerId && e.status == 'received')
        .toList();
  }
}
