import 'package:flutter/foundation.dart';

/// What the D3 Settings sync-status card (and anything else that cares)
/// shows for the current shop. Deliberately a closed set rather than a
/// loading-bool + error-string pair, so the UI can never render an
/// inconsistent combination (e.g. "syncing" and "error" at once).
@immutable
sealed class SyncStatus {
  const SyncStatus();
}

/// Nothing has run yet this session.
class SyncIdle extends SyncStatus {
  const SyncIdle();
}

class SyncInProgress extends SyncStatus {
  const SyncInProgress();
}

class SyncSuccess extends SyncStatus {
  const SyncSuccess(this.lastSyncedAt);
  final DateTime lastSyncedAt;
}

/// Device has no connectivity — not an error, just a state to show plainly
/// (NFR §10.4: billing/khata keep working regardless).
class SyncOffline extends SyncStatus {
  const SyncOffline();
}

/// A sync attempt failed (permission-denied, Firestore unavailable, etc.).
/// [lastSyncedAt] carries forward the previous success, if any, so the UI
/// can show "last synced 2h ago — retry failed" instead of losing that fact.
class SyncError extends SyncStatus {
  const SyncError(this.message, {this.lastSyncedAt});
  final String message;
  final DateTime? lastSyncedAt;
}
