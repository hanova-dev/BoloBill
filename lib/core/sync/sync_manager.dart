import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/firestore_sync_service.dart';
import '../../domain/entities/shop.dart';
import '../di/providers.dart';
import 'sync_status.dart';

/// Orchestrates when [FirestoreSyncService] runs and surfaces the result as
/// [SyncStatus] for D3 Settings. Triggers: a shop becoming available (app
/// start / onboarding completion), a connectivity transition into "online",
/// and the manual "Sync Now" button (all three funnel through [syncNow]).
///
/// A sync attempt must never throw into a caller and must never block or
/// slow down billing/khata — those write straight to the local encrypted DB
/// regardless of sync state (NFR §10.4, "zero degradation offline"). Every
/// failure here is swallowed and turned into [SyncError] state instead.
class SyncManager extends StateNotifier<SyncStatus> {
  SyncManager(this._ref, this._syncService, this._connectivity) : super(const SyncIdle()) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _shopSub = _ref.listen<Shop?>(currentShopProvider, (previous, next) {
      if (previous == null && next != null) syncNow();
    });
    if (_ref.read(currentShopProvider) != null) {
      syncNow();
    }
  }

  final Ref _ref;
  final FirestoreSyncService _syncService;
  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  late final ProviderSubscription<Shop?> _shopSub;
  DateTime? _lastSyncedAt;
  bool _syncing = false;

  /// Observed on-device: a Firestore write against a project whose Firestore
  /// API isn't enabled doesn't reject quickly — the native SDK's write
  /// stream retries internally and the awaited `Future` never settles,
  /// which without a bound left the UI stuck on "Syncing…" forever. A
  /// bounded wait turns that into a normal, retryable [SyncError] instead.
  static const Duration _syncTimeout = Duration(seconds: 20);

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_isOnline(results)) {
      syncNow();
    } else {
      state = const SyncOffline();
    }
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  Future<void> syncNow() async {
    if (_syncing) return;
    final shop = _ref.read(currentShopProvider);
    if (shop == null) return;

    if (!_isOnline(await _connectivity.checkConnectivity())) {
      state = const SyncOffline();
      return;
    }

    _syncing = true;
    state = const SyncInProgress();
    try {
      await _runSync(shop.shopId).timeout(_syncTimeout);
      _lastSyncedAt = DateTime.now();
      state = SyncSuccess(_lastSyncedAt!);
    } on TimeoutException {
      state = SyncError('Sync timed out', lastSyncedAt: _lastSyncedAt);
    } catch (e) {
      state = SyncError(e.toString(), lastSyncedAt: _lastSyncedAt);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _runSync(String shopId) async {
    await _syncService.push(shopId);
    await _syncService.pull(shopId);
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _shopSub.close();
    super.dispose();
  }
}
