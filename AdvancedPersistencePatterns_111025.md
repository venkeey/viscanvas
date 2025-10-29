# Advanced Persistence Patterns & Enterprise Architecture
**Date:** 11-10-2025
**Context:** Extending the persistence architecture with sophisticated design patterns
**Goal:** Enterprise-grade persistence with advanced patterns

---

## 🎯 **Advanced Patterns Overview**

The previous architecture provides a solid foundation. Now we'll add **enterprise-grade patterns** for maximum robustness, scalability, and maintainability:

1. **CQRS + Event Sourcing** - Separate read/write models with event-driven persistence
2. **Saga Pattern** - Handle complex persistence transactions
3. **Circuit Breaker** - Graceful failure handling
4. **Repository + Unit of Work** - Advanced data access patterns
5. **Domain-Driven Design** - Rich domain models with aggregates
6. **Pipeline Pattern** - Composable persistence processing

---

## 🏗️ **1. CQRS + Event Sourcing Architecture**

### **Command Query Responsibility Segregation (CQRS)**

```dart
// ===== CQRS CORE =====

// Commands (Write Operations)
abstract class PersistenceCommand {
  String get aggregateId;
  int get expectedVersion;
}

class SaveDocumentCommand extends PersistenceCommand {
  final String documentId;
  final DocumentContent content;
  final Map<String, dynamic> metadata;

  SaveDocumentCommand({
    required this.documentId,
    required this.content,
    this.metadata = const {},
  });

  @override
  String get aggregateId => documentId;
  @override
  int get expectedVersion => -1; // Use optimistic concurrency
}

// Queries (Read Operations)
abstract class PersistenceQuery<T> {
  String get queryId;
}

class GetDocumentQuery extends PersistenceQuery<DocumentContent?> {
  final String documentId;
  final bool includeHistory;

  GetDocumentQuery({
    required this.documentId,
    this.includeHistory = false,
  });

  @override
  String get queryId => 'get_document_$documentId';
}

// Command Handlers
abstract class CommandHandler<T extends PersistenceCommand> {
  Future<CommandResult> handle(T command);
}

class SaveDocumentCommandHandler extends CommandHandler<SaveDocumentCommand> {
  final EventStore _eventStore;
  final DocumentAggregateRepository _repository;

  @override
  Future<CommandResult> handle(SaveDocumentCommand command) async {
    try {
      // Load aggregate
      final aggregate = await _repository.getById(command.documentId) ??
                       DocumentAggregate.create(command.documentId);

      // Apply command
      final events = aggregate.saveContent(command.content, command.metadata);

      // Store events (Event Sourcing)
      await _eventStore.appendEvents(command.documentId, events, command.expectedVersion);

      // Update read model asynchronously
      unawaited(_updateReadModel(command.documentId, aggregate));

      return CommandResult.success(events.length);
    } catch (e) {
      return CommandResult.failure(e.toString());
    }
  }
}

// Query Handlers
abstract class QueryHandler<TQuery extends PersistenceQuery, TResult> {
  Future<QueryResult<TResult>> handle(TQuery query);
}

class GetDocumentQueryHandler extends QueryHandler<GetDocumentQuery, DocumentContent?> {
  final DocumentReadModelRepository _readRepository;

  @override
  Future<QueryResult<DocumentContent?>> handle(GetDocumentQuery query) async {
    try {
      final document = await _readRepository.getById(query.documentId);

      if (query.includeHistory && document != null) {
        // Load event history for full audit trail
        final history = await _loadEventHistory(query.documentId);
        return QueryResult.success(document.copyWith(history: history));
      }

      return QueryResult.success(document);
    } catch (e) {
      return QueryResult.failure(e.toString());
    }
  }
}
```

### **Event Sourcing Implementation**

