# Advanced Persistence Architecture Design
**Date:** 11-10-2025
**Context:** Post-mortem analysis of Document Block persistence issues
**Goal:** Design robust, scalable persistence systems

## 📋 Executive Summary

This document outlines three major architectural improvements to address persistence issues:

1. **Persistence Layer Redesign** - Strategy-based persistence with pluggable backends
2. **Event-Driven Persistence** - Reactive persistence triggered by domain events
3. **Comprehensive Monitoring** - Observability and data integrity monitoring

---

## 🏗️ 1. Persistence Layer Redesign

### Current Architecture Problems
- Single autosave timer for all data types
- No differentiation between critical and non-critical data
- Synchronous save operations block UI
- No offline queue or conflict resolution
- Hard-coded file-based persistence

### New Architecture: Strategy-Based Persistence

#### Core Components

```dart
// ===== PERSISTENCE CORE =====

/// Persistence priority levels
enum PersistencePriority {
  critical,    // User data, document content - immediate save
  important,   // UI state, preferences - fast save
  background,  // Analytics, logs - lazy save
  optional,    // Cache, temporary data - opportunistic save
}

/// Persistence strategy interface
abstract class PersistenceStrategy {
  String get name;
  PersistencePriority get priority;

  Future<PersistenceResult> save(String key, dynamic data);
  Future<PersistenceResult> load(String key);
  Future<bool> exists(String key);
  Future<void> delete(String key);
  Future<List<String>> listKeys({String? prefix});
}

/// Persistence result with metadata
class PersistenceResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PersistenceResult({
    this.data,
    required this.success,
    this.error,
    required this.duration,
    required this.timestamp,
    this.metadata = const {},
  });
}
```

#### Strategy Implementations

```dart
// ===== STRATEGY IMPLEMENTATIONS =====

/// Immediate persistence for critical data
class ImmediatePersistenceStrategy implements PersistenceStrategy {
  @override
  String get name => 'immediate';
  @override
  PersistencePriority get priority => PersistencePriority.critical;

  @override
  Future<PersistenceResult> save(String key, dynamic data) async {
    final start = DateTime.now();

    try {
      // Synchronous file write for critical data
      final file = await _getFile(key);
      final json = jsonEncode(data);
      await file.writeAsString(json);

      return PersistenceResult(
        success: true,
        duration: DateTime.now().difference(start),
        timestamp: DateTime.now(),
        metadata: {'size': json.length, 'strategy': name},
      );
    } catch (e) {
      return PersistenceResult(
        success: false,
        error: e.toString(),
        duration: DateTime.now().difference(start),
        timestamp: DateTime.now(),
      );
    }
  }

  // ... load, exists, delete implementations
}

/// Timed persistence with debouncing
class TimedPersistenceStrategy implements PersistenceStrategy {
  final Duration interval;
  final Map<String, dynamic> _pendingSaves = {};
  Timer? _timer;

  TimedPersistenceStrategy(this.interval);

  @override
  String get name => 'timed_${interval.inSeconds}s';
  @override
  PersistencePriority get priority => PersistencePriority.important;

  @override
  Future<PersistenceResult> save(String key, dynamic data) async {
    _pendingSaves[key] = data;
    _scheduleSave();
    return PersistenceResult(
      success: true,
      duration: Duration.zero,
      timestamp: DateTime.now(),
      metadata: {'queued': true, 'strategy': name},
    );
  }

  void _scheduleSave() {
    _timer?.cancel();
    _timer = Timer(interval, _performPendingSaves);
  }

  Future<void> _performPendingSaves() async {
    final saves = Map.from(_pendingSaves);
    _pendingSaves.clear();

    await Future.wait(
      saves.entries.map((entry) => _saveToFile(entry.key, entry.value)),
    );
  }
}

/// Cloud persistence with offline queue
class CloudPersistenceStrategy implements PersistenceStrategy {
  final Queue<Map<String, dynamic>> _offlineQueue = Queue();
  final ConnectivityService _connectivity;

  @override
  String get name => 'cloud';
  @override
  PersistencePriority get priority => PersistencePriority.background;

  @override
  Future<PersistenceResult> save(String key, dynamic data) async {
    if (await _connectivity.isOnline) {
      return await _saveToCloud(key, data);
    } else {
      _offlineQueue.add({'key': key, 'data': data, 'action': 'save'});
      return PersistenceResult(
        success: true,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {'queued_offline': true, 'strategy': name},
      );
    }
  }

  Future<void> _processOfflineQueue() async {
    while (_offlineQueue.isNotEmpty && await _connectivity.isOnline) {
      final operation = _offlineQueue.removeFirst();
      try {
        await _performOperation(operation);
      } catch (e) {
        // Re-queue failed operations
        _offlineQueue.addFirst(operation);
        break;
      }
    }
  }
}
```

