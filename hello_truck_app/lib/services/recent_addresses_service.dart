import 'package:hive_flutter/hive_flutter.dart';
import 'package:hello_truck_app/models/saved_address.dart';

/// Manages a list of recently used addresses in local Hive storage.
///
/// Stores entries as JSON-like maps instead of Hive objects,
/// sorted by last used timestamp and capped to a maximum size.
class RecentAddressesService {
  static const _boxName = 'recent_addresses';
  static const _entriesKey = 'entries';
  static const _maxEntries = 20;

  bool _initialized = false;
  Box<dynamic>? _box;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    _initialized = true;
  }

  // ---------------------------- //
  // Public API
  // ---------------------------- //

  /// Returns the most recent unique addresses (sorted by timestamp descending).
  Future<List<SavedAddress>> getRecentAddresses({int limit = 5}) async {
    await _ensureInitialized();
    final entries = _readEntries();

    // Sort latest first
    entries.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    final seen = <String>{};
    final recents = <SavedAddress>[];

    for (final entry in entries) {
      final formatted = _normalize(((entry['address'] as Map?)?['formattedAddress'] ?? '').toString());
      if (formatted.isEmpty || !seen.add(formatted)) continue;

      recents.add(_fromStorageMap(entry));
      if (recents.length >= limit) break;
    }

    return recents;
  }

  /// Adds or updates a recent address and moves it to the top.
  Future<void> addRecent(SavedAddress address) async {
    await _ensureInitialized();
    final entries = _readEntries();

    final formatted = _normalize(address.address.formattedAddress);

    // Remove duplicates by formatted address
    entries.removeWhere((e) =>
        _normalize(((e['address'] as Map?)?['formattedAddress'] ?? '').toString()) == formatted);

    // Insert new entry with current timestamp
    final newEntry = _toStorageMap(address);
    entries.insert(0, newEntry);

    // Cap list length
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }

    await _writeEntries(entries);
  }

  /// Removes all stored addresses.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _writeEntries([]);
  }

  /// Deletes a specific entry by its formatted address (case-insensitive).
  Future<void> deleteByFormattedAddress(String formattedAddress) async {
    await _ensureInitialized();
    final entries = _readEntries();

    final normalizedKey = _normalize(formattedAddress);
    entries.removeWhere((e) =>
        _normalize(((e['address'] as Map?)?['formattedAddress'] ?? '').toString()) == normalizedKey);

    await _writeEntries(entries);
  }

  // ---------------------------- //
  // Internal Helpers
  // ---------------------------- //

  List<Map<String, dynamic>> _readEntries() {
    final raw = (_box!.get(_entriesKey) as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  Future<void> _writeEntries(List<Map<String, dynamic>> entries) async {
    await _box!.put(_entriesKey, entries);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  // ---------------------------- //
  // Serialization Helpers
  // ---------------------------- //

  Map<String, dynamic> _toStorageMap(SavedAddress address) {
    return {
      'id': address.id,
      'name': address.name,
      'address': address.address.toJson()
        ..addAll({'formattedAddress': address.address.formattedAddress}),
      'contactName': address.contactName,
      'contactPhone': address.contactPhone,
      'noteToDriver': address.noteToDriver,
      'isDefault': address.isDefault,
      'createdAt': address.createdAt.toIso8601String(),
      'updatedAt': address.updatedAt.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
      'isLocalRecent': true,
    };
  }

  SavedAddress _fromStorageMap(Map<String, dynamic> map) {
    final addrMap = Map<String, dynamic>.from(map['address'] ?? {});
    addrMap['formattedAddress'] ??= '';

    return SavedAddress(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      address: Address.fromJson(addrMap),
      contactName: (map['contactName'] ?? '').toString(),
      contactPhone: (map['contactPhone'] ?? '').toString(),
      noteToDriver: map['noteToDriver'] as String?,
      isDefault: map['isDefault'] == true,
      isLocalRecent: true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}