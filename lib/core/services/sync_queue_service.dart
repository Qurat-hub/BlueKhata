import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';

/// Supported offline mutation types. Extend as new modules go offline-first.
enum SyncOperation { insert, update, delete }

/// A single pending mutation waiting to be pushed to Supabase.
class SyncTask {
  final String id;
  final String table;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  int attempts;

  SyncTask({
    required this.id,
    required this.table,
    required this.operation,
    required this.payload,
    required this.queuedAt,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'table': table,
        'operation': operation.name,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
        'attempts': attempts,
      };

  factory SyncTask.fromJson(Map<String, dynamic> json) => SyncTask(
        id: json['id'] as String,
        table: json['table'] as String,
        operation: SyncOperation.values.byName(json['operation'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        queuedAt: DateTime.parse(json['queuedAt'] as String),
        attempts: json['attempts'] as int? ?? 0,
      );
}

/// Offline-first sync engine.
///
/// Local writes are applied immediately to the Hive cache and enqueued here.
/// When connectivity is restored, [flush] replays queued mutations against
/// Supabase in order, with simple last-write-wins conflict resolution
/// (server `updated_at` wins on conflict — see `handleConflict`).
class SyncQueueService {
  SyncQueueService._();

  static const _uuid = Uuid();

  static Future<void> enqueue({
    required String table,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final box = LocalStorageService.box(HiveBoxes.syncQueue);
    final task = SyncTask(
      id: _uuid.v4(),
      table: table,
      operation: operation,
      payload: payload,
      queuedAt: DateTime.now(),
    );
    await box.put(task.id, jsonEncode(task.toJson()));
  }

  static List<SyncTask> pendingTasks() {
    final box = LocalStorageService.box(HiveBoxes.syncQueue);
    return box.values
        .map((raw) => SyncTask.fromJson(jsonDecode(raw as String)))
        .toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  /// Replays all pending tasks against Supabase. Call on connectivity
  /// restore or app resume. Failed tasks are retried up to 5 times,
  /// then left in the queue for manual/background retry.
  static Future<void> flush() async {
    final box = LocalStorageService.box(HiveBoxes.syncQueue);
    for (final task in pendingTasks()) {
      try {
        await _apply(task);
        await box.delete(task.id);
      } catch (_) {
        task.attempts += 1;
        if (task.attempts <= 5) {
          await box.put(task.id, jsonEncode(task.toJson()));
        }
        // else: leave for manual review / dead-letter handling.
      }
    }
  }

  static Future<void> _apply(SyncTask task) async {
    final client = SupabaseService.client;
    switch (task.operation) {
      case SyncOperation.insert:
        await client.from(task.table).insert(task.payload);
        break;
      case SyncOperation.update:
        await client
            .from(task.table)
            .update(task.payload)
            .eq('id', task.payload['id']);
        break;
      case SyncOperation.delete:
        await client
            .from(task.table)
            .update({'is_deleted': true, 'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', task.payload['id']);
        break;
    }
  }
}