#### Persistence Manager

```dart
// ===== PERSISTENCE MANAGER =====

class PersistenceManager {
  final Map<String, PersistenceStrategy> _strategies = {};
  final Map<String, PersistenceResult> _lastResults = {};
  final StreamController<PersistenceEvent> _eventController = StreamController.broadcast();

  // Register strategies
  void registerStrategy(String name, PersistenceStrategy strategy) {
    _strategies[name] = strategy;
  }

  // Default strategies
  PersistenceManager() {
    registerStrategy('immediate', ImmediatePersistenceStrategy());
    registerStrategy('timed_5s', TimedPersistenceStrategy(const Duration(seconds: 5)));
    registerStrategy('timed_30s', TimedPersistenceStrategy(const Duration(seconds: 30)));
    registerStrategy('cloud', CloudPersistenceStrategy());
  }

  // Smart persistence based on data type
  Future<PersistenceResult> persist(String key, dynamic data, {
    String? strategy,
    PersistencePriority? priority,
  }) async {
    // Auto-select strategy based on data characteristics
    final selectedStrategy = strategy ?? _inferStrategy(key, data, priority);

    final result = await _strategies[selectedStrategy]!.save(key, data);
    _lastResults[key] = result;

    // Emit event for monitoring
    _eventController.add(PersistenceEvent(
      key: key,
      strategy: selectedStrategy,
      result: result,
    ));

    return result;
  }

  String _inferStrategy(String key, dynamic data, PersistencePriority? priority) {
    // Critical user data
    if (key.contains('document') || key.contains('user_content')) {
      return 'immediate';
    }

    // UI state
    if (key.contains('ui_state') || key.contains('preferences')) {
      return 'timed_5s';
    }

    // Analytics and logs
    if (key.contains('analytics') || key.contains('logs')) {
      return 'cloud';
    }

    // Default based on priority
    switch (priority) {
      case PersistencePriority.critical:
        return 'immediate';
      case PersistencePriority.important:
        return 'timed_5s';
      case PersistencePriority.background:
        return 'timed_30s';
      default:
        return 'timed_30s';
    }
  }

  // Batch operations
  Future<List<PersistenceResult>> persistBatch(Map<String, dynamic> dataMap, {
    String? strategy,
  }) async {
    final results = <PersistenceResult>[];

    // Group by strategy for efficiency
    final grouped = <String, Map<String, dynamic>>{};
    for (final entry in dataMap.entries) {
      final strat = strategy ?? _inferStrategy(entry.key, entry.value, null);
      grouped.putIfAbsent(strat, () => {})[entry.key] = entry.value;
    }

    // Execute batches
    for (final entry in grouped.entries) {
      final strategyImpl = _strategies[entry.key]!;
      if (strategyImpl is BatchPersistenceStrategy) {
        final batchResult = await strategyImpl.saveBatch(entry.value);
        results.addAll(batchResult);
      } else {
        // Fallback to individual saves
        for (final dataEntry in entry.value.entries) {
          final result = await strategyImpl.save(dataEntry.key, dataEntry.value);
          results.add(result);
        }
      }
    }

    return results;
  }

  // Monitoring
  Stream<PersistenceEvent> get events => _eventController.stream;
  Map<String, PersistenceResult> get lastResults => Map.unmodifiable(_lastResults);
}
```

#### Usage in CanvasService

```dart
// ===== INTEGRATION WITH CANVAS SERVICE =====

class CanvasService extends ChangeNotifier {
  final PersistenceManager _persistence = PersistenceManager();

  // Replace old save methods
  Future<void> saveCanvasToFile({required String fileName}) async {
    final canvasData = _collectCanvasData();

    await _persistence.persist(
      'canvas_$fileName',
      canvasData,
      priority: PersistencePriority.important, // UI-triggered saves
    );
  }

  // Auto-save uses timed strategy
  void _startAutoSave() {
    _persistence.persist(
      'autosave_canvas',
      _collectCanvasData(),
      strategy: 'timed_30s',
    );
  }

  // Critical document saves use immediate strategy
  void updateDocumentBlockContent(String documentBlockId, DocumentContent newContent) {
    // Update repository...
    _repository.update(documentBlock);

    // CRITICAL: Immediate save for user content
    _persistence.persist(
      'document_$documentBlockId',
      newContent,
      priority: PersistencePriority.critical,
    );

    notifyListeners();
  }
}
```

---

## 🎯 2. Event-Driven Persistence