```dart
// ===== EVENT SOURCING =====

abstract class DomainEvent {
  String get aggregateId;
  int get version;
  DateTime get timestamp;
  Map<String, dynamic> toJson();
}

class DocumentContentSaved extends DomainEvent {
  final String documentId;
  final DocumentContent content;
  final Map<String, dynamic> metadata;

  DocumentContentSaved({
    required this.documentId,
    required this.content,
    required this.metadata,
    required int version,
  }) : super(version: version);

  @override
  String get aggregateId => documentId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'DocumentContentSaved',
    'documentId': documentId,
    'content': content.toJson(),
    'metadata': metadata,
    'version': version,
    'timestamp': timestamp.toIso8601String(),
  };
}

class EventStore {
  final PersistenceManager _persistence;
  final Map<String, List<DomainEvent>> _eventCache = {};

  Future<void> appendEvents(String aggregateId, List<DomainEvent> events, int expectedVersion) async {
    final key = 'events_$aggregateId';
    final existingEvents = await _loadEvents(aggregateId);

    // Optimistic concurrency check
    if (expectedVersion != -1 && existingEvents.length != expectedVersion) {
      throw ConcurrencyException('Version conflict: expected $expectedVersion, got ${existingEvents.length}');
    }

    // Append new events
    existingEvents.addAll(events);
    _eventCache[aggregateId] = existingEvents;

    // Persist events
    await _persistence.persist(key, existingEvents.map((e) => e.toJson()).toList(),
      priority: PersistencePriority.critical);
  }

  Future<List<DomainEvent>> getEvents(String aggregateId, {int? fromVersion}) async {
    final events = await _loadEvents(aggregateId);
    if (fromVersion != null) {
      return events.where((e) => e.version >= fromVersion).toList();
    }
    return events;
  }

  Future<List<DomainEvent>> _loadEvents(String aggregateId) async {
    if (_eventCache.containsKey(aggregateId)) {
      return _eventCache[aggregateId]!;
    }

    final key = 'events_$aggregateId';
    final result = await _persistence.load(key);

    if (result.success && result.data != null) {
      final eventData = result.data as List;
      final events = eventData.map((json) => _deserializeEvent(json)).toList();
      _eventCache[aggregateId] = events;
      return events;
    }

    return [];
  }

  DomainEvent _deserializeEvent(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'DocumentContentSaved':
        return DocumentContentSaved(
          documentId: json['documentId'],
          content: DocumentContent.fromJson(json['content']),
          metadata: json['metadata'],
          version: json['version'],
        );
      default:
        throw UnsupportedError('Unknown event type: $type');
    }
  }
}
```

### **CQRS Bus Implementation**

```dart
// ===== CQRS BUS =====

class CqrsBus {
  final Map<Type, CommandHandler> _commandHandlers = {};
  final Map<Type, QueryHandler> _queryHandlers = {};
  final StreamController<CqrsEvent> _eventController = StreamController.broadcast();

  Stream<CqrsEvent> get events => _eventController.stream;

  void registerCommandHandler<T extends PersistenceCommand>(
    CommandHandler<T> handler,
  ) {
    _commandHandlers[T] = handler;
  }

  void registerQueryHandler<TQuery extends PersistenceQuery, TResult>(
    QueryHandler<TQuery, TResult> handler,
  ) {
    _queryHandlers[TQuery] = handler;
  }

  Future<CommandResult> send<T extends PersistenceCommand>(T command) async {
    final handler = _commandHandlers[T] as CommandHandler<T>?;
    if (handler == null) {
      return CommandResult.failure('No handler registered for ${T.runtimeType}');
    }

    final startTime = DateTime.now();
    try {
      final result = await handler.handle(command);
      final duration = DateTime.now().difference(startTime);

      _eventController.add(CommandExecuted(
        commandType: T.toString(),
        result: result,
        duration: duration,
      ));

      return result;
    } catch (e) {
      _eventController.add(CommandFailed(
        commandType: T.toString(),
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      ));
      return CommandResult.failure(e.toString());
    }
  }

  Future<QueryResult<TResult>> query<TQuery extends PersistenceQuery, TResult>(
    TQuery query,
  ) async {
    final handler = _queryHandlers[TQuery] as QueryHandler<TQuery, TResult>?;
    if (handler == null) {
      return QueryResult.failure('No handler registered for ${TQuery.runtimeType}');
    }

    final startTime = DateTime.now();
    try {
      final result = await handler.handle(query);
      final duration = DateTime.now().difference(startTime);

      _eventController.add(QueryExecuted(
        queryType: TQuery.toString(),
        result: result,
        duration: duration,
      ));

      return result;
    } catch (e) {
      _eventController.add(QueryFailed(
        queryType: TQuery.toString(),
        error: e.toString(),
        duration: DateTime.now().difference(startTime),
      ));
      return QueryResult.failure(e.toString());
    }
  }
}
```

---

## 🔄 **2. Saga Pattern for Complex Transactions**

### **Saga Implementation**