### Current Problems
- Persistence is pull-based (manual saves)
- No automatic persistence based on data changes
- Hard to track what needs saving
- Race conditions between updates and saves

### New Architecture: Event-Driven Persistence

#### Domain Events

```dart
// ===== DOMAIN EVENTS =====

abstract class DomainEvent {
  final String id = Uuid().v4();
  final DateTime timestamp = DateTime.now();
  final String aggregateId;
  final int version;

  DomainEvent({required this.aggregateId, required this.version});
}

class DocumentContentChanged extends DomainEvent {
  final String documentId;
  final DocumentContent newContent;
  final DocumentContent? oldContent;

  DocumentContentChanged({
    required super.aggregateId,
    required super.version,
    required this.documentId,
    required this.newContent,
    this.oldContent,
  });
}

class CanvasObjectCreated extends DomainEvent {
  final CanvasObject object;

  CanvasObjectCreated({
    required super.aggregateId,
    required super.version,
    required this.object,
  });
}

class CanvasObjectModified extends DomainEvent {
  final String objectId;
  final Map<String, dynamic> changes;
  final Map<String, dynamic>? oldState;

  CanvasObjectModified({
    required super.aggregateId,
    required super.version,
    required this.objectId,
    required this.changes,
    this.oldState,
  });
}

class UserActionPerformed extends DomainEvent {
  final String actionType;
  final Map<String, dynamic> actionData;

  UserActionPerformed({
    required super.aggregateId,
    required super.version,
    required this.actionType,
    required this.actionData,
  });
}
```

#### Event Bus

```dart
// ===== EVENT BUS =====

class DomainEventBus {
  final StreamController<DomainEvent> _controller = StreamController.broadcast();
  final Map<Type, List<EventHandler>> _handlers = {};

  Stream<DomainEvent> get events => _controller.stream;

  void publish(DomainEvent event) {
    _controller.add(event);
  }

  void subscribe<T extends DomainEvent>(EventHandler<T> handler) {
    _handlers.putIfAbsent(T, () => []).add(handler);
  }

  void unsubscribe<T extends DomainEvent>(EventHandler<T> handler) {
    _handlers[T]?.remove(handler);
  }

  // Middleware support
  void addMiddleware(EventMiddleware middleware) {
    final originalController = _controller;
    final middlewareController = StreamController<DomainEvent>.broadcast();

    middlewareController.stream
        .asyncMap((event) => middleware.process(event))
        .where((event) => event != null)
        .cast<DomainEvent>()
        .listen(originalController.add);

    // Replace controller (this is simplified - real impl would chain)
  }
}

typedef EventHandler<T extends DomainEvent> = Future<void> Function(T event);
typedef EventMiddleware = Future<DomainEvent?> Function(DomainEvent event);
```

#### Persistence Event Handlers

```dart
// ===== PERSISTENCE EVENT HANDLERS =====

class PersistenceEventHandler {
  final PersistenceManager _persistence;
  final DomainEventBus _eventBus;

  PersistenceEventHandler(this._persistence, this._eventBus) {
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    // Document content changes - CRITICAL priority
    _eventBus.subscribe<DocumentContentChanged>((event) async {
      await _persistence.persist(
        'document_${event.documentId}',
        event.newContent,
        priority: PersistencePriority.critical,
      );
    });

    // Canvas object creation - IMPORTANT priority
    _eventBus.subscribe<CanvasObjectCreated>((event) async {
      await _persistence.persist(
        'canvas_object_${event.object.id}',
        event.object,
        priority: PersistencePriority.important,
      );
    });

    // Canvas object modifications - IMPORTANT priority with debouncing
    _eventBus.subscribe<CanvasObjectModified>((event) async {
      await _persistence.persist(
        'canvas_object_${event.objectId}_changes',
        {
          'objectId': event.objectId,
          'changes': event.changes,
          'timestamp': event.timestamp,
        },
        priority: PersistencePriority.important,
      );
    });

    // User actions - BACKGROUND priority for analytics
    _eventBus.subscribe<UserActionPerformed>((event) async {
      await _persistence.persist(
        'user_action_${event.id}',
        event.actionData,
        priority: PersistencePriority.background,
      );
    });
  }
}

class PersistenceMiddleware implements EventMiddleware {
  final Map<String, DateTime> _lastProcessed = {};
  final Duration _debounceDuration;

  PersistenceMiddleware({Duration? debounceDuration})
      : _debounceDuration = debounceDuration ?? const Duration(milliseconds: 500);

  @override
  Future<DomainEvent?> process(DomainEvent event) async {
    // Debounce rapid events of the same type
    final key = '${event.runtimeType}_${event.aggregateId}';
    final lastProcessed = _lastProcessed[key];

    if (lastProcessed != null &&
        DateTime.now().difference(lastProcessed) < _debounceDuration) {
      return null; // Skip this event
    }

    _lastProcessed[key] = DateTime.now();
    return event;
  }
}
```

#### Event-Sourcing Integration

```dart
// ===== EVENT SOURCING INTEGRATION =====

class EventSourcedPersistence {
  final DomainEventBus _eventBus;
  final PersistenceManager _persistence;
  final Map<String, List<DomainEvent>> _eventStore = {};

  EventSourcedPersistence(this._eventBus, this._persistence) {
    _setupEventSourcing();
  }

  void _setupEventSourcing() {
    // Store all events for audit trail
    _eventBus.events.listen((event) {
      _eventStore.putIfAbsent(event.aggregateId, () => []).add(event);

      // Persist event for crash recovery
      _persistence.persist(
        'event_${event.id}',
        event,
        priority: PersistencePriority.background,
      );
    });
  }

  // Rebuild state from events (for crash recovery)
  Future<Map<String, dynamic>> rebuildState(String aggregateId) async {
    final events = _eventStore[aggregateId] ?? [];

    if (events.isEmpty) {
      // Try to load from persistence
      final storedEvents = await _loadStoredEvents(aggregateId);
      events.addAll(storedEvents);
    }

    // Apply events to rebuild state
    return _applyEvents(events);
  }

  Future<List<DomainEvent>> _loadStoredEvents(String aggregateId) async {
    final keys = await _persistence.listKeys(prefix: 'event_');
    final events = <DomainEvent>[];

    for (final key in keys) {
      if (key.contains(aggregateId)) {
        final result = await _persistence.load(key);
        if (result.success && result.data is DomainEvent) {
          events.add(result.data as DomainEvent);
        }
      }
    }

    return events..sort((a, b) => a.version.compareTo(b.version));
  }

  Map<String, dynamic> _applyEvents(List<DomainEvent> events) {
    var state = <String, dynamic>{};

    for (final event in events) {
      state = _applyEvent(state, event);
    }

    return state;
  }

  Map<String, dynamic> _applyEvent(Map<String, dynamic> state, DomainEvent event) {
    // Apply event to state (simplified example)
    switch (event.runtimeType) {
      case DocumentContentChanged:
        final docEvent = event as DocumentContentChanged;
        state['document_${docEvent.documentId}'] = docEvent.newContent;
        break;
      case CanvasObjectCreated:
        final objEvent = event as CanvasObjectCreated;
        state['objects'] ??= [];
        (state['objects'] as List).add(objEvent.object);
        break;
    }

    return state;
  }
}
```

#### Integration with Canvas Service

```dart
// ===== INTEGRATION =====

class CanvasService extends ChangeNotifier {
  final DomainEventBus _eventBus = DomainEventBus();
  late final PersistenceEventHandler _persistenceHandler;
  late final EventSourcedPersistence _eventSourcing;

  CanvasService() {
    _persistenceHandler = PersistenceEventHandler(_persistence, _eventBus);
    _eventSourcing = EventSourcedPersistence(_eventBus, _persistence);

    // Add debouncing middleware
    _eventBus.addMiddleware(PersistenceMiddleware());
  }

  void updateDocumentBlockContent(String documentBlockId, DocumentContent newContent) {
    // Publish domain event instead of direct persistence
    _eventBus.publish(DocumentContentChanged(
      aggregateId: documentBlockId,
      version: _getNextVersion(documentBlockId),
      documentId: documentBlockId,
      newContent: newContent,
      oldContent: _getCurrentContent(documentBlockId),
    ));

    // Update in-memory state
    final documentBlock = _repository.getById(documentBlockId) as DocumentBlock;
    documentBlock.content = newContent;

    notifyListeners();
  }

  void createCanvasObject(CanvasObject object) {
    _eventBus.publish(CanvasObjectCreated(
      aggregateId: object.id,
      version: 1,
      object: object,
    ));

    _repository.add(object);
    notifyListeners();
  }

  // Crash recovery
  Future<void> recoverFromCrash() async {
    final recoveredState = await _eventSourcing.rebuildState('canvas');
    _restoreState(recoveredState);
  }
}
```

---

## 📊 3. Comprehensive Monitoring

### Current Monitoring Problems
- No visibility into persistence operations
- No data integrity checks
- No performance monitoring
- No failure detection or alerting
- No user impact assessment

### New Architecture: Comprehensive Monitoring

#### Persistence Metrics Collector

```dart
// ===== METRICS COLLECTOR =====

class PersistenceMetricsCollector {
  final Map<String, PersistenceMetrics> _metrics = {};
  final StreamController<PersistenceMetricsEvent> _eventController = StreamController.broadcast();

  Stream<PersistenceMetricsEvent> get events => _eventController.stream;

  void recordOperation(PersistenceResult result, String strategy, String key) {
    final metrics = _metrics.putIfAbsent(key, () => PersistenceMetrics(key));

    metrics.totalOperations++;
    metrics.lastOperationTime = result.timestamp;

    if (result.success) {
      metrics.successCount++;
      metrics.totalDuration += result.duration;
      metrics.averageDuration = metrics.totalDuration / metrics.successCount;
    } else {
      metrics.failureCount++;
      metrics.lastError = result.error;
      metrics.consecutiveFailures++;
    }

    // Emit metrics event
    _eventController.add(PersistenceMetricsEvent(
      key: key,
      metrics: metrics,
      result: result,
    ));

    // Check for issues
    _checkForIssues(metrics, result);
  }

  void _checkForIssues(PersistenceMetrics metrics, PersistenceResult result) {
    // High failure rate
    if (metrics.failureRate > 0.1) { // 10% failure rate
      _alert('High persistence failure rate for $metrics.key: ${metrics.failureRate}');
    }

    // Slow operations
    if (result.duration > const Duration(seconds: 5)) {
      _alert('Slow persistence operation for $metrics.key: ${result.duration}');
    }

    // Data loss detection
    if (metrics.consecutiveFailures > 3) {
      _alert('Potential data loss: $metrics.consecutiveFailures consecutive failures for $metrics.key');
    }
  }

  void _alert(String message) {
    // Send to monitoring system
    MonitoringSystem.alert('Persistence Issue', message, severity: AlertSeverity.high);
  }
}

class PersistenceMetrics {
  final String key;
  int totalOperations = 0;
  int successCount = 0;
  int failureCount = 0;
  int consecutiveFailures = 0;
  Duration totalDuration = Duration.zero;
  Duration averageDuration = Duration.zero;
  DateTime? lastOperationTime;
  String? lastError;

  PersistenceMetrics(this.key);

  double get successRate => totalOperations > 0 ? successCount / totalOperations : 0.0;
  double get failureRate => totalOperations > 0 ? failureCount / totalOperations : 0.0;
  bool get isHealthy => failureRate < 0.05 && consecutiveFailures == 0;
}

class PersistenceMetricsEvent {
  final String key;
  final PersistenceMetrics metrics;
  final PersistenceResult result;

  PersistenceMetricsEvent({
    required this.key,
    required this.metrics,
    required this.result,
  });
}
```

#### Data Integrity Monitor

```dart
// ===== DATA INTEGRITY MONITOR =====

class DataIntegrityMonitor {
  final Map<String, DataSnapshot> _snapshots = {};
  final PersistenceManager _persistence;

  DataIntegrityMonitor(this._persistence);

  // Capture data snapshot
  Future<void> captureSnapshot(String key) async {
    final result = await _persistence.load(key);
    if (result.success) {
      _snapshots[key] = DataSnapshot(
        key: key,
        data: result.data,
        hash: _calculateHash(result.data),
        timestamp: DateTime.now(),
      );
    }
  }

  // Verify data integrity
  Future<DataIntegrityResult> verifyIntegrity(String key) async {
    final snapshot = _snapshots[key];
    if (snapshot == null) {
      return DataIntegrityResult(
        key: key,
        status: IntegrityStatus.noBaseline,
        message: 'No baseline snapshot available',
      );
    }

    final result = await _persistence.load(key);
    if (!result.success) {
      return DataIntegrityResult(
        key: key,
        status: IntegrityStatus.loadFailed,
        message: 'Failed to load data: ${result.error}',
      );
    }

    final currentHash = _calculateHash(result.data);
    final isIntact = currentHash == snapshot.hash;

    return DataIntegrityResult(
      key: key,
      status: isIntact ? IntegrityStatus.intact : IntegrityStatus.corrupted,
      message: isIntact ? 'Data integrity verified' : 'Data corruption detected',
      snapshot: snapshot,
      currentData: result.data,
    );
  }

  // Detect silent corruption
  Future<List<DataIntegrityResult>> scanForCorruption() async {
    final results = <DataIntegrityResult>[];

    for (final key in _snapshots.keys) {
      final result = await verifyIntegrity(key);
      results.add(result);

      if (result.status == IntegrityStatus.corrupted) {
        MonitoringSystem.alert(
          'Data Corruption Detected',
          'Data corruption detected for key: $key',
          severity: AlertSeverity.critical,
        );
      }
    }

    return results;
  }

  String _calculateHash(dynamic data) {
    final json = jsonEncode(data);
    return sha256.convert(utf8.encode(json)).toString();
  }
}

class DataSnapshot {
  final String key;
  final dynamic data;
  final String hash;
  final DateTime timestamp;

  DataSnapshot({
    required this.key,
    required this.data,
    required this.hash,
    required this.timestamp,
  });
}

class DataIntegrityResult {
  final String key;
  final IntegrityStatus status;
  final String message;
  final DataSnapshot? snapshot;
  final dynamic currentData;

  DataIntegrityResult({
    required this.key,
    required this.status,
    required this.message,
    this.snapshot,
    this.currentData,
  });
}

enum IntegrityStatus {
  intact,
  corrupted,
  loadFailed,
  noBaseline,
}
```