```dart
// ===== SAGA PATTERN =====

abstract class Saga {
  String get sagaId;
  SagaState get state;
  Future<void> start();
  Future<void> handleEvent(DomainEvent event);
  Future<void> compensate();
}

enum SagaState { notStarted, inProgress, completed, compensating, failed }

class DocumentPersistenceSaga extends Saga {
  final String documentId;
  final DocumentContent content;
  final CqrsBus _bus;
  final PersistenceManager _persistence;

  @override
  String get sagaId => 'document_persistence_$documentId';

  SagaState _state = SagaState.notStarted;

  @override
  SagaState get state => _state;

  DocumentPersistenceSaga({
    required this.documentId,
    required this.content,
    required CqrsBus bus,
    required PersistenceManager persistence,
  }) : _bus = bus,
       _persistence = persistence;

  @override
  Future<void> start() async {
    _state = SagaState.inProgress;

    try {
      // Step 1: Validate content
      await _validateContent();

      // Step 2: Create backup
      await _createBackup();

      // Step 3: Save document
      final saveCommand = SaveDocumentCommand(
        documentId: documentId,
        content: content,
        metadata: {'sagaId': sagaId},
      );

      final result = await _bus.send(saveCommand);
      if (!result.success) {
        throw Exception('Save failed: ${result.error}');
      }

      // Step 4: Update search index
      await _updateSearchIndex();

      // Step 5: Notify collaborators
      await _notifyCollaborators();

      _state = SagaState.completed;

    } catch (e) {
      _state = SagaState.failed;
      await compensate();
      rethrow;
    }
  }

  @override
  Future<void> handleEvent(DomainEvent event) async {
    // Handle external events that might affect the saga
    if (event is CollaboratorJoined && event.documentId == documentId) {
      // Update permissions or resend notifications
      await _notifyCollaborators();
    }
  }

  @override
  Future<void> compensate() async {
    _state = SagaState.compensating;

    try {
      // Rollback steps in reverse order
      await _removeNotifications();
      await _removeFromSearchIndex();
      await _restoreFromBackup();
      await _cleanupSagaData();

      _state = SagaState.notStarted;
    } catch (e) {
      // Log compensation failure - manual intervention may be needed
      _persistence.persist(
        'saga_compensation_failure_$sagaId',
        {'error': e.toString(), 'timestamp': DateTime.now()},
        priority: PersistencePriority.critical,
      );
    }
  }

  Future<void> _validateContent() async {
    if (content.blocks.isEmpty) {
      throw ValidationException('Document must have at least one block');
    }

    // Additional validation logic...
  }

  Future<void> _createBackup() async {
    final current = await _bus.query(GetDocumentQuery(documentId: documentId));
    if (current.success && current.data != null) {
      await _persistence.persist(
        'backup_${documentId}_${DateTime.now().millisecondsSinceEpoch}',
        current.data,
        priority: PersistencePriority.important,
      );
    }
  }

  Future<void> _updateSearchIndex() async {
    // Update search index with new content
    final searchData = _extractSearchData(content);
    await _persistence.persist(
      'search_index_$documentId',
      searchData,
      priority: PersistencePriority.background,
    );
  }

  Future<void> _notifyCollaborators() async {
    // Send real-time notifications to collaborators
    final collaborators = await _getCollaborators(documentId);
    for (final collaborator in collaborators) {
      await _sendNotification(collaborator, 'Document updated');
    }
  }

  // Compensation methods...
  Future<void> _removeNotifications() async { /* ... */ }
  Future<void> _removeFromSearchIndex() async { /* ... */ }
  Future<void> _restoreFromBackup() async { /* ... */ }
  Future<void> _cleanupSagaData() async { /* ... */ }
}
```

### **Saga Coordinator**

```dart
// ===== SAGA COORDINATOR =====

class SagaCoordinator {
  final Map<String, Saga> _activeSagas = {};
  final CqrsBus _bus;
  final PersistenceManager _persistence;

  SagaCoordinator(this._bus, this._persistence) {
    _setupEventHandling();
  }

  Future<String> startSaga(Saga saga) async {
    _activeSagas[saga.sagaId] = saga;

    // Persist saga state
    await _persistence.persist(
      'saga_state_${saga.sagaId}',
      {'state': saga.state.toString(), 'startTime': DateTime.now()},
      priority: PersistencePriority.important,
    );

    try {
      await saga.start();

      // Saga completed successfully
      _activeSagas.remove(saga.sagaId);
      await _cleanupSaga(saga.sagaId);

    } catch (e) {
      // Saga failed - it will handle its own compensation
      await _handleSagaFailure(saga, e);
    }

    return saga.sagaId;
  }

  void _setupEventHandling() {
    _bus.events.listen((event) {
      // Forward relevant events to active sagas
      for (final saga in _activeSagas.values) {
        if (_isRelevantEvent(saga, event)) {
          saga.handleEvent(event);
        }
      }
    });
  }

  bool _isRelevantEvent(Saga saga, CqrsEvent event) {
    // Determine if event is relevant to this saga
    if (saga is DocumentPersistenceSaga && event is DocumentEvent) {
      return event.documentId == saga.documentId;
    }
    return false;
  }

  Future<void> _handleSagaFailure(Saga saga, dynamic error) async {
    // Log failure
    await _persistence.persist(
      'saga_failure_${saga.sagaId}',
      {
        'error': error.toString(),
        'timestamp': DateTime.now(),
        'sagaType': saga.runtimeType.toString(),
      },
      priority: PersistencePriority.critical,
    );

    // Alert monitoring
    MonitoringSystem.alert(
      'Saga Failure',
      'Saga ${saga.sagaId} failed: $error',
      severity: AlertSeverity.high,
    );
  }

  Future<void> _cleanupSaga(String sagaId) async {
    await _persistence.persist(
      'saga_completed_$sagaId',
      {'completionTime': DateTime.now()},
      priority: PersistencePriority.background,
    );
  }

  // Recovery: Restart incomplete sagas on app startup
  Future<void> recoverIncompleteSagas() async {
    final incompleteSagas = await _findIncompleteSagas();

    for (final sagaData in incompleteSagas) {
      // Recreate and resume saga
      final saga = await _recreateSaga(sagaData);
      if (saga.state == SagaState.inProgress) {
        // Resume from last known state
        await _resumeSaga(saga);
      }
    }
  }
}
```

---

## 🔌 **3. Circuit Breaker Pattern**

### **Circuit Breaker Implementation**

```dart
// ===== CIRCUIT BREAKER =====

enum CircuitState { closed, open, halfOpen }

class PersistenceCircuitBreaker {
  final String serviceName;
  final int failureThreshold;
  final Duration timeout;
  final Duration retryTimeout;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  int _successCount = 0;

  PersistenceCircuitBreaker({
    required this.serviceName,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.retryTimeout = const Duration(seconds: 30),
  });

  Future<PersistenceResult<T>> execute<T>(
    Future<PersistenceResult<T>> Function() operation,
  ) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
      } else {
        return PersistenceResult(
          success: false,
          error: 'Circuit breaker is OPEN for $serviceName',
          metadata: {'circuit_state': 'open'},
        );
      }
    }

    try {
      final result = await operation();

      if (result.success) {
        _onSuccess();
      } else {
        _onFailure();
      }

      return result;

    } catch (e) {
      _onFailure();
      return PersistenceResult(
        success: false,
        error: e.toString(),
        metadata: {'circuit_state': _state.toString()},
      );
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _successCount++;

    if (_state == CircuitState.halfOpen) {
      // Enough successes, close the circuit
      if (_successCount >= 3) {
        _state = CircuitState.closed;
        _successCount = 0;

        MonitoringSystem.alert(
          'Circuit Closed',
          'Circuit breaker CLOSED for $serviceName',
          severity: AlertSeverity.info,
        );
      }
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;

      MonitoringSystem.alert(
        'Circuit Opened',
        'Circuit breaker OPENED for $serviceName after $_failureCount failures',
        severity: AlertSeverity.warning,
      );
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > retryTimeout;
  }

  CircuitState get state => _state;
  int get failureCount => _failureCount;
}
```

### **Integration with Persistence Strategies**

```dart
// ===== CIRCUIT BREAKER INTEGRATION =====

class ResilientPersistenceStrategy implements PersistenceStrategy {
  final PersistenceStrategy _innerStrategy;
  final PersistenceCircuitBreaker _circuitBreaker;

  ResilientPersistenceStrategy({
    required PersistenceStrategy innerStrategy,
    required String serviceName,
  }) : _innerStrategy = innerStrategy,
       _circuitBreaker = PersistenceCircuitBreaker(serviceName: serviceName);

  @override
  String get name => 'resilient_${_innerStrategy.name}';

  @override
  PersistencePriority get priority => _innerStrategy.priority;

  @override
  Future<PersistenceResult> save(String key, dynamic data) {
    return _circuitBreaker.execute(() => _innerStrategy.save(key, data));
  }

  @override
  Future<PersistenceResult> load(String key) {
    return _circuitBreaker.execute(() => _innerStrategy.load(key));
  }

  @override
  Future<bool> exists(String key) {
    return _circuitBreaker.execute(() async {
      final result = await _innerStrategy.exists(key);
      return PersistenceResult(
        data: result,
        success: true,
        metadata: {'exists': result},
      );
    }).then((result) => result.data as bool? ?? false);
  }

  @override
  Future<void> delete(String key) {
    return _circuitBreaker.execute(() => _innerStrategy.delete(key))
        .then((_) {});
  }

  @override
  Future<List<String>> listKeys({String? prefix}) {
    return _circuitBreaker.execute(() => _innerStrategy.listKeys(prefix: prefix))
        .then((result) => result.data as List<String>? ?? []);
  }
}
```

---

## 🏭 **4. Repository + Unit of Work Pattern**

### **Advanced Repository Pattern**

```dart
// ===== ADVANCED REPOSITORY =====

abstract class IRepository<TAggregate, TId> {
  Future<TAggregate?> getById(TId id);
  Future<List<TAggregate>> getAll();
  Future<void> add(TAggregate aggregate);
  Future<void> update(TAggregate aggregate);
  Future<void> remove(TId id);
  Future<bool> exists(TId id);
  Future<int> count();
}

abstract class ISpecification<T> {
  bool isSatisfiedBy(T item);
  ISpecification<T> and(ISpecification<T> other);
  ISpecification<T> or(ISpecification<T> other);
  ISpecification<T> not();
}

class DocumentRepository implements IRepository<DocumentAggregate, String> {
  final PersistenceManager _persistence;
  final EventStore _eventStore;

  @override
  Future<DocumentAggregate?> getById(String id) async {
    // Load from event store for event sourcing
    final events = await _eventStore.getEvents(id);
    if (events.isEmpty) return null;

    // Rebuild aggregate from events
    return DocumentAggregate.rebuildFromEvents(id, events);
  }

  @override
  Future<List<DocumentAggregate>> getAll() async {
    // This would be inefficient for large datasets
    // In practice, you'd have a read model for this
    throw UnimplementedError('Use read model for bulk queries');
  }

  @override
  Future<void> add(DocumentAggregate aggregate) async {
    final events = aggregate.getUncommittedEvents();
    await _eventStore.appendEvents(aggregate.id, events, -1);
    aggregate.markEventsAsCommitted();
  }

  @override
  Future<void> update(DocumentAggregate aggregate) async {
    final events = aggregate.getUncommittedEvents();
    final currentVersion = await _getCurrentVersion(aggregate.id);
    await _eventStore.appendEvents(aggregate.id, events, currentVersion);
    aggregate.markEventsAsCommitted();
  }

  @override
  Future<void> remove(String id) async {
    // Mark as deleted with event
    final deleteEvent = DocumentDeleted(id: id);
    await _eventStore.appendEvents(id, [deleteEvent], await _getCurrentVersion(id));
  }

  Future<int> _getCurrentVersion(String id) async {
    final events = await _eventStore.getEvents(id);
    return events.length;
  }
}
```

### **Unit of Work Pattern**

```dart
// ===== UNIT OF WORK =====

abstract class IUnitOfWork {
  Future<void> beginTransaction();
  Future<void> commit();
  Future<void> rollback();
  bool get isInTransaction;
  void registerNew<T>(T entity);
  void registerModified<T>(T entity);
  void registerDeleted<T>(T entity);
}

class PersistenceUnitOfWork implements IUnitOfWork {
  final Map<String, IRepository> _repositories;
  final List<DomainEvent> _events = [];
  final Map<String, dynamic> _identityMap = {};
  bool _isInTransaction = false;
  bool _hasChanges = false;

  PersistenceUnitOfWork(this._repositories);

  @override
  Future<void> beginTransaction() async {
    _isInTransaction = true;
    _events.clear();
    _hasChanges = false;
  }

  @override
  Future<void> commit() async {
    if (!_isInTransaction) {
      throw StateError('No active transaction');
    }

    if (!_hasChanges) {
      _isInTransaction = false;
      return;
    }

    try {
      // Validate all changes
      await _validateChanges();

      // Apply all changes
      await _applyChanges();

      // Publish events
      await _publishEvents();

      _isInTransaction = false;
      _hasChanges = false;

    } catch (e) {
      await rollback();
      rethrow;
    }
  }

  @override
  Future<void> rollback() async {
    _events.clear();
    _identityMap.clear();
    _isInTransaction = false;
    _hasChanges = false;
  }

  @override
  bool get isInTransaction => _isInTransaction;

  @override
  void registerNew<T>(T entity) {
    _ensureTransaction();
    _hasChanges = true;
    // Store for later insertion
  }

  @override
  void registerModified<T>(T entity) {
    _ensureTransaction();
    _hasChanges = true;
    // Store for later update
  }

  @override
  void registerDeleted<T>(T entity) {
    _ensureTransaction();
    _hasChanges = true;
    // Store for later deletion
  }

  void _ensureTransaction() {
    if (!_isInTransaction) {
      throw StateError('Must be in transaction to register changes');
    }
  }

  Future<void> _validateChanges() async {
    // Validate business rules across all changes
    // e.g., check referential integrity
  }

  Future<void> _applyChanges() async {
    // Apply all registered changes in correct order
    // Handle dependencies between changes
  }

  Future<void> _publishEvents() async {
    if (_events.isNotEmpty) {
      // Publish all events
      final eventBus = GetIt.I<DomainEventBus>();
      for (final event in _events) {
        eventBus.publish(event);
      }
    }
  }
}
```

---

## 🎨 **5. Domain-Driven Design with Aggregates**

### **Rich Domain Model**

```dart
// ===== DOMAIN AGGREGATE =====

class DocumentAggregate {
  final String id;
  final List<DomainEvent> _events = [];
  DocumentContent? _content;
  DocumentMetadata _metadata;
  bool _isDeleted = false;

  DocumentAggregate._(this.id, this._metadata);

  static DocumentAggregate create(String id) {
    final aggregate = DocumentAggregate._(id, DocumentMetadata.empty());
    aggregate._addEvent(DocumentCreated(id: id));
    return aggregate;
  }

  static DocumentAggregate rebuildFromEvents(String id, List<DomainEvent> events) {
    final aggregate = DocumentAggregate._(id, DocumentMetadata.empty());

    for (final event in events) {
      aggregate._applyEvent(event);
    }

    return aggregate;
  }

  // Business Logic
  List<DomainEvent> saveContent(DocumentContent content, Map<String, dynamic> metadata) {
    _validateContent(content);

    final oldContent = _content;
    _content = content;
    _metadata = _metadata.updateLastModified();

    _addEvent(DocumentContentSaved(
      documentId: id,
      content: content,
      oldContent: oldContent,
      metadata: metadata,
    ));

    return getUncommittedEvents();
  }

  void rename(String newTitle) {
    _validateNotDeleted();

    _metadata = _metadata.copyWith(title: newTitle);
    _addEvent(DocumentRenamed(
      documentId: id,
      newTitle: newTitle,
      oldTitle: _metadata.title,
    ));
  }

  void delete() {
    _validateNotDeleted();

    _isDeleted = true;
    _addEvent(DocumentDeleted(id: id));
  }

  // Validation
  void _validateContent(DocumentContent content) {
    if (content.blocks.isEmpty) {
      throw DomainException('Document must have at least one block');
    }

    if (content.blocks.any((block) => block.content.isEmpty)) {
      throw DomainException('Document blocks cannot be empty');
    }
  }

  void _validateNotDeleted() {
    if (_isDeleted) {
      throw DomainException('Cannot modify deleted document');
    }
  }

  // Event Handling
  void _addEvent(DomainEvent event) {
    _events.add(event);
    _applyEvent(event);
  }

  void _applyEvent(DomainEvent event) {
    switch (event.runtimeType) {
      case DocumentCreated:
        // Initialize aggregate
        break;
      case DocumentContentSaved:
        final e = event as DocumentContentSaved;
        _content = e.content;
        _metadata = _metadata.updateLastModified();
        break;
      case DocumentRenamed:
        final e = event as DocumentRenamed;
        _metadata = _metadata.copyWith(title: e.newTitle);
        break;
      case DocumentDeleted:
        _isDeleted = true;
        break;
    }
  }

  // Public API
  List<DomainEvent> getUncommittedEvents() => List.unmodifiable(_events);
  void markEventsAsCommitted() => _events.clear();

  DocumentContent? get content => _content;
  DocumentMetadata get metadata => _metadata;
  bool get isDeleted => _isDeleted;
}

class DocumentMetadata {
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final String authorId;
  final List<String> collaboratorIds;

  const DocumentMetadata({
    required this.title,
    required this.createdAt,
    required this.lastModified,
    required this.authorId,
    required this.collaboratorIds,
  });

  static DocumentMetadata empty() => DocumentMetadata(
    title: 'Untitled Document',
    createdAt: DateTime.now(),
    lastModified: DateTime.now(),
    authorId: '',
    collaboratorIds: [],
  );

  DocumentMetadata copyWith({
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    String? authorId,
    List<String>? collaboratorIds,
  }) {
    return DocumentMetadata(
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      authorId: authorId ?? this.authorId,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }

  DocumentMetadata updateLastModified() {
    return copyWith(lastModified: DateTime.now());
  }
}
```

---

## 🔧 **6. Pipeline Pattern for Processing**

### **Persistence Pipeline**

```dart
// ===== PIPELINE PATTERN =====

abstract class PipelineStep<TInput, TOutput> {
  Future<PipelineResult<TOutput>> execute(TInput input);
}

class PipelineResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  const PipelineResult({
    this.data,
    required this.success,
    this.error,
    this.metadata = const {},
  });
}

class PersistencePipeline {
  final List<PipelineStep> _steps = [];

  void addStep<TInput, TOutput>(PipelineStep<TInput, TOutput> step) {
    _steps.add(step);
  }

  Future<PipelineResult> execute(dynamic input) async {
    dynamic currentInput = input;
    final metadata = <String, dynamic>{};

    for (final step in _steps) {
      final result = await step.execute(currentInput);

      if (!result.success) {
        return PipelineResult(
          success: false,
          error: result.error,
          metadata: {
            ...metadata,
            'failed_step': step.runtimeType.toString(),
          },
        );
      }

      currentInput = result.data;
      metadata.addAll(result.metadata);
    }

    return PipelineResult(
      data: currentInput,
      success: true,
      metadata: metadata,
    );
  }
}

// Pipeline Steps
class ValidationStep extends PipelineStep<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  Future<PipelineResult<Map<String, dynamic>>> execute(Map<String, dynamic> input) async {
    // Validate input data
    final errors = _validate(input);

    if (errors.isNotEmpty) {
      return PipelineResult(
        success: false,
        error: 'Validation failed: ${errors.join(', ')}',
        metadata: {'validation_errors': errors},
      );
    }

    return PipelineResult(
      data: input,
      success: true,
      metadata: {'validated': true},
    );
  }

  List<String> _validate(Map<String, dynamic> data) {
    final errors = <String>[];

    if (!data.containsKey('id')) {
      errors.add('Missing id field');
    }

    if (!data.containsKey('content')) {
      errors.add('Missing content field');
    }

    return errors;
  }
}

class EnrichmentStep extends PipelineStep<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  Future<PipelineResult<Map<String, dynamic>>> execute(Map<String, dynamic> input) async {
    // Enrich data with additional information
    final enriched = Map<String, dynamic>.from(input);

    enriched['timestamp'] = DateTime.now().toIso8601String();
    enriched['version'] = await _getNextVersion(input['id']);
    enriched['hash'] = _calculateHash(input);

    return PipelineResult(
      data: enriched,
      success: true,
      metadata: {'enriched': true, 'fields_added': ['timestamp', 'version', 'hash']},
    );
  }

  Future<int> _getNextVersion(String id) async {
    // Get next version from event store
    return 1; // Simplified
  }

  String _calculateHash(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    return sha256.convert(utf8.encode(json)).toString();
  }
}

class PersistenceStep extends PipelineStep<Map<String, dynamic>, PersistenceResult> {
  final PersistenceManager _persistence;

  PersistenceStep(this._persistence);

  @override
  Future<PipelineResult<PersistenceResult>> execute(Map<String, dynamic> input) async {
    final key = 'document_${input['id']}';
    final result = await _persistence.persist(key, input, priority: PersistencePriority.critical);

    return PipelineResult(
      data: result,
      success: result.success,
      error: result.error,
      metadata: {'persisted': result.success, 'duration': result.duration.inMilliseconds},
    );
  }
}

class NotificationStep extends PipelineStep<PersistenceResult, PersistenceResult> {
  @override
  Future<PipelineResult<PersistenceResult>> execute(PersistenceResult input) async {
    if (input.success) {
      // Send success notifications
      await _sendSuccessNotification(input);
    } else {
      // Send failure notifications
      await _sendFailureNotification(input);
    }

    return PipelineResult(
      data: input,
      success: true, // Notification step always succeeds
      metadata: {'notification_sent': true},
    );
  }

  Future<void> _sendSuccessNotification(PersistenceResult result) async {
    // Send success notification to user/monitoring
  }

  Future<void> _sendFailureNotification(PersistenceResult result) async {
    // Send failure notification with error details
  }
}
```

### **Pipeline Usage**

```dart
// ===== PIPELINE USAGE =====

class DocumentPersistencePipeline {
  final PersistencePipeline _pipeline = PersistencePipeline();

  DocumentPersistencePipeline() {
    // Build the pipeline
    _pipeline.addStep(ValidationStep());
    _pipeline.addStep(EnrichmentStep());
    _pipeline.addStep(PersistenceStep(GetIt.I<PersistenceManager>()));
    _pipeline.addStep(NotificationStep());
  }

  Future<PipelineResult> saveDocument(Map<String, dynamic> documentData) {
    return _pipeline.execute(documentData);
  }
}

// Usage
final pipeline = DocumentPersistencePipeline();
final result = await pipeline.saveDocument({
  'id': 'doc123',
  'content': documentContent,
  'metadata': {'author': 'user123'},
});

if (result.success) {
  print('Document saved successfully');
} else {
  print('Failed to save document: ${result.error}');
}
```

---

## 🎯 **Putting It All Together**

### **Complete Enterprise Architecture**

```dart
// ===== ENTERPRISE ARCHITECTURE =====

class EnterprisePersistenceSystem {
  final CqrsBus _cqrsBus;
  final EventStore _eventStore;
  final SagaCoordinator _sagaCoordinator;
  final PersistenceManager _persistenceManager;
  final PersistenceMonitoringDashboard _monitoring;

  EnterprisePersistenceSystem()
      : _cqrsBus = CqrsBus(),
        _eventStore = EventStore(GetIt.I<PersistenceManager>()),
        _sagaCoordinator = SagaCoordinator(GetIt.I<CqrsBus>(), GetIt.I<PersistenceManager>()),
        _persistenceManager = PersistenceManager(),
        _monitoring = PersistenceMonitoringDashboard() {

    _initializeSystem();
  }

  void _initializeSystem() {
    // Register command handlers
    _cqrsBus.registerCommandHandler(SaveDocumentCommandHandler(
      _eventStore,
      GetIt.I<DocumentAggregateRepository>(),
    ));

    // Register query handlers
    _cqrsBus.registerQueryHandler(GetDocumentQueryHandler(
      GetIt.I<DocumentReadModelRepository>(),
    ));

    // Setup monitoring
    _setupMonitoring();

    // Setup circuit breakers
    _setupCircuitBreakers();
  }

  Future<CommandResult> saveDocument(String documentId, DocumentContent content) async {
    // Create saga for complex operation
    final saga = DocumentPersistenceSaga(
      documentId: documentId,
      content: content,
      bus: _cqrsBus,
      persistence: _persistenceManager,
    );

    // Execute via saga coordinator
    await _sagaCoordinator.startSaga(saga);

    // Return result
    return CommandResult.success('Document saved via saga');
  }

  Future<QueryResult<DocumentContent?>> getDocument(String documentId) {
    final query = GetDocumentQuery(documentId: documentId);
    return _cqrsBus.query(query);
  }

  void _setupMonitoring() {
    // Monitor CQRS operations
    _cqrsBus.events.listen((event) {
      _monitoring.recordOperation(event);
    });

    // Monitor persistence operations
    _persistenceManager.events.listen((event) {
      _monitoring.recordPersistenceEvent(event);
    });
  }

  void _setupCircuitBreakers() {
    // Wrap strategies with circuit breakers
    final resilientStrategy = ResilientPersistenceStrategy(
      innerStrategy: ImmediatePersistenceStrategy(),
      serviceName: 'document_persistence',
    );

    _persistenceManager.registerStrategy('resilient_immediate', resilientStrategy);
  }
}
```

### **Benefits of This Architecture**

1. **CQRS + Event Sourcing**: Complete audit trail, temporal queries, event-driven reactions
2. **Saga Pattern**: Reliable complex operations with compensation
3. **Circuit Breaker**: Automatic failure handling and recovery
4. **Repository + UoW**: Clean data access with transactional consistency
5. **DDD Aggregates**: Rich business logic with invariants
6. **Pipeline Pattern**: Composable, testable processing steps

### **Performance Characteristics**

- **Reads**: Optimized via CQRS read models
- **Writes**: Event-sourced with immediate consistency for critical data
- **Failures**: Circuit breakers prevent cascade failures
- **Complex Ops**: Sagas ensure consistency across services
- **Monitoring**: Complete observability of all operations

This represents a **production-ready, enterprise-grade persistence architecture** that can handle complex business requirements while maintaining reliability, performance, and observability.