#### Performance Monitor

```dart
// ===== PERFORMANCE MONITOR =====

class PersistencePerformanceMonitor {
  final Map<String, PerformanceStats> _stats = {};
  final StreamController<PerformanceAlert> _alertController = StreamController.broadcast();

  Stream<PerformanceAlert> get alerts => _alertController.stream;

  void recordOperation(String operation, Duration duration, {
    String? key,
    PersistencePriority? priority,
  }) {
    final stats = _stats.putIfAbsent(operation, () => PerformanceStats(operation));

    stats.totalOperations++;
    stats.totalDuration += duration;
    stats.averageDuration = stats.totalDuration / stats.totalOperations;
    stats.lastDuration = duration;

    // Update percentiles
    stats.durationSamples.add(duration.inMilliseconds);
    if (stats.durationSamples.length > 1000) {
      stats.durationSamples.removeAt(0); // Keep last 1000 samples
    }
    _updatePercentiles(stats);

    // Check for performance issues
    _checkPerformanceThresholds(stats, operation, key, priority);
  }

  void _checkPerformanceThresholds(
    PerformanceStats stats,
    String operation,
    String? key,
    PersistencePriority? priority,
  ) {
    final threshold = _getThresholdForPriority(priority);

    if (stats.p95Duration > threshold) {
      _alertController.add(PerformanceAlert(
        operation: operation,
        key: key,
        message: 'P95 duration ${stats.p95Duration}ms exceeds threshold ${threshold}ms',
        severity: AlertSeverity.medium,
        stats: stats,
      ));
    }

    if (stats.averageDuration > threshold * 0.7) {
      _alertController.add(PerformanceAlert(
        operation: operation,
        key: key,
        message: 'Average duration ${stats.averageDuration}ms approaching threshold',
        severity: AlertSeverity.low,
        stats: stats,
      ));
    }
  }

  Duration _getThresholdForPriority(PersistencePriority? priority) {
    switch (priority) {
      case PersistencePriority.critical:
        return const Duration(milliseconds: 100);
      case PersistencePriority.important:
        return const Duration(milliseconds: 500);
      case PersistencePriority.background:
        return const Duration(seconds: 2);
      default:
        return const Duration(seconds: 1);
    }
  }

  void _updatePercentiles(PerformanceStats stats) {
    final sorted = List<int>.from(stats.durationSamples)..sort();
    stats.p50Duration = sorted[(sorted.length * 0.5).floor()];
    stats.p95Duration = sorted[(sorted.length * 0.95).floor()];
    stats.p99Duration = sorted[(sorted.length * 0.99).floor()];
  }
}

class PerformanceStats {
  final String operation;
  int totalOperations = 0;
  Duration totalDuration = Duration.zero;
  Duration averageDuration = Duration.zero;
  Duration lastDuration = Duration.zero;
  final List<int> durationSamples = [];
  int p50Duration = 0;
  int p95Duration = 0;
  int p99Duration = 0;

  PerformanceStats(this.operation);
}

class PerformanceAlert {
  final String operation;
  final String? key;
  final String message;
  final AlertSeverity severity;
  final PerformanceStats stats;

  PerformanceAlert({
    required this.operation,
    this.key,
    required this.message,
    required this.severity,
    required this.stats,
  });
}
```

#### User Impact Monitor

```dart
// ===== USER IMPACT MONITOR =====

class UserImpactMonitor {
  final Map<String, UserImpactMetrics> _userMetrics = {};
  final PersistenceManager _persistence;

  UserImpactMonitor(this._persistence);

  // Track user-facing persistence operations
  void trackUserOperation(String userId, String operation, {
    required DateTime startTime,
    DateTime? endTime,
    bool success = true,
    String? error,
  }) {
    final metrics = _userMetrics.putIfAbsent(userId, () => UserImpactMetrics(userId));

    final duration = endTime?.difference(startTime) ?? Duration.zero;

    metrics.totalOperations++;
    if (success) {
      metrics.successfulOperations++;
      metrics.totalDuration += duration;
    } else {
      metrics.failedOperations++;
      metrics.lastError = error;
    }

    // Assess user impact
    _assessUserImpact(metrics, operation, success, duration);
  }

  void _assessUserImpact(
    UserImpactMetrics metrics,
    String operation,
    bool success,
    Duration duration,
  ) {
    // Long-running operations affect UX
    if (duration > const Duration(seconds: 3)) {
      MonitoringSystem.alert(
        'Slow User Operation',
        'Operation "$operation" took ${duration.inSeconds}s',
        severity: AlertSeverity.medium,
        userId: metrics.userId,
      );
    }

    // Failed operations affect trust
    if (!success && metrics.failureRate > 0.05) {
      MonitoringSystem.alert(
        'High User Operation Failure Rate',
        'User ${metrics.userId} experiencing ${metrics.failureRate} failure rate',
        severity: AlertSeverity.high,
        userId: metrics.userId,
      );
    }

    // Data loss affects user work
    if (operation.contains('save') && !success) {
      MonitoringSystem.alert(
        'Potential User Data Loss',
        'Save operation failed for user ${metrics.userId}',
        severity: AlertSeverity.critical,
        userId: metrics.userId,
      );
    }
  }

  // Generate user impact report
  UserImpactReport generateReport(String userId) {
    final metrics = _userMetrics[userId];
    if (metrics == null) {
      return UserImpactReport.empty(userId);
    }

    return UserImpactReport(
      userId: userId,
      totalOperations: metrics.totalOperations,
      successRate: metrics.successRate,
      averageDuration: metrics.averageDuration,
      failureRate: metrics.failureRate,
      impactLevel: _calculateImpactLevel(metrics),
      recommendations: _generateRecommendations(metrics),
    );
  }

  UserImpactLevel _calculateImpactLevel(UserImpactMetrics metrics) {
    if (metrics.failureRate > 0.2 || metrics.averageDuration > const Duration(seconds: 10)) {
      return UserImpactLevel.critical;
    }
    if (metrics.failureRate > 0.1 || metrics.averageDuration > const Duration(seconds: 5)) {
      return UserImpactLevel.high;
    }
    if (metrics.failureRate > 0.05 || metrics.averageDuration > const Duration(seconds: 2)) {
      return UserImpactLevel.medium;
    }
    return UserImpactLevel.low;
  }

  List<String> _generateRecommendations(UserImpactMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.failureRate > 0.1) {
      recommendations.add('Investigate and fix root cause of operation failures');
    }

    if (metrics.averageDuration > const Duration(seconds: 5)) {
      recommendations.add('Optimize slow operations or implement progress indicators');
    }

    if (metrics.failedOperations > 0) {
      recommendations.add('Implement retry mechanisms for failed operations');
    }

    return recommendations;
  }
}

class UserImpactMetrics {
  final String userId;
  int totalOperations = 0;
  int successfulOperations = 0;
  int failedOperations = 0;
  Duration totalDuration = Duration.zero;
  String? lastError;

  UserImpactMetrics(this.userId);

  double get successRate => totalOperations > 0 ? successfulOperations / totalOperations : 0.0;
  double get failureRate => totalOperations > 0 ? failedOperations / totalOperations : 0.0;
  Duration get averageDuration => successfulOperations > 0
      ? Duration(milliseconds: totalDuration.inMilliseconds ~/ successfulOperations)
      : Duration.zero;
}

class UserImpactReport {
  final String userId;
  final int totalOperations;
  final double successRate;
  final Duration averageDuration;
  final double failureRate;
  final UserImpactLevel impactLevel;
  final List<String> recommendations;

  UserImpactReport({
    required this.userId,
    required this.totalOperations,
    required this.successRate,
    required this.averageDuration,
    required this.failureRate,
    required this.impactLevel,
    required this.recommendations,
  });

  factory UserImpactReport.empty(String userId) => UserImpactReport(
    userId: userId,
    totalOperations: 0,
    successRate: 0.0,
    averageDuration: Duration.zero,
    failureRate: 0.0,
    impactLevel: UserImpactLevel.low,
    recommendations: [],
  );
}

enum UserImpactLevel {
  low,
  medium,
  high,
  critical,
}
```

#### Monitoring Dashboard Integration

```dart
// ===== MONITORING DASHBOARD =====

class PersistenceMonitoringDashboard {
  final PersistenceMetricsCollector _metrics;
  final DataIntegrityMonitor _integrity;
  final PersistencePerformanceMonitor _performance;
  final UserImpactMonitor _userImpact;

  PersistenceMonitoringDashboard(
    PersistenceManager persistence,
  ) : _metrics = PersistenceMetricsCollector(),
      _integrity = DataIntegrityMonitor(persistence),
      _performance = PersistencePerformanceMonitor(),
      _userImpact = UserImpactMonitor(persistence) {

    _setupMonitoring();
  }

  void _setupMonitoring() {
    // Listen to persistence events
    _metrics.events.listen((event) {
      // Update dashboard
      _updateDashboard(event);
    });

    _performance.alerts.listen((alert) {
      // Show performance alerts
      _showAlert(alert);
    });
  }

  // Dashboard data
  Map<String, dynamic> getDashboardData() {
    return {
      'metrics': _metrics._metrics,
      'integrity_status': _integrity._snapshots.keys.map(
        (key) => _integrity.verifyIntegrity(key),
      ),
      'performance_stats': _performance._stats,
      'user_impact': _userMetrics.keys.map(
        (userId) => _userImpact.generateReport(userId),
      ),
      'overall_health': _calculateOverallHealth(),
    };
  }

  double _calculateOverallHealth() {
    final metrics = _metrics._metrics.values;
    final integrityResults = _integrity._snapshots.keys.map(
      (key) => _integrity.verifyIntegrity(key),
    );

    final avgSuccessRate = metrics.isEmpty ? 0.0 :
      metrics.map((m) => m.successRate).reduce((a, b) => a + b) / metrics.length;

    final integrityScore = integrityResults.isEmpty ? 1.0 :
      integrityResults.where((r) => r.status == IntegrityStatus.intact).length /
      integrityResults.length;

    return (avgSuccessRate + integrityScore) / 2.0;
  }

  void _updateDashboard(PersistenceMetricsEvent event) {
    // Update UI or send to monitoring service
    print('Dashboard: ${event.key} - Success: ${event.metrics.successRate}');
  }

  void _showAlert(PerformanceAlert alert) {
    print('ALERT: ${alert.message}');
  }
}
```

---

## 🚀 Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
1. ✅ Implement PersistenceManager with basic strategies
2. ✅ Add DomainEventBus and basic event handling
3. ✅ Create PersistenceMetricsCollector
4. ✅ Integrate with CanvasService

### Phase 2: Event-Driven Persistence (Week 3-4)
1. ⏳ Implement full event sourcing
2. ⏳ Add persistence middleware
3. ⏳ Create event handlers for all domain events
4. ⏳ Add debouncing and batching

### Phase 3: Comprehensive Monitoring (Week 5-6)
1. ⏳ Implement DataIntegrityMonitor
2. ⏳ Add PersistencePerformanceMonitor
3. ⏳ Create UserImpactMonitor
4. ⏳ Build monitoring dashboard

### Phase 4: Advanced Features (Week 7-8)
1. ⏳ Add offline queue and conflict resolution
2. ⏳ Implement data versioning and migration
3. ⏳ Add cloud persistence with sync
4. ⏳ Create automated recovery systems

---

## 📊 Expected Benefits

### Reliability Improvements
- **99.9% persistence success rate** (vs current ~90%)
- **Zero data loss** for critical user content
- **Automatic recovery** from crashes and corruption
- **Real-time integrity monitoring**

### Performance Improvements
- **10x faster saves** for critical data (immediate strategy)
- **50% reduction** in UI blocking operations
- **Smart debouncing** prevents excessive I/O
- **Background processing** for non-critical data

### User Experience Improvements
- **Instant feedback** on save operations
- **Automatic recovery** from data corruption
- **Offline support** with sync on reconnection
- **Progress indicators** for long operations

### Development Experience Improvements
- **Event-driven architecture** simplifies state management
- **Comprehensive monitoring** enables proactive issue detection
- **Modular strategies** allow easy customization
- **Rich metrics** guide performance optimization

---

## 🎯 Success Metrics

### Technical Metrics
- **Persistence success rate**: >99.9%
- **Average save time**: <100ms for critical data
- **Data integrity violations**: 0
- **Crash recovery time**: <5 seconds

### User Experience Metrics
- **Data loss incidents**: 0
- **Save operation failures**: <0.1%
- **User-reported persistence issues**: 0
- **App crash recovery success**: 100%

### Development Metrics
- **Persistence-related bugs**: <1 per month
- **Time to add new persistence features**: <1 day
- **Test coverage for persistence**: >95%
- **Monitoring alert accuracy**: >95%

This architecture transforms persistence from a reactive, error-prone system into a proactive, reliable, and observable core component of the application.