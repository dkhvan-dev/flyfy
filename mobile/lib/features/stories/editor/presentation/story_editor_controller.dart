import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';

import '../../../../core/network/file_api.dart';
import '../../models/story_vm.dart';
import '../data/story_editor_api.dart';
import '../data/story_editor_dto.dart';
import '../data/story_editor_recovery_store.dart';
import '../domain/story_document.dart';
import '../domain/story_editor_autosave_policy.dart';

enum StoryEditorMode { create, edit }

enum StoryEditorSavePhase { idle, saving, saved, failed, conflict }

enum StoryEditorValidationScope { none, draft, publish }

enum StoryEditorMediaStatus { queued, uploading, uploaded, failed, removed }

enum StoryEditorMediaUploadKind { cover, inlineImage }

enum StoryEditorMediaErrorCode {
  retryUpload,
  uploadInterrupted,
  missingSource,
  uploadFailed,
}

enum StoryEditorTemplateApplyMode { replace, append, metadataOnly }

enum StoryEditorTemplateBlockOrigin { template, userEditedTemplate, user }

class StoryEditorTemplateState {
  StoryEditorTemplateState({
    this.appliedTemplateId,
    this.appliedTemplateVersion,
    Map<String, StoryEditorTemplateBlockOrigin> blockOrigins = const {},
    this.formatTouchedByUser = false,
    this.categoryTouchedByUser = false,
  }) : _blockOrigins = Map.unmodifiable(blockOrigins);

  StoryEditorTemplateState.empty() : this();

  final String? appliedTemplateId;
  final String? appliedTemplateVersion;
  final Map<String, StoryEditorTemplateBlockOrigin> _blockOrigins;
  final bool formatTouchedByUser;
  final bool categoryTouchedByUser;

  Map<String, StoryEditorTemplateBlockOrigin> get blockOrigins => _blockOrigins;

  bool get hasMetadataTouchedByUser =>
      formatTouchedByUser || categoryTouchedByUser;

  StoryEditorTemplateBlockOrigin? originFor(String blockId) {
    return _blockOrigins[blockId];
  }

  StoryEditorTemplateState copyWith({
    Object? appliedTemplateId = _sentinel,
    Object? appliedTemplateVersion = _sentinel,
    Map<String, StoryEditorTemplateBlockOrigin>? blockOrigins,
    bool? formatTouchedByUser,
    bool? categoryTouchedByUser,
  }) {
    return StoryEditorTemplateState(
      appliedTemplateId: identical(appliedTemplateId, _sentinel)
          ? this.appliedTemplateId
          : appliedTemplateId as String?,
      appliedTemplateVersion: identical(appliedTemplateVersion, _sentinel)
          ? this.appliedTemplateVersion
          : appliedTemplateVersion as String?,
      blockOrigins: blockOrigins ?? _blockOrigins,
      formatTouchedByUser: formatTouchedByUser ?? this.formatTouchedByUser,
      categoryTouchedByUser:
          categoryTouchedByUser ?? this.categoryTouchedByUser,
    );
  }

  StoryEditorTemplateState withUserBlock(String blockId) {
    final normalized = _normalizeNullable(blockId);
    if (normalized == null) return this;
    return copyWith(
      blockOrigins: {
        ..._blockOrigins,
        normalized: StoryEditorTemplateBlockOrigin.user,
      },
    );
  }

  StoryEditorTemplateState withUserEditedBlock(String blockId) {
    final normalized = _normalizeNullable(blockId);
    if (normalized == null) return this;
    final current = _blockOrigins[normalized];
    final nextOrigin = current == StoryEditorTemplateBlockOrigin.template
        ? StoryEditorTemplateBlockOrigin.userEditedTemplate
        : current ?? StoryEditorTemplateBlockOrigin.user;
    if (current == nextOrigin) return this;
    return copyWith(blockOrigins: {..._blockOrigins, normalized: nextOrigin});
  }

  StoryEditorTemplateState withoutBlocks(Iterable<String> blockIds) {
    final removeIds = blockIds
        .map(_normalizeNullable)
        .whereType<String>()
        .toSet();
    if (removeIds.isEmpty) return this;
    final next = Map<String, StoryEditorTemplateBlockOrigin>.from(_blockOrigins)
      ..removeWhere((blockId, _) => removeIds.contains(blockId));
    return copyWith(blockOrigins: next);
  }
}

const int _maxRecoverablePreviewBytes = 64 * 1024;

abstract class StoryEditorApiGateway {
  Future<StoryVm> getStory(String storyId);

  Future<StoryVm> createDraft(StoryEditorWriteRequest request);

  Future<StoryVm> autosave(String storyId, StoryEditorWriteRequest request);

  Future<StoryVm> update(String storyId, StoryEditorWriteRequest request);

  Future<StoryVm> publish(String storyId, StoryEditorWriteRequest request);

  Future<StoryVm> archive(String storyId, {int? revision});
}

class StoryEditorApiGatewayAdapter implements StoryEditorApiGateway {
  StoryEditorApiGatewayAdapter([StoryEditorApi? api])
    : _api = api ?? StoryEditorApi();

  final StoryEditorApi _api;

  @override
  Future<StoryVm> getStory(String storyId) {
    return _api.getStory(storyId);
  }

  @override
  Future<StoryVm> createDraft(StoryEditorWriteRequest request) {
    return _api.createDraft(request);
  }

  @override
  Future<StoryVm> autosave(String storyId, StoryEditorWriteRequest request) {
    return _api.autosave(storyId, request);
  }

  @override
  Future<StoryVm> update(String storyId, StoryEditorWriteRequest request) {
    return _api.update(storyId, request);
  }

  @override
  Future<StoryVm> publish(String storyId, StoryEditorWriteRequest request) {
    return _api.publish(storyId, request);
  }

  @override
  Future<StoryVm> archive(String storyId, {int? revision}) {
    return _api.archive(storyId, revision: revision);
  }
}

abstract class StoryEditorRecoveryGateway {
  Future<bool> save(StoryEditorRecoverySnapshot snapshot);

  Future<StoryEditorRecoverySnapshot?> load({
    required String userId,
    String? storyId,
    String? localDraftId,
  });

  Future<bool> clear({
    required String userId,
    String? storyId,
    String? localDraftId,
  });
}

class StoryEditorRecoveryStoreGateway implements StoryEditorRecoveryGateway {
  StoryEditorRecoveryStoreGateway([StoryEditorRecoveryStore? store])
    : _store = store ?? StoryEditorRecoveryStore();

  final StoryEditorRecoveryStore _store;

  @override
  Future<bool> save(StoryEditorRecoverySnapshot snapshot) {
    return _store.save(snapshot);
  }

  @override
  Future<StoryEditorRecoverySnapshot?> load({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) {
    return _store.load(
      userId: userId,
      storyId: storyId,
      localDraftId: localDraftId,
    );
  }

  @override
  Future<bool> clear({
    required String userId,
    String? storyId,
    String? localDraftId,
  }) {
    return _store.clear(
      userId: userId,
      storyId: storyId,
      localDraftId: localDraftId,
    );
  }
}

class StoryEditorMediaUploadRequest {
  const StoryEditorMediaUploadRequest({
    required this.localMediaId,
    required this.kind,
    this.fileName,
    this.mimeType,
    this.byteSize,
    this.localPath,
    this.bytes,
  });

  final String localMediaId;
  final StoryEditorMediaUploadKind kind;
  final String? fileName;
  final String? mimeType;
  final int? byteSize;
  final String? localPath;
  final Uint8List? bytes;

  bool get hasUploadSource =>
      bytes != null || (localPath != null && localPath!.trim().isNotEmpty);
}

class StoryEditorGalleryUploadDraft {
  const StoryEditorGalleryUploadDraft({
    required this.localMediaId,
    this.fileName,
    this.mimeType,
    this.byteSize,
    this.localPath,
    this.bytes,
  });

  final String localMediaId;
  final String? fileName;
  final String? mimeType;
  final int? byteSize;
  final String? localPath;
  final Uint8List? bytes;
}

class StoryEditorUploadedMedia {
  const StoryEditorUploadedMedia({required this.fileId});

  final String fileId;
}

abstract class StoryEditorMediaUploadGateway {
  Future<StoryEditorUploadedMedia> upload(
    StoryEditorMediaUploadRequest request,
  );
}

abstract class StoryEditorMediaLifecycleGateway {
  Future<void> bindStoryMedia({
    required String storyId,
    required String? coverFileId,
    required Iterable<String> contentFileIds,
  });

  Future<void> releaseStoryMedia(Iterable<String> fileIds);
}

class StoryEditorFileMediaUploadGateway
    implements StoryEditorMediaUploadGateway {
  StoryEditorFileMediaUploadGateway([FileApi? fileApi])
    : _fileApi = fileApi ?? FileApi();

  final FileApi _fileApi;

  @override
  Future<StoryEditorUploadedMedia> upload(
    StoryEditorMediaUploadRequest request,
  ) async {
    final bytes = request.bytes ?? await _readLocalBytes(request);
    final fileName = _normalizeNullable(request.fileName) ?? 'story-media.jpg';
    final mimeType = _normalizeNullable(request.mimeType) ?? 'image/jpeg';
    final sizeBytes = request.byteSize ?? bytes.length;
    final upload = switch (request.kind) {
      StoryEditorMediaUploadKind.cover => await _fileApi.createStoryCoverUpload(
        originalName: fileName,
        contentType: mimeType,
        sizeBytes: sizeBytes,
      ),
      StoryEditorMediaUploadKind.inlineImage =>
        await _fileApi.createStoryInlineImageUpload(
          originalName: fileName,
          contentType: mimeType,
          sizeBytes: sizeBytes,
        ),
    };
    await _fileApi.uploadBinary(
      upload: upload,
      bytes: bytes,
      contentType: mimeType,
    );
    await _fileApi.completeUpload(upload.fileId);
    return StoryEditorUploadedMedia(fileId: upload.fileId);
  }

  Future<Uint8List> _readLocalBytes(StoryEditorMediaUploadRequest request) {
    final localPath = _normalizeNullable(request.localPath);
    if (localPath == null) {
      throw ArgumentError.value(
        request.localMediaId,
        'localMediaId',
        'Media upload requires bytes or a local file path.',
      );
    }
    return io.File(localPath).readAsBytes();
  }
}

class StoryEditorFileMediaLifecycleGateway
    implements StoryEditorMediaLifecycleGateway {
  StoryEditorFileMediaLifecycleGateway([FileApi? fileApi])
    : _fileApi = fileApi ?? FileApi();

  static const _storyOwnerType = 'STORY';
  static const _storyMediaPurpose = 'STORY_MEDIA';

  final FileApi _fileApi;

  @override
  Future<void> bindStoryMedia({
    required String storyId,
    required String? coverFileId,
    required Iterable<String> contentFileIds,
  }) async {
    final normalizedStoryId = _requiredTrim(storyId);
    final normalizedCoverFileId = _normalizeNullable(coverFileId);
    if (normalizedCoverFileId != null) {
      await _fileApi.bindFile(
        fileId: normalizedCoverFileId,
        ownerType: _storyOwnerType,
        ownerId: normalizedStoryId,
        purpose: _storyMediaPurpose,
        isPrimary: true,
      );
    }

    for (final fileId in _normalizeFileIds(contentFileIds)) {
      if (fileId == normalizedCoverFileId) {
        continue;
      }
      await _fileApi.bindFile(
        fileId: fileId,
        ownerType: _storyOwnerType,
        ownerId: normalizedStoryId,
        purpose: _storyMediaPurpose,
      );
    }
  }

  @override
  Future<void> releaseStoryMedia(Iterable<String> fileIds) async {
    for (final fileId in _normalizeFileIds(fileIds)) {
      try {
        await _fileApi.releaseUnboundUpload(fileId);
      } catch (_) {
        // Best-effort client-side cleanup. The server-side TTL cleanup remains
        // the source of truth for uploads that cannot be released immediately.
      }
    }
  }
}

abstract class StoryEditorAutosaveScheduler {
  StoryEditorAutosaveState get state;

  void recordMeaningfulEdit(StoryEditorAutosaveWork work);

  void recordPublishCriticalMetadataChange(StoryEditorAutosaveWork work);

  void dispose();
}

class StoryEditorAutosavePolicyScheduler
    implements StoryEditorAutosaveScheduler {
  StoryEditorAutosavePolicyScheduler([StoryEditorAutosavePolicy? policy])
    : _policy = policy ?? StoryEditorAutosavePolicy();

  final StoryEditorAutosavePolicy _policy;

  @override
  StoryEditorAutosaveState get state => _policy.state;

  @override
  void recordMeaningfulEdit(StoryEditorAutosaveWork work) {
    _policy.recordMeaningfulEdit(work);
  }

  @override
  void recordPublishCriticalMetadataChange(StoryEditorAutosaveWork work) {
    _policy.recordPublishCriticalMetadataChange(work);
  }

  @override
  void dispose() {
    _policy.dispose();
  }
}

class StoryEditorSaveStatus {
  const StoryEditorSaveStatus({required this.phase, this.message, this.error});

  const StoryEditorSaveStatus.idle() : this(phase: StoryEditorSavePhase.idle);

  final StoryEditorSavePhase phase;
  final String? message;
  final Object? error;
}

class StoryEditorPublishValidationSummary {
  StoryEditorPublishValidationSummary({
    List<StoryEditorFieldError> errors = const [],
  }) : errors = List.unmodifiable(errors);

  factory StoryEditorPublishValidationSummary.valid() {
    return StoryEditorPublishValidationSummary();
  }

  final List<StoryEditorFieldError> errors;

  bool get isValid => errors.isEmpty;
}

class StoryEditorConflictState {
  StoryEditorConflictState({
    this.message,
    List<StoryEditorFieldError> fieldErrors = const [],
  }) : fieldErrors = List.unmodifiable(fieldErrors);

  StoryEditorConflictState.none() : this();

  final String? message;
  final List<StoryEditorFieldError> fieldErrors;

  bool get hasConflict => (message ?? '').trim().isNotEmpty;
}

class StoryEditorRecoveryState {
  const StoryEditorRecoveryState({this.snapshot});

  final StoryEditorRecoverySnapshot? snapshot;

  bool get hasSnapshot => snapshot != null;
}

class StoryEditorMediaQueueState {
  StoryEditorMediaQueueState({List<StoryEditorMediaQueueItem> items = const []})
    : items = List.unmodifiable(items);

  final List<StoryEditorMediaQueueItem> items;

  StoryEditorMediaQueueState copyWith({
    List<StoryEditorMediaQueueItem>? items,
  }) {
    return StoryEditorMediaQueueState(items: items ?? this.items);
  }
}

class StoryEditorMediaQueueItem {
  const StoryEditorMediaQueueItem({
    required this.localMediaId,
    required this.status,
    this.kind = StoryEditorMediaUploadKind.inlineImage,
    this.attemptId = 0,
    this.blockId,
    this.galleryImageIndex,
    this.fileName,
    this.mimeType,
    this.byteSize,
    this.localPath,
    this.previewBytes,
    this.fileId,
    this.errorCode,
    this.errorMessage,
  });

  final String localMediaId;
  final StoryEditorMediaStatus status;
  final StoryEditorMediaUploadKind kind;
  final int attemptId;
  final String? blockId;
  final int? galleryImageIndex;
  final String? fileName;
  final String? mimeType;
  final int? byteSize;
  final String? localPath;
  final Uint8List? previewBytes;
  final String? fileId;
  final StoryEditorMediaErrorCode? errorCode;
  final String? errorMessage;

  bool get hasUploadSource =>
      previewBytes != null ||
      (localPath != null && localPath!.trim().isNotEmpty);

  bool get blocksPublish =>
      status == StoryEditorMediaStatus.queued ||
      status == StoryEditorMediaStatus.uploading ||
      status == StoryEditorMediaStatus.failed;

  StoryEditorMediaQueueItem copyWith({
    StoryEditorMediaStatus? status,
    int? attemptId,
    Object? galleryImageIndex = _sentinel,
    String? fileId,
    StoryEditorMediaErrorCode? errorCode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoryEditorMediaQueueItem(
      localMediaId: localMediaId,
      status: status ?? this.status,
      kind: kind,
      attemptId: attemptId ?? this.attemptId,
      blockId: blockId,
      galleryImageIndex: identical(galleryImageIndex, _sentinel)
          ? this.galleryImageIndex
          : galleryImageIndex as int?,
      fileName: fileName,
      mimeType: mimeType,
      byteSize: byteSize,
      localPath: localPath,
      previewBytes: previewBytes,
      fileId: fileId ?? this.fileId,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StoryEditorState {
  StoryEditorState({
    required this.userId,
    required this.mode,
    required this.metadata,
    required this.document,
    this.storyId,
    this.localDraftId,
    this.selectedBlockId,
    this.revision,
    this.isDirty = false,
    this.canUndo = false,
    this.canRedo = false,
    this.saveStatus = const StoryEditorSaveStatus.idle(),
    this.validationScope = StoryEditorValidationScope.none,
    StoryEditorPublishValidationSummary? publishValidation,
    StoryEditorMediaQueueState? mediaQueue,
    StoryEditorConflictState? conflict,
    StoryEditorTemplateState? template,
    this.recovery = const StoryEditorRecoveryState(),
  }) : publishValidation =
           publishValidation ?? StoryEditorPublishValidationSummary.valid(),
       mediaQueue = mediaQueue ?? StoryEditorMediaQueueState(),
       conflict = conflict ?? StoryEditorConflictState.none(),
       template = template ?? StoryEditorTemplateState.empty();

  factory StoryEditorState.empty() {
    return StoryEditorState(
      userId: '',
      mode: StoryEditorMode.create,
      metadata: StoryEditorMetadataDraft(
        title: '',
        format: 'STORY',
        category: 'JOURNAL',
        status: 'DRAFT',
      ),
      document: StoryDocument(),
      template: StoryEditorTemplateState.empty(),
    );
  }

  final String userId;
  final StoryEditorMode mode;
  final String? storyId;
  final String? localDraftId;
  final StoryEditorMetadataDraft metadata;
  final StoryDocument document;
  final String? selectedBlockId;
  final int? revision;
  final bool isDirty;
  final bool canUndo;
  final bool canRedo;
  final StoryEditorSaveStatus saveStatus;
  final StoryEditorValidationScope validationScope;
  final StoryEditorPublishValidationSummary publishValidation;
  final StoryEditorMediaQueueState mediaQueue;
  final StoryEditorConflictState conflict;
  final StoryEditorTemplateState template;
  final StoryEditorRecoveryState recovery;

  bool get canApplyTemplateSilently {
    if (template.hasMetadataTouchedByUser) {
      return false;
    }
    if (document.blocks.isEmpty) {
      return true;
    }
    return document.blocks.every(
      (block) =>
          template.originFor(block.id) ==
          StoryEditorTemplateBlockOrigin.template,
    );
  }

  StoryEditorState copyWith({
    String? userId,
    StoryEditorMode? mode,
    Object? storyId = _sentinel,
    Object? localDraftId = _sentinel,
    StoryEditorMetadataDraft? metadata,
    StoryDocument? document,
    Object? selectedBlockId = _sentinel,
    Object? revision = _sentinel,
    bool? isDirty,
    bool? canUndo,
    bool? canRedo,
    StoryEditorSaveStatus? saveStatus,
    StoryEditorValidationScope? validationScope,
    StoryEditorPublishValidationSummary? publishValidation,
    StoryEditorMediaQueueState? mediaQueue,
    StoryEditorConflictState? conflict,
    StoryEditorTemplateState? template,
    StoryEditorRecoveryState? recovery,
  }) {
    return StoryEditorState(
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      storyId: identical(storyId, _sentinel)
          ? this.storyId
          : storyId as String?,
      localDraftId: identical(localDraftId, _sentinel)
          ? this.localDraftId
          : localDraftId as String?,
      metadata: metadata ?? this.metadata,
      document: document ?? this.document,
      selectedBlockId: identical(selectedBlockId, _sentinel)
          ? this.selectedBlockId
          : selectedBlockId as String?,
      revision: identical(revision, _sentinel)
          ? this.revision
          : revision as int?,
      isDirty: isDirty ?? this.isDirty,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      saveStatus: saveStatus ?? this.saveStatus,
      validationScope: validationScope ?? this.validationScope,
      publishValidation: publishValidation ?? this.publishValidation,
      mediaQueue: mediaQueue ?? this.mediaQueue,
      conflict: conflict ?? this.conflict,
      template: template ?? this.template,
      recovery: recovery ?? this.recovery,
    );
  }
}

class StoryEditorController extends ChangeNotifier {
  StoryEditorController({
    StoryEditorApiGateway? api,
    StoryEditorRecoveryGateway? recovery,
    StoryEditorAutosaveScheduler? autosave,
    StoryEditorMediaUploadGateway? mediaUpload,
    StoryEditorMediaLifecycleGateway? mediaLifecycle,
    String Function()? localDraftIdFactory,
    DateTime Function()? now,
  }) : _api = api ?? StoryEditorApiGatewayAdapter(),
       _recovery = recovery ?? StoryEditorRecoveryStoreGateway(),
       _autosave = autosave ?? StoryEditorAutosavePolicyScheduler(),
       _mediaUpload = mediaUpload ?? StoryEditorFileMediaUploadGateway(),
       _mediaLifecycle =
           mediaLifecycle ?? StoryEditorFileMediaLifecycleGateway(),
       _localDraftIdFactory = localDraftIdFactory ?? _defaultLocalDraftId,
       _now = now ?? DateTime.now;

  final StoryEditorApiGateway _api;
  final StoryEditorRecoveryGateway _recovery;
  final StoryEditorAutosaveScheduler _autosave;
  final StoryEditorMediaUploadGateway _mediaUpload;
  final StoryEditorMediaLifecycleGateway _mediaLifecycle;
  final String Function() _localDraftIdFactory;
  final DateTime Function() _now;

  StoryEditorState _state = StoryEditorState.empty();
  final List<_StoryEditorHistoryEntry> _undoStack = [];
  final List<_StoryEditorHistoryEntry> _redoStack = [];
  final Set<String> _boundStoryFileIds = <String>{};
  int _changeGeneration = 0;
  int _mediaAttemptSequence = 0;
  bool _isDisposed = false;

  StoryEditorState get state => _state;

  Future<void> loadStoryForEdit({
    required String userId,
    required String storyId,
  }) async {
    final story = await _api.getStory(_requiredTrim(storyId));
    if (_isDisposed) return;
    initializeEdit(userId: userId, story: story);
  }

  void initializeCreate({required String userId}) {
    _changeGeneration++;
    _clearHistory();
    _boundStoryFileIds.clear();
    _setState(
      StoryEditorState(
        userId: _requiredTrim(userId),
        mode: StoryEditorMode.create,
        localDraftId: _localDraftIdFactory(),
        metadata: StoryEditorMetadataDraft(
          title: '',
          format: 'STORY',
          category: 'JOURNAL',
          status: 'DRAFT',
        ),
        document: StoryDocument(),
        template: StoryEditorTemplateState.empty(),
      ),
    );
  }

  void initializeEdit({required String userId, required StoryVm story}) {
    _changeGeneration++;
    _clearHistory();
    _boundStoryFileIds
      ..clear()
      ..addAll(
        _normalizeFileIds([
          story.coverFileId,
          ..._storyDocumentFileIds(_documentFromStory(story)),
        ]),
      );
    _setState(
      StoryEditorState(
        userId: _requiredTrim(userId),
        mode: StoryEditorMode.edit,
        storyId: _normalizeNullable(story.id),
        metadata: _metadataFromStory(story),
        document: _documentFromStory(story),
        revision: story.revision,
        template: StoryEditorTemplateState.empty(),
      ),
    );
  }

  void changeTitle(String title) {
    _recordHistory();
    _changeMetadata(_metadataCopyWith(_state.metadata, title: title));
  }

  void changeFormat(String format) {
    _recordHistory();
    _changeMetadata(
      _metadataCopyWith(_state.metadata, format: format),
      template: _state.template.copyWith(formatTouchedByUser: true),
    );
  }

  void changeCategory(String category) {
    _recordHistory();
    _changeMetadata(
      _metadataCopyWith(_state.metadata, category: category),
      template: _state.template.copyWith(categoryTouchedByUser: true),
    );
  }

  void changePlace({
    String? placeName,
    String? placeCountryCode,
    String? placeCityId,
    bool clearPlace = false,
    bool clearCountryCode = false,
    bool clearCityId = false,
  }) {
    _recordHistory();
    _changeMetadata(
      clearPlace
          ? _metadataCopyWith(
              _state.metadata,
              placeName: null,
              placeCountryCode: null,
              placeCityId: null,
            )
          : _metadataCopyWith(
              _state.metadata,
              placeName: placeName ?? _sentinel,
              placeCountryCode: clearCountryCode
                  ? null
                  : placeCountryCode ?? _sentinel,
              placeCityId: clearCityId ? null : placeCityId ?? _sentinel,
            ),
    );
  }

  void clearPlace() {
    changePlace(clearPlace: true);
  }

  void changeTags(List<String> tags) {
    _recordHistory();
    _changeMetadata(_metadataCopyWith(_state.metadata, tags: tags));
  }

  void changeCover(String? coverFileId) {
    _recordHistory();
    if (_normalizeNullable(coverFileId) == null) {
      final coverItemsToRelease = _state.mediaQueue.items
          .where(
            (item) =>
                item.kind == StoryEditorMediaUploadKind.cover &&
                item.status != StoryEditorMediaStatus.removed,
          )
          .toList(growable: false);
      final items = _state.mediaQueue.items
          .map(
            (item) =>
                item.kind == StoryEditorMediaUploadKind.cover &&
                    item.status != StoryEditorMediaStatus.removed
                ? item.copyWith(status: StoryEditorMediaStatus.removed)
                : item,
          )
          .toList(growable: false);
      final metadata = _metadataCopyWith(_state.metadata, coverFileId: null);
      _changeGeneration++;
      _setState(
        _state.copyWith(
          metadata: metadata,
          mediaQueue: StoryEditorMediaQueueState(items: items),
          publishValidation: _validationForCurrentScope(
            metadata,
            _state.document,
            items,
          ),
          conflict: StoryEditorConflictState.none(),
          isDirty: true,
          canUndo: _undoStack.isNotEmpty,
          canRedo: _redoStack.isNotEmpty,
        ),
      );
      _releaseUnboundStoryMedia(_uploadedFileIdsFromQueue(coverItemsToRelease));
      _scheduleAutosave();
      return;
    }
    _changeMetadata(
      _metadataCopyWith(_state.metadata, coverFileId: coverFileId),
    );
  }

  void selectBlock(String? blockId) {
    final normalized = _normalizeNullable(blockId);
    if (normalized != null && _state.document.blockById(normalized) == null) {
      return;
    }
    _setState(_state.copyWith(selectedBlockId: normalized));
  }

  void addBlock(StoryBlock block, {int? index}) {
    _recordHistory();
    final document = index == null
        ? _state.document.appendBlock(block)
        : _state.document.insertBlock(index, block);
    _changeDocument(
      document,
      selectedBlockId: block.id,
      template: _state.template.withUserBlock(block.id),
    );
  }

  void updateBlock(String blockId, StoryBlock Function(StoryBlock) update) {
    _recordHistory();
    _changeDocument(
      _state.document.updateBlock(blockId, update),
      selectedBlockIdChanged: false,
      template: _state.template.withUserEditedBlock(blockId),
    );
  }

  void deleteBlock(String blockId) {
    final normalizedBlockId = _normalizeNullable(blockId);
    if (normalizedBlockId == null) {
      return;
    }
    _recordHistory();
    final document = _state.document.removeBlock(normalizedBlockId);
    final removedItems = _state.mediaQueue.items
        .where(
          (item) =>
              item.blockId == normalizedBlockId &&
              item.status != StoryEditorMediaStatus.removed,
        )
        .toList(growable: false);
    final items = _state.mediaQueue.items
        .map(
          (item) => item.blockId == normalizedBlockId
              ? item.copyWith(status: StoryEditorMediaStatus.removed)
              : item,
        )
        .toList(growable: false);

    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        mediaQueue: StoryEditorMediaQueueState(items: items),
        selectedBlockId: _state.selectedBlockId == normalizedBlockId
            ? null
            : _state.selectedBlockId,
        template: _state.template.withoutBlocks([normalizedBlockId]),
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          items,
        ),
        conflict: StoryEditorConflictState.none(),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _releaseUnboundStoryMedia(_uploadedFileIdsFromQueue(removedItems));
    _scheduleAutosave();
  }

  void reorderBlock(String blockId, int newIndex) {
    _recordHistory();
    _changeDocument(_state.document.moveBlock(blockId, newIndex));
  }

  void applyTemplate({
    required String templateId,
    required String templateVersion,
    required String format,
    required String category,
    required List<StoryBlock> blocks,
    StoryEditorTemplateApplyMode mode = StoryEditorTemplateApplyMode.replace,
  }) {
    _recordHistory();
    final normalizedTemplateId = _requiredTrim(templateId);
    final normalizedTemplateVersion = _requiredTrim(templateVersion);
    final templateBlocks = List<StoryBlock>.unmodifiable(blocks);
    final retainedBlocks = mode == StoryEditorTemplateApplyMode.replace
        ? _state.document.blocks
              .where(
                (block) =>
                    _state.template.originFor(block.id) !=
                    StoryEditorTemplateBlockOrigin.template,
              )
              .toList(growable: false)
        : _state.document.blocks;
    final nextBlocks = switch (mode) {
      StoryEditorTemplateApplyMode.replace => [
        ...retainedBlocks,
        ...templateBlocks,
      ],
      StoryEditorTemplateApplyMode.append => [
        ..._state.document.blocks,
        ...templateBlocks,
      ],
      StoryEditorTemplateApplyMode.metadataOnly => _state.document.blocks,
    };

    final templateBlockIds = templateBlocks.map((block) => block.id).toSet();
    final retainedOrigins = <String, StoryEditorTemplateBlockOrigin>{};
    for (final block in nextBlocks) {
      if (templateBlockIds.contains(block.id)) {
        continue;
      }
      final existingOrigin = _state.template.originFor(block.id);
      retainedOrigins[block.id] =
          existingOrigin ?? StoryEditorTemplateBlockOrigin.user;
    }
    if (mode != StoryEditorTemplateApplyMode.metadataOnly) {
      for (final block in templateBlocks) {
        retainedOrigins[block.id] = StoryEditorTemplateBlockOrigin.template;
      }
    }

    _changeGeneration++;
    final metadata = _metadataCopyWith(
      _state.metadata,
      format: format,
      category: category,
    );
    final document = _state.document.copyWith(blocks: nextBlocks);
    final template = StoryEditorTemplateState(
      appliedTemplateId: normalizedTemplateId,
      appliedTemplateVersion: normalizedTemplateVersion,
      blockOrigins: retainedOrigins,
    );
    _setState(
      _state.copyWith(
        metadata: metadata,
        document: document,
        selectedBlockId: templateBlocks.isNotEmpty
            ? templateBlocks.last.id
            : _state.selectedBlockId,
        publishValidation: _validationForCurrentScope(
          metadata,
          document,
          _state.mediaQueue.items,
        ),
        conflict: StoryEditorConflictState.none(),
        template: template,
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
  }

  Future<void> uploadCover({
    required String localMediaId,
    String? fileName,
    String? mimeType,
    int? byteSize,
    String? localPath,
    Uint8List? bytes,
  }) async {
    _recordHistory();
    final mediaId = _requiredTrim(localMediaId);
    final item = StoryEditorMediaQueueItem(
      localMediaId: mediaId,
      kind: StoryEditorMediaUploadKind.cover,
      status: _hasUploadSource(localPath: localPath, bytes: bytes)
          ? StoryEditorMediaStatus.uploading
          : StoryEditorMediaStatus.queued,
      attemptId: _nextMediaAttemptId(),
      fileName: _normalizeNullable(fileName),
      mimeType: _normalizeNullable(mimeType),
      byteSize: byteSize,
      localPath: _normalizeNullable(localPath),
      previewBytes: bytes,
    );
    final replacedCoverItems = _state.mediaQueue.items
        .where(
          (existing) =>
              existing.kind == StoryEditorMediaUploadKind.cover &&
              existing.status != StoryEditorMediaStatus.removed,
        )
        .toList(growable: false);
    _changeGeneration++;
    final items = [
      for (final existing in _state.mediaQueue.items)
        if (existing.kind == StoryEditorMediaUploadKind.cover &&
            existing.status != StoryEditorMediaStatus.removed)
          existing.copyWith(status: StoryEditorMediaStatus.removed)
        else
          existing,
      item,
    ];
    final metadata = _metadataCopyWith(_state.metadata, coverFileId: null);
    _setState(
      _state.copyWith(
        metadata: metadata,
        mediaQueue: StoryEditorMediaQueueState(items: items),
        publishValidation: _validationForCurrentScope(
          metadata,
          _state.document,
          items,
        ),
        conflict: StoryEditorConflictState.none(),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _releaseUnboundStoryMedia(_uploadedFileIdsFromQueue(replacedCoverItems));
    _scheduleAutosave();
    if (item.hasUploadSource) {
      await _uploadMediaItem(item);
    }
  }

  Future<void> addImage({
    required String localMediaId,
    String? fileName,
    String? mimeType,
    int? byteSize,
    String? localPath,
    Uint8List? bytes,
  }) async {
    _recordHistory();
    final mediaId = _requiredTrim(localMediaId);
    final blockId = 'image-$mediaId';
    final item = StoryEditorMediaQueueItem(
      localMediaId: mediaId,
      kind: StoryEditorMediaUploadKind.inlineImage,
      status: _hasUploadSource(localPath: localPath, bytes: bytes)
          ? StoryEditorMediaStatus.uploading
          : StoryEditorMediaStatus.queued,
      attemptId: _nextMediaAttemptId(),
      blockId: blockId,
      fileName: _normalizeNullable(fileName),
      mimeType: _normalizeNullable(mimeType),
      byteSize: byteSize,
      localPath: _normalizeNullable(localPath),
      previewBytes: bytes,
    );
    final document = _state.document.appendBlock(
      StoryBlock.image(
        id: blockId,
        image: StoryImagePayload(
          fileId: '',
          uploadState: StoryUploadState.uploading,
        ),
      ),
    );
    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        selectedBlockId: blockId,
        mediaQueue: StoryEditorMediaQueueState(
          items: [..._state.mediaQueue.items, item],
        ),
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          [..._state.mediaQueue.items, item],
        ),
        conflict: StoryEditorConflictState.none(),
        template: _state.template.withUserBlock(blockId),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
    if (item.hasUploadSource) {
      await _uploadMediaItem(item);
    }
  }

  Future<void> addGalleryUpload({
    required String localMediaId,
    String? fileName,
    String? mimeType,
    int? byteSize,
    String? localPath,
    Uint8List? bytes,
  }) async {
    await addGalleryUploads(
      localGalleryId: localMediaId,
      images: [
        StoryEditorGalleryUploadDraft(
          localMediaId: localMediaId,
          fileName: fileName,
          mimeType: mimeType,
          byteSize: byteSize,
          localPath: localPath,
          bytes: bytes,
        ),
      ],
    );
  }

  Future<void> addGalleryUploads({
    required String localGalleryId,
    required List<StoryEditorGalleryUploadDraft> images,
  }) async {
    if (images.isEmpty) {
      return;
    }
    _recordHistory();
    final galleryId = _requiredTrim(localGalleryId);
    final blockId = 'gallery-$galleryId';
    final items = <StoryEditorMediaQueueItem>[];
    final payloadImages = <StoryImagePayload>[];
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final mediaId = _requiredTrim(image.localMediaId);
      items.add(
        StoryEditorMediaQueueItem(
          localMediaId: mediaId,
          kind: StoryEditorMediaUploadKind.inlineImage,
          status:
              _hasUploadSource(localPath: image.localPath, bytes: image.bytes)
              ? StoryEditorMediaStatus.uploading
              : StoryEditorMediaStatus.queued,
          attemptId: _nextMediaAttemptId(),
          blockId: blockId,
          galleryImageIndex: index,
          fileName: _normalizeNullable(image.fileName),
          mimeType: _normalizeNullable(image.mimeType),
          byteSize: image.byteSize,
          localPath: _normalizeNullable(image.localPath),
          previewBytes: image.bytes,
        ),
      );
      payloadImages.add(
        StoryImagePayload(fileId: '', uploadState: StoryUploadState.uploading),
      );
    }
    final document = _state.document.appendBlock(
      StoryBlock.gallery(
        id: blockId,
        gallery: StoryGalleryPayload(images: payloadImages),
      ),
    );
    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        selectedBlockId: blockId,
        mediaQueue: StoryEditorMediaQueueState(
          items: [..._state.mediaQueue.items, ...items],
        ),
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          [..._state.mediaQueue.items, ...items],
        ),
        conflict: StoryEditorConflictState.none(),
        template: _state.template.withUserBlock(blockId),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
    await Future.wait(
      items
          .where((item) => item.hasUploadSource)
          .map(_uploadMediaItem)
          .toList(growable: false),
    );
  }

  void addGallery({
    required String blockId,
    required List<StoryImagePayload> images,
  }) {
    addBlock(
      StoryBlock.gallery(
        id: blockId,
        gallery: StoryGalleryPayload(images: images),
      ),
    );
  }

  Future<void> retryMediaUpload(String localMediaId) async {
    _recordHistory();
    final item = _mediaItemByLocalId(localMediaId);
    if (item == null || item.status != StoryEditorMediaStatus.failed) {
      return;
    }
    if (!item.hasUploadSource) {
      final failedItem = item.copyWith(
        status: StoryEditorMediaStatus.failed,
        errorCode: StoryEditorMediaErrorCode.missingSource,
      );
      _replaceMediaItem(
        failedItem,
        document: _documentWithMediaState(_state.document, failedItem),
      );
      return;
    }
    final nextItem = item.copyWith(
      status: StoryEditorMediaStatus.uploading,
      attemptId: _nextMediaAttemptId(),
      clearError: true,
    );
    _replaceMediaItem(
      nextItem,
      document: _documentWithMediaState(_state.document, nextItem),
    );
    if (nextItem.hasUploadSource) {
      await _uploadMediaItem(nextItem);
    }
  }

  void removeMediaUpload(String localMediaId) {
    _recordHistory();
    final mediaId = _requiredTrim(localMediaId);
    final removeBlockIds = _state.mediaQueue.items
        .where((item) => item.localMediaId == mediaId)
        .map((item) => item.blockId)
        .whereType<String>()
        .toSet();
    var document = _state.document;
    for (final blockId in removeBlockIds) {
      document = document.removeBlock(blockId);
    }
    final items = _state.mediaQueue.items
        .map(
          (item) =>
              item.localMediaId == mediaId ||
                  (item.blockId != null &&
                      removeBlockIds.contains(item.blockId))
              ? item.copyWith(status: StoryEditorMediaStatus.removed)
              : item,
        )
        .toList(growable: false);
    final removedItems = _state.mediaQueue.items
        .where(
          (item) =>
              item.localMediaId == mediaId ||
              (item.blockId != null && removeBlockIds.contains(item.blockId)),
        )
        .toList(growable: false);
    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        mediaQueue: StoryEditorMediaQueueState(items: items),
        selectedBlockId: removeBlockIds.contains(_state.selectedBlockId)
            ? null
            : _state.selectedBlockId,
        template: _state.template.withoutBlocks(removeBlockIds),
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          items,
        ),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _releaseUnboundStoryMedia(_uploadedFileIdsFromQueue(removedItems));
    _scheduleAutosave();
  }

  void removeGalleryImage({required String blockId, required int imageIndex}) {
    final normalizedBlockId = _requiredTrim(blockId);
    if (imageIndex < 0) {
      return;
    }
    final block = _state.document.blockById(normalizedBlockId);
    if (block == null || block.type != StoryBlockType.gallery) {
      return;
    }
    final images = block.gallery?.images ?? const <StoryImagePayload>[];
    if (imageIndex >= images.length) {
      return;
    }

    _recordHistory();
    final nextImages = [
      for (var index = 0; index < images.length; index++)
        if (index != imageIndex) images[index],
    ];
    final removeBlock = nextImages.isEmpty;
    final document = removeBlock
        ? _state.document.removeBlock(normalizedBlockId)
        : _state.document.replaceBlock(
            normalizedBlockId,
            block.copyWith(gallery: StoryGalleryPayload(images: nextImages)),
          );
    final removedItems = _state.mediaQueue.items
        .where((item) {
          if (item.blockId != normalizedBlockId) {
            return false;
          }
          return removeBlock || item.galleryImageIndex == imageIndex;
        })
        .toList(growable: false);
    final items = _state.mediaQueue.items
        .map((item) {
          if (item.blockId != normalizedBlockId) {
            return item;
          }
          if (removeBlock) {
            return item.copyWith(status: StoryEditorMediaStatus.removed);
          }
          final galleryImageIndex = item.galleryImageIndex;
          if (galleryImageIndex == imageIndex) {
            return item.copyWith(status: StoryEditorMediaStatus.removed);
          }
          if (galleryImageIndex != null && galleryImageIndex > imageIndex) {
            return item.copyWith(galleryImageIndex: galleryImageIndex - 1);
          }
          return item;
        })
        .toList(growable: false);

    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        mediaQueue: StoryEditorMediaQueueState(items: items),
        selectedBlockId:
            removeBlock && _state.selectedBlockId == normalizedBlockId
            ? null
            : _state.selectedBlockId,
        template: removeBlock
            ? _state.template.withoutBlocks([normalizedBlockId])
            : _state.template.withUserEditedBlock(normalizedBlockId),
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          items,
        ),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _releaseUnboundStoryMedia(_uploadedFileIdsFromQueue(removedItems));
    _scheduleAutosave();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final current = _StoryEditorHistoryEntry.fromState(_state);
    final previous = _undoStack.removeLast();
    _redoStack.add(current);
    _restoreHistory(previous, isDirty: _undoStack.isNotEmpty);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = _StoryEditorHistoryEntry.fromState(_state);
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _restoreHistory(next, isDirty: true);
  }

  Future<void> autosave() async {
    final snapshot = _snapshotState();
    await _saveRecoverySnapshot(snapshot);
    final storyId = snapshot.storyId;
    if (storyId == null) {
      if (_isCurrent(snapshot.context)) {
        _setState(
          _state.copyWith(
            saveStatus: const StoryEditorSaveStatus(
              phase: StoryEditorSavePhase.saved,
            ),
          ),
        );
      }
      return;
    }
    await _runRemoteSave(
      snapshot,
      () => _api.autosave(storyId, snapshot.writeRequest),
      clearRecoveryOnSuccess: true,
    );
  }

  Future<StoryVm?> saveDraft({bool showSuccessStatus = true}) async {
    final localValidation = _validateForDraft(_state.metadata, _state.document);
    if (!localValidation.isValid) {
      _setState(
        _state.copyWith(
          publishValidation: localValidation,
          validationScope: StoryEditorValidationScope.draft,
          saveStatus: const StoryEditorSaveStatus(
            phase: StoryEditorSavePhase.failed,
          ),
        ),
      );
      return null;
    }

    final snapshot = _snapshotState();
    _setState(
      _state.copyWith(
        validationScope: StoryEditorValidationScope.draft,
        saveStatus: const StoryEditorSaveStatus(
          phase: StoryEditorSavePhase.saving,
        ),
      ),
    );
    try {
      final storyId = snapshot.storyId;
      final story = storyId == null
          ? await _api.createDraft(snapshot.writeRequest)
          : await _api.update(storyId, snapshot.writeRequest);
      if (!_isCurrent(snapshot.context)) return null;
      _applySavedStory(
        story,
        clearLocalDraft: true,
        saveStatus: showSuccessStatus
            ? null
            : const StoryEditorSaveStatus(phase: StoryEditorSavePhase.saving),
      );
      try {
        await _bindSavedStoryMedia(story, snapshot);
      } catch (error) {
        if (!_isDisposed) {
          _handleMutationError(error);
          _setState(_state.copyWith(isDirty: true));
        }
        return null;
      }
      await _clearRecoveryFor(snapshot);
      return story;
    } catch (error) {
      if (_isCurrent(snapshot.context)) {
        _handleMutationError(error);
      }
      return null;
    }
  }

  Future<StoryVm?> publish({bool showSuccessStatus = true}) async {
    final localValidation = _validateForPublish(
      _state.metadata,
      _state.document,
      _state.mediaQueue.items,
    );
    if (!localValidation.isValid) {
      _setState(
        _state.copyWith(
          publishValidation: localValidation,
          validationScope: StoryEditorValidationScope.publish,
          saveStatus: const StoryEditorSaveStatus(
            phase: StoryEditorSavePhase.failed,
            message: 'Story is not ready to publish.',
          ),
        ),
      );
      return null;
    }

    final storyId = _state.storyId;
    if (storyId == null) {
      await saveDraft(showSuccessStatus: showSuccessStatus);
      if (_state.storyId == null ||
          _state.saveStatus.phase == StoryEditorSavePhase.failed) {
        return null;
      }
    }

    final remoteStoryId = _state.storyId;
    if (remoteStoryId == null) return null;
    final snapshot = _snapshotState();
    _setState(
      _state.copyWith(
        validationScope: StoryEditorValidationScope.publish,
        saveStatus: const StoryEditorSaveStatus(
          phase: StoryEditorSavePhase.saving,
        ),
      ),
    );
    try {
      final story = await _api.publish(remoteStoryId, snapshot.writeRequest);
      if (!_isCurrent(snapshot.context)) return null;
      _applySavedStory(
        story,
        saveStatus: showSuccessStatus
            ? null
            : const StoryEditorSaveStatus(phase: StoryEditorSavePhase.saving),
      );
      try {
        await _bindSavedStoryMedia(story, snapshot);
      } catch (error) {
        if (!_isDisposed) {
          _handleMutationError(error, publishValidation: true);
          _setState(_state.copyWith(isDirty: true));
        }
        return null;
      }
      await _clearRecoveryFor(snapshot);
      return story;
    } catch (error) {
      if (_isCurrent(snapshot.context)) {
        _handleMutationError(error, publishValidation: true);
      }
      return null;
    }
  }

  Future<void> archive() async {
    final storyId = _state.storyId;
    if (storyId == null) return;
    final snapshot = _snapshotState();
    _setState(
      _state.copyWith(
        saveStatus: const StoryEditorSaveStatus(
          phase: StoryEditorSavePhase.saving,
        ),
      ),
    );
    try {
      final story = await _api.archive(storyId, revision: snapshot.revision);
      if (!_isCurrent(snapshot.context)) return;
      _applySavedStory(story);
    } catch (error) {
      if (_isCurrent(snapshot.context)) {
        _handleMutationError(error);
      }
    }
  }

  Future<bool> loadRecoverySnapshot() async {
    final context = _operationContext();
    final snapshot = await _recovery.load(
      userId: context.userId,
      storyId: context.storyId,
      localDraftId: context.localDraftId,
    );
    if (!_matchesIdentity(context) ||
        !_snapshotMatchesContext(snapshot, context)) {
      return false;
    }
    _setState(
      _state.copyWith(recovery: StoryEditorRecoveryState(snapshot: snapshot)),
    );
    return snapshot != null;
  }

  Future<void> recoverLocalSnapshot() async {
    final context = _operationContext();
    final snapshot =
        _state.recovery.snapshot ??
        await _recovery.load(
          userId: context.userId,
          storyId: context.storyId,
          localDraftId: context.localDraftId,
        );
    if (!_matchesIdentity(context) ||
        !_snapshotMatchesContext(snapshot, context)) {
      return;
    }
    final mediaItems = snapshot!.pendingMediaReferences
        .map(_mediaItemFromRecoveryReference)
        .toList(growable: false);
    var document = snapshot.document;
    for (final item in mediaItems) {
      document = _documentWithMediaState(document, item);
    }
    _changeGeneration++;
    _setState(
      _state.copyWith(
        metadata: snapshot.metadata,
        document: document,
        revision: snapshot.lastRemoteRevision,
        mediaQueue: StoryEditorMediaQueueState(items: mediaItems),
        recovery: StoryEditorRecoveryState(snapshot: snapshot),
        publishValidation: _validateForPublish(
          snapshot.metadata,
          document,
          mediaItems,
        ),
      ),
    );
  }

  Future<void> discardLocalSnapshot() async {
    await _clearRecovery();
    _setState(_state.copyWith(recovery: const StoryEditorRecoveryState()));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _releaseUnboundStoryMedia(
      _uploadedFileIdsFromQueue(_state.mediaQueue.items),
    );
    _autosave.dispose();
    super.dispose();
  }

  void _recordHistory() {
    final current = _StoryEditorHistoryEntry.fromState(_state);
    if (_undoStack.isEmpty || !_undoStack.last.hasSameContent(current)) {
      _undoStack.add(current);
    }
    _redoStack.clear();
  }

  void _restoreHistory(
    _StoryEditorHistoryEntry entry, {
    required bool isDirty,
  }) {
    _changeGeneration++;
    _setState(
      _state.copyWith(
        metadata: entry.metadata,
        document: entry.document,
        selectedBlockId: entry.selectedBlockId,
        mediaQueue: entry.mediaQueue,
        template: entry.template,
        publishValidation: _validationForCurrentScope(
          entry.metadata,
          entry.document,
          entry.mediaQueue.items,
        ),
        conflict: StoryEditorConflictState.none(),
        isDirty: isDirty,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
  }

  void _clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _changeMetadata(
    StoryEditorMetadataDraft metadata, {
    StoryEditorTemplateState? template,
  }) {
    _changeGeneration++;
    _setState(
      _state.copyWith(
        metadata: metadata,
        template: template ?? _state.template,
        publishValidation: _validationForCurrentScope(
          metadata,
          _state.document,
          _state.mediaQueue.items,
        ),
        conflict: StoryEditorConflictState.none(),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
  }

  void _changeDocument(
    StoryDocument document, {
    String? selectedBlockId,
    bool selectedBlockIdChanged = true,
    StoryEditorTemplateState? template,
  }) {
    _changeGeneration++;
    _setState(
      _state.copyWith(
        document: document,
        selectedBlockId: selectedBlockIdChanged
            ? selectedBlockId
            : _state.selectedBlockId,
        publishValidation: _validationForCurrentScope(
          _state.metadata,
          document,
          _state.mediaQueue.items,
        ),
        conflict: StoryEditorConflictState.none(),
        template: template ?? _state.template,
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    final snapshot = _snapshotState();
    final work = StoryEditorAutosaveWork(
      storyId: snapshot.storyId,
      saveLocalSnapshot: () => _saveRecoverySnapshot(snapshot),
      saveRemote: () async {
        final storyId = snapshot.storyId;
        if (storyId == null) return;
        await _runRemoteSave(
          snapshot,
          () => _api.autosave(storyId, snapshot.writeRequest),
          clearRecoveryOnSuccess: true,
        );
      },
      isTransientFailure: (error) =>
          error is StoryEditorApiException &&
          (error.statusCode == null || error.statusCode! >= 500),
    );
    _autosave.recordMeaningfulEdit(work);
  }

  Future<bool> _saveRecoverySnapshot(
    _StoryEditorSnapshot editorSnapshot,
  ) async {
    final recoverySnapshot = StoryEditorRecoverySnapshot(
      userId: editorSnapshot.userId,
      storyId: editorSnapshot.storyId,
      localDraftId: editorSnapshot.localDraftId,
      metadata: editorSnapshot.metadata,
      document: editorSnapshot.document,
      pendingMediaReferences: editorSnapshot.mediaQueue.items
          .where((item) => item.blocksPublish)
          .map(_mediaReferenceFromQueueItem)
          .toList(growable: false),
      lastRemoteRevision: editorSnapshot.revision,
      lastLocalEditAt: _now(),
    );
    final saved = await _recovery.save(recoverySnapshot);
    if (saved && _isCurrent(editorSnapshot.context)) {
      _setState(
        _state.copyWith(
          recovery: StoryEditorRecoveryState(snapshot: recoverySnapshot),
        ),
      );
    }
    return saved;
  }

  Future<void> _runRemoteSave(
    _StoryEditorSnapshot snapshot,
    Future<StoryVm> Function() save, {
    bool clearRecoveryOnSuccess = false,
  }) async {
    try {
      final story = await save();
      if (!_isCurrent(snapshot.context)) return;
      _applySavedStory(story);
      await _bindSavedStoryMedia(story, snapshot);
      if (clearRecoveryOnSuccess) {
        await _clearRecoveryFor(snapshot);
      }
    } catch (error) {
      if (_isCurrent(snapshot.context)) {
        _handleMutationError(error);
      }
      rethrow;
    }
  }

  void _applySavedStory(
    StoryVm story, {
    bool clearLocalDraft = false,
    StoryEditorSaveStatus? saveStatus,
  }) {
    final metadata = _metadataFromStory(story, fallback: _state.metadata);
    _setState(
      _state.copyWith(
        mode: StoryEditorMode.edit,
        storyId: _normalizeNullable(story.id),
        localDraftId: clearLocalDraft ? null : _state.localDraftId,
        metadata: metadata,
        revision: story.revision,
        saveStatus:
            saveStatus ??
            const StoryEditorSaveStatus(phase: StoryEditorSavePhase.saved),
        validationScope: saveStatus?.phase == StoryEditorSavePhase.saving
            ? _state.validationScope
            : StoryEditorValidationScope.none,
        publishValidation: _validateForPublish(
          metadata,
          _state.document,
          _state.mediaQueue.items,
        ),
        conflict: StoryEditorConflictState.none(),
        isDirty: false,
        canUndo: false,
        canRedo: false,
      ),
    );
    _clearHistory();
  }

  Future<void> _bindSavedStoryMedia(
    StoryVm story,
    _StoryEditorSnapshot snapshot,
  ) async {
    final storyId = _normalizeNullable(story.id);
    if (storyId == null) {
      return;
    }
    final coverFileId = _normalizeNullable(snapshot.writeRequest.coverFileId);
    final contentFileIds = _normalizeFileIds(
      _storyDocumentFileIds(snapshot.writeRequest.document),
    ).where((fileId) => fileId != coverFileId).toList(growable: false);
    if (coverFileId == null && contentFileIds.isEmpty) {
      return;
    }

    await _mediaLifecycle.bindStoryMedia(
      storyId: storyId,
      coverFileId: coverFileId,
      contentFileIds: contentFileIds,
    );
    _boundStoryFileIds.addAll(
      _normalizeFileIds([coverFileId, ...contentFileIds]),
    );
  }

  void _releaseUnboundStoryMedia(Iterable<String> fileIds) {
    final unboundFileIds = _normalizeFileIds(fileIds)
        .where((fileId) => !_boundStoryFileIds.contains(fileId))
        .toList(growable: false);
    if (unboundFileIds.isEmpty) {
      return;
    }
    unawaited(_mediaLifecycle.releaseStoryMedia(unboundFileIds));
  }

  Future<void> _clearRecoveryFor(_StoryEditorSnapshot snapshot) async {
    await _recovery.clear(
      userId: snapshot.userId,
      storyId: snapshot.storyId,
      localDraftId: snapshot.localDraftId,
    );
    if (_isCurrent(snapshot.context)) {
      _setState(_state.copyWith(recovery: const StoryEditorRecoveryState()));
    }
  }

  Future<void> _clearRecovery({String? storyId, String? localDraftId}) async {
    await _recovery.clear(
      userId: _state.userId,
      storyId: storyId ?? _state.storyId,
      localDraftId: localDraftId ?? _state.localDraftId,
    );
  }

  StoryEditorWriteRequest _writeRequestFor(StoryEditorState state) {
    final metadata = state.metadata;
    return StoryEditorWriteRequest(
      title: metadata.title,
      format: metadata.format,
      category: metadata.category,
      status: metadata.status,
      document: _documentForWrite(state),
      revision: state.revision,
      coverFileId: metadata.coverFileId,
      placeName: metadata.placeName,
      placeCountryCode: metadata.placeCountryCode,
      placeCityId: metadata.placeCityId,
      tags: metadata.tags,
      metadata: metadata.metadata,
    );
  }

  StoryEditorPublishValidationSummary _validationForCurrentScope(
    StoryEditorMetadataDraft metadata,
    StoryDocument document,
    List<StoryEditorMediaQueueItem> mediaItems,
  ) {
    return switch (_state.validationScope) {
      StoryEditorValidationScope.draft => _validateForDraft(metadata, document),
      StoryEditorValidationScope.publish || StoryEditorValidationScope.none =>
        _validateForPublish(metadata, document, mediaItems),
    };
  }

  void _handleMutationError(Object error, {bool publishValidation = false}) {
    if (_isConflict(error)) {
      final apiError = error as StoryEditorApiException;
      _setState(
        _state.copyWith(
          saveStatus: StoryEditorSaveStatus(
            phase: StoryEditorSavePhase.conflict,
            message: apiError.message,
            error: error,
          ),
          conflict: StoryEditorConflictState(
            message: apiError.message,
            fieldErrors: apiError.fieldErrors,
          ),
        ),
      );
      return;
    }

    if (publishValidation && error is StoryEditorApiException) {
      _setState(
        _state.copyWith(
          saveStatus: StoryEditorSaveStatus(
            phase: StoryEditorSavePhase.failed,
            message: error.message,
            error: error,
          ),
          publishValidation: StoryEditorPublishValidationSummary(
            errors: error.fieldErrors,
          ),
          validationScope: StoryEditorValidationScope.publish,
        ),
      );
      return;
    }

    final message = error is StoryEditorApiException
        ? error.message
        : error.toString();
    _setState(
      _state.copyWith(
        saveStatus: StoryEditorSaveStatus(
          phase: StoryEditorSavePhase.failed,
          message: message,
          error: error,
        ),
      ),
    );
  }

  bool _isConflict(Object error) {
    return error is StoryEditorApiException &&
        (error.statusCode == 409 ||
            error.fieldErrors.any((fieldError) {
              return fieldError.code == 'revision_conflict';
            }));
  }

  Future<void> _uploadMediaItem(StoryEditorMediaQueueItem item) async {
    try {
      final uploaded = await _mediaUpload.upload(
        StoryEditorMediaUploadRequest(
          localMediaId: item.localMediaId,
          kind: item.kind,
          fileName: item.fileName,
          mimeType: item.mimeType,
          byteSize: item.byteSize,
          localPath: item.localPath,
          bytes: item.previewBytes,
        ),
      );
      final current = _mediaItemByLocalId(item.localMediaId);
      if (!_isCurrentMediaAttempt(current, item)) {
        _releaseUnboundStoryMedia([uploaded.fileId]);
        return;
      }
      final currentItem = current!;
      final uploadedItem = currentItem.copyWith(
        status: StoryEditorMediaStatus.uploaded,
        fileId: _requiredTrim(uploaded.fileId),
        clearError: true,
      );
      final metadata = currentItem.kind == StoryEditorMediaUploadKind.cover
          ? _metadataCopyWith(_state.metadata, coverFileId: uploadedItem.fileId)
          : _state.metadata;
      _replaceMediaItem(
        uploadedItem,
        metadata: metadata,
        document: _documentWithMediaState(_state.document, uploadedItem),
      );
    } catch (error) {
      final current = _mediaItemByLocalId(item.localMediaId);
      if (!_isCurrentMediaAttempt(current, item)) {
        return;
      }
      final failedItem = current!.copyWith(
        status: StoryEditorMediaStatus.failed,
        errorCode: _mediaUploadErrorCode(error),
      );
      _replaceMediaItem(
        failedItem,
        document: _documentWithMediaState(_state.document, failedItem),
      );
    }
  }

  StoryEditorMediaQueueItem? _mediaItemByLocalId(String localMediaId) {
    final mediaId = _requiredTrim(localMediaId);
    for (final item in _state.mediaQueue.items) {
      if (item.localMediaId == mediaId) {
        return item;
      }
    }
    return null;
  }

  int _nextMediaAttemptId() {
    _mediaAttemptSequence += 1;
    return _mediaAttemptSequence;
  }

  bool _isCurrentMediaAttempt(
    StoryEditorMediaQueueItem? current,
    StoryEditorMediaQueueItem attempted,
  ) {
    return current != null &&
        current.status != StoryEditorMediaStatus.removed &&
        current.attemptId == attempted.attemptId;
  }

  void _replaceMediaItem(
    StoryEditorMediaQueueItem replacement, {
    StoryEditorMetadataDraft? metadata,
    StoryDocument? document,
  }) {
    final items = _state.mediaQueue.items
        .map(
          (item) => item.localMediaId == replacement.localMediaId
              ? replacement
              : item,
        )
        .toList(growable: false);
    _changeGeneration++;
    final nextMetadata = metadata ?? _state.metadata;
    final nextDocument = document ?? _state.document;
    _setState(
      _state.copyWith(
        metadata: nextMetadata,
        document: nextDocument,
        mediaQueue: StoryEditorMediaQueueState(items: items),
        publishValidation: _validationForCurrentScope(
          nextMetadata,
          nextDocument,
          items,
        ),
        isDirty: true,
        canUndo: _undoStack.isNotEmpty,
        canRedo: _redoStack.isNotEmpty,
      ),
    );
    _scheduleAutosave();
  }

  void _setState(StoryEditorState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  _StoryEditorSnapshot _snapshotState() {
    final state = _state;
    return _StoryEditorSnapshot(
      context: _operationContext(),
      userId: state.userId,
      storyId: state.storyId,
      localDraftId: state.localDraftId,
      metadata: state.metadata,
      document: state.document,
      revision: state.revision,
      mediaQueue: state.mediaQueue,
      writeRequest: _writeRequestFor(state),
    );
  }

  _EditorOperationContext _operationContext() {
    return _EditorOperationContext(
      generation: _changeGeneration,
      userId: _state.userId,
      storyId: _state.storyId,
      localDraftId: _state.localDraftId,
    );
  }

  bool _isCurrent(_EditorOperationContext context) {
    return !_isDisposed &&
        context.generation == _changeGeneration &&
        _matchesIdentity(context);
  }

  bool _matchesIdentity(_EditorOperationContext context) {
    return context.userId == _state.userId &&
        context.storyId == _state.storyId &&
        context.localDraftId == _state.localDraftId;
  }
}

class _StoryEditorSnapshot {
  const _StoryEditorSnapshot({
    required this.context,
    required this.userId,
    required this.storyId,
    required this.localDraftId,
    required this.metadata,
    required this.document,
    required this.revision,
    required this.mediaQueue,
    required this.writeRequest,
  });

  final _EditorOperationContext context;
  final String userId;
  final String? storyId;
  final String? localDraftId;
  final StoryEditorMetadataDraft metadata;
  final StoryDocument document;
  final int? revision;
  final StoryEditorMediaQueueState mediaQueue;
  final StoryEditorWriteRequest writeRequest;
}

class _EditorOperationContext {
  const _EditorOperationContext({
    required this.generation,
    required this.userId,
    required this.storyId,
    required this.localDraftId,
  });

  final int generation;
  final String userId;
  final String? storyId;
  final String? localDraftId;
}

class _StoryEditorHistoryEntry {
  _StoryEditorHistoryEntry({
    required this.metadata,
    required this.document,
    required this.selectedBlockId,
    required this.mediaQueue,
    required this.template,
  });

  factory _StoryEditorHistoryEntry.fromState(StoryEditorState state) {
    return _StoryEditorHistoryEntry(
      metadata: state.metadata,
      document: state.document,
      selectedBlockId: state.selectedBlockId,
      mediaQueue: state.mediaQueue,
      template: state.template,
    );
  }

  final StoryEditorMetadataDraft metadata;
  final StoryDocument document;
  final String? selectedBlockId;
  final StoryEditorMediaQueueState mediaQueue;
  final StoryEditorTemplateState template;

  bool hasSameContent(_StoryEditorHistoryEntry other) {
    return identical(metadata, other.metadata) &&
        identical(document, other.document) &&
        selectedBlockId == other.selectedBlockId &&
        identical(mediaQueue, other.mediaQueue) &&
        identical(template, other.template);
  }
}

StoryEditorMetadataDraft _metadataFromStory(
  StoryVm story, {
  StoryEditorMetadataDraft? fallback,
}) {
  return StoryEditorMetadataDraft(
    title: story.title.isNotEmpty ? story.title : fallback?.title ?? '',
    format: story.format.isNotEmpty
        ? story.format
        : fallback?.format ?? 'STORY',
    category: story.category.isNotEmpty
        ? story.category
        : fallback?.category ?? 'JOURNAL',
    status: story.status.isNotEmpty
        ? story.status
        : fallback?.status ?? 'DRAFT',
    coverFileId: _normalizeNullable(story.coverFileId) ?? fallback?.coverFileId,
    placeName: _normalizeNullable(story.placeName) ?? fallback?.placeName,
    placeCountryCode:
        _normalizeNullable(story.placeCountryCode) ??
        fallback?.placeCountryCode,
    placeCityId: _normalizeNullable(story.placeCityId) ?? fallback?.placeCityId,
    tags: story.tags.isNotEmpty ? story.tags : fallback?.tags ?? const [],
    metadata: fallback?.metadata ?? const {},
  );
}

StoryEditorMetadataDraft _metadataCopyWith(
  StoryEditorMetadataDraft metadata, {
  String? title,
  String? format,
  String? category,
  String? status,
  Object? coverFileId = _sentinel,
  Object? placeName = _sentinel,
  Object? placeCountryCode = _sentinel,
  Object? placeCityId = _sentinel,
  List<String>? tags,
  Map<String, Object?>? extraMetadata,
}) {
  return StoryEditorMetadataDraft(
    title: title ?? metadata.title,
    format: format ?? metadata.format,
    category: category ?? metadata.category,
    status: status ?? metadata.status,
    coverFileId: identical(coverFileId, _sentinel)
        ? metadata.coverFileId
        : coverFileId as String?,
    placeName: identical(placeName, _sentinel)
        ? metadata.placeName
        : placeName as String?,
    placeCountryCode: identical(placeCountryCode, _sentinel)
        ? metadata.placeCountryCode
        : placeCountryCode as String?,
    placeCityId: identical(placeCityId, _sentinel)
        ? metadata.placeCityId
        : placeCityId as String?,
    tags: tags ?? metadata.tags,
    metadata: extraMetadata ?? metadata.metadata,
  );
}

StoryDocument _documentFromStory(StoryVm story) {
  if (story.contentBlocks.isEmpty) {
    return StoryDocument();
  }
  return StoryDocument(
    version: story.contentSchemaVersion,
    blocks: story.contentBlocks.map(_blockFromJson).toList(growable: false),
  );
}

StoryDocument _documentForWrite(StoryEditorState state) {
  final pendingBlockIds = state.mediaQueue.items
      .where((item) => item.blocksPublish)
      .map((item) => item.blockId)
      .whereType<String>()
      .toSet();
  if (pendingBlockIds.isEmpty) {
    return state.document;
  }

  return state.document.copyWith(
    blocks: state.document.blocks
        .map((block) {
          if (!pendingBlockIds.contains(block.id)) {
            return block;
          }
          if (block.type == StoryBlockType.image) {
            return block.copyWith(
              image: (block.image ?? const StoryImagePayload(fileId: ''))
                  .copyWith(
                    fileId: '',
                    uploadState: StoryUploadState.uploading,
                  ),
            );
          }
          if (block.type == StoryBlockType.gallery) {
            return block.copyWith(
              gallery: StoryGalleryPayload(
                images: (block.gallery?.images ?? const [])
                    .map(
                      (image) => image.copyWith(
                        fileId: '',
                        uploadState: StoryUploadState.uploading,
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          }
          return block;
        })
        .toList(growable: false),
  );
}

List<String> _storyDocumentFileIds(StoryDocument document) {
  final fileIds = <String>[];
  for (final block in document.blocks) {
    if (block.type == StoryBlockType.image) {
      final fileId = _normalizeNullable(block.image?.fileId);
      if (fileId != null) {
        fileIds.add(fileId);
      }
      continue;
    }
    if (block.type == StoryBlockType.gallery) {
      for (final image
          in block.gallery?.images ?? const <StoryImagePayload>[]) {
        final fileId = _normalizeNullable(image.fileId);
        if (fileId != null) {
          fileIds.add(fileId);
        }
      }
    }
  }
  return _normalizeFileIds(fileIds);
}

List<String> _uploadedFileIdsFromQueue(
  Iterable<StoryEditorMediaQueueItem> items,
) {
  return _normalizeFileIds(
    items
        .where((item) => item.status == StoryEditorMediaStatus.uploaded)
        .map((item) => item.fileId),
  );
}

StoryBlock _blockFromJson(Map<String, dynamic> json) {
  final id = json['id']?.toString() ?? '';
  final text = json['text']?.toString() ?? '';
  final marks = _marksFromJson(json['marks']);
  return switch (json['type']?.toString()) {
    'heading' => StoryBlock.heading(
      id: id,
      text: text,
      level: int.tryParse(json['level']?.toString() ?? '') ?? 1,
      marks: marks,
    ),
    'bulleted_list' => StoryBlock.bulletedList(
      id: id,
      text: _listTextFromJson(json, fallback: text),
      marks: marks,
    ),
    'numbered_list' => StoryBlock.numberedList(
      id: id,
      text: _listTextFromJson(json, fallback: text),
      marks: marks,
    ),
    'quote' => StoryBlock.quote(id: id, text: text, marks: marks),
    'callout' => StoryBlock.callout(id: id, text: text, marks: marks),
    'image' => StoryBlock.image(
      id: id,
      image: _imageFromJson(json['image'] ?? json),
    ),
    'gallery' => StoryBlock.gallery(
      id: id,
      gallery: StoryGalleryPayload(
        images: _galleryImagesFromJson(json['gallery'] ?? json),
      ),
    ),
    'divider' => StoryBlock.divider(id: id),
    'place_reference' => StoryBlock.placeReference(
      id: id,
      place: _placeFromJson(json['place'] ?? json),
    ),
    _ => StoryBlock.paragraph(id: id, text: text, marks: marks),
  };
}

String _listTextFromJson(
  Map<String, dynamic> json, {
  required String fallback,
}) {
  final items = json['items'];
  if (items is! List) {
    return fallback;
  }
  return items
      .whereType<Map>()
      .map((item) => item['text']?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .join('\n');
}

List<StoryInlineMark> _marksFromJson(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((mark) {
        final start = int.tryParse(mark['start']?.toString() ?? '') ?? 0;
        final end = int.tryParse(mark['end']?.toString() ?? '') ?? 0;
        return switch (mark['type']?.toString()) {
          'bold' => StoryInlineMark.bold(start: start, end: end),
          'italic' => StoryInlineMark.italic(start: start, end: end),
          'underline' => StoryInlineMark.underline(start: start, end: end),
          'strikethrough' => StoryInlineMark.strikethrough(
            start: start,
            end: end,
          ),
          'link' => StoryInlineMark.link(
            start: start,
            end: end,
            url: mark['url']?.toString() ?? '',
          ),
          _ => StoryInlineMark.bold(start: start, end: end),
        };
      })
      .toList(growable: false);
}

StoryImagePayload _imageFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  return StoryImagePayload(
    fileId: json['fileId']?.toString() ?? '',
    uploadState: StoryUploadState.complete,
  );
}

List<StoryImagePayload> _galleryImagesFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  final images = json['images'];
  if (images is! List) return const [];
  return images.map(_imageFromJson).toList(growable: false);
}

StoryPlaceReference _placeFromJson(Object? raw) {
  final json = raw is Map ? raw : const <String, Object?>{};
  return StoryPlaceReference(
    name: json['name']?.toString() ?? json['placeName']?.toString() ?? '',
    placeId: _normalizeNullable(json['placeId']?.toString()),
    countryCode: _normalizeNullable(
      json['countryCode']?.toString() ?? json['placeCountryCode']?.toString(),
    ),
    cityId: _normalizeNullable(
      json['cityId']?.toString() ?? json['placeCityId']?.toString(),
    ),
    latitude: double.tryParse(json['latitude']?.toString() ?? ''),
    longitude: double.tryParse(json['longitude']?.toString() ?? ''),
  );
}

StoryEditorPublishValidationSummary _validateForDraft(
  StoryEditorMetadataDraft metadata,
  StoryDocument document,
) {
  final errors = <StoryEditorFieldError>[];
  final hasTitle = metadata.title.trim().isNotEmpty;
  final hasContent = _hasDraftSaveableContent(document);
  if (!hasTitle && !hasContent) {
    errors.add(
      const StoryEditorFieldError(
        field: 'title',
        code: 'draft_required',
        message: 'Add a title or at least one story block to save a draft.',
      ),
    );
    errors.add(
      const StoryEditorFieldError(
        field: 'contentBlocks',
        code: 'draft_required',
        message: 'Add a title or at least one story block to save a draft.',
      ),
    );
  }
  errors.addAll(
    document.validateForDraft().issues.map((issue) {
      return StoryEditorFieldError(
        field: 'contentBlocks',
        code: issue.code,
        message: issue.message,
        blockId: issue.blockId,
      );
    }),
  );
  return StoryEditorPublishValidationSummary(errors: errors);
}

StoryEditorPublishValidationSummary _validateForPublish(
  StoryEditorMetadataDraft metadata,
  StoryDocument document,
  List<StoryEditorMediaQueueItem> mediaItems,
) {
  final errors = <StoryEditorFieldError>[];
  if (metadata.title.trim().isEmpty) {
    errors.add(
      const StoryEditorFieldError(
        field: 'title',
        code: 'title_required',
        message: 'Story title is required.',
      ),
    );
  }
  if (metadata.format.trim().isEmpty) {
    errors.add(
      const StoryEditorFieldError(
        field: 'format',
        code: 'format_required',
        message: 'Story format is required.',
      ),
    );
  }
  if (metadata.category.trim().isEmpty) {
    errors.add(
      const StoryEditorFieldError(
        field: 'category',
        code: 'category_required',
        message: 'Story category is required.',
      ),
    );
  }
  if ((metadata.coverFileId ?? '').trim().isEmpty) {
    errors.add(
      const StoryEditorFieldError(
        field: 'coverFileId',
        code: 'cover_required',
        message: 'Story cover is required.',
      ),
    );
  }
  final hasPlace =
      (metadata.placeName ?? '').trim().isNotEmpty ||
      (metadata.placeCityId ?? '').trim().isNotEmpty;
  if (!hasPlace) {
    errors.add(
      const StoryEditorFieldError(
        field: 'place',
        code: 'place_required',
        message: 'Story place is required.',
      ),
    );
  }
  if ((metadata.placeCountryCode ?? '').trim().isEmpty) {
    errors.add(
      const StoryEditorFieldError(
        field: 'country',
        code: 'country_required',
        message: 'Story country is required.',
      ),
    );
  }
  errors.addAll(
    document.validateForPublish().issues.map((issue) {
      return StoryEditorFieldError(
        field: 'contentBlocks',
        code: issue.code,
        message: issue.message,
        blockId: issue.blockId,
      );
    }),
  );
  if (mediaItems.any((item) => item.blocksPublish)) {
    errors.add(
      const StoryEditorFieldError(
        field: 'mediaQueue',
        code: 'media_upload_pending',
        message: 'Pending media uploads must complete before publishing.',
      ),
    );
  }
  return StoryEditorPublishValidationSummary(errors: errors);
}

bool _hasDraftSaveableContent(StoryDocument document) {
  for (final block in document.blocks) {
    if (block.isTextBlock && (block.text ?? '').trim().isNotEmpty) {
      return true;
    }
    if (block.type == StoryBlockType.image &&
        (block.image?.isUploadComplete ?? false)) {
      return true;
    }
    if (block.type == StoryBlockType.gallery &&
        (block.gallery?.images.any((image) => image.isUploadComplete) ??
            false)) {
      return true;
    }
    if (block.type == StoryBlockType.placeReference &&
        (block.place?.isMeaningful ?? false)) {
      return true;
    }
  }
  return false;
}

bool _snapshotMatchesContext(
  StoryEditorRecoverySnapshot? snapshot,
  _EditorOperationContext context,
) {
  if (snapshot == null) return false;
  return snapshot.userId == context.userId &&
      snapshot.storyId == context.storyId &&
      snapshot.localDraftId == context.localDraftId;
}

StoryEditorPendingMediaReference _mediaReferenceFromQueueItem(
  StoryEditorMediaQueueItem item,
) {
  return StoryEditorPendingMediaReference(
    localMediaId: item.localMediaId,
    kind: item.kind.name,
    status: item.status.name,
    blockId: item.blockId,
    galleryImageIndex: item.galleryImageIndex,
    fileName: item.fileName,
    mimeType: item.mimeType,
    byteSize: item.byteSize,
    localPath: item.localPath,
    previewBytes:
        item.previewBytes != null &&
            item.previewBytes!.length <= _maxRecoverablePreviewBytes
        ? item.previewBytes
        : null,
  );
}

StoryEditorMediaQueueItem _mediaItemFromRecoveryReference(
  StoryEditorPendingMediaReference reference,
) {
  final kind = _mediaKindFromRecovery(reference.kind);
  var status = _mediaStatusFromRecovery(reference.status);
  final hasSource =
      reference.previewBytes != null ||
      _normalizeNullable(reference.localPath) != null;
  var errorCode = status == StoryEditorMediaStatus.failed
      ? StoryEditorMediaErrorCode.retryUpload
      : null;
  if (status == StoryEditorMediaStatus.queued ||
      status == StoryEditorMediaStatus.uploading) {
    status = StoryEditorMediaStatus.failed;
    errorCode = hasSource
        ? StoryEditorMediaErrorCode.uploadInterrupted
        : StoryEditorMediaErrorCode.missingSource;
  }
  return StoryEditorMediaQueueItem(
    localMediaId: reference.localMediaId,
    kind: kind,
    blockId: reference.blockId,
    galleryImageIndex: reference.galleryImageIndex,
    fileName: reference.fileName,
    mimeType: reference.mimeType,
    byteSize: reference.byteSize,
    localPath: reference.localPath,
    previewBytes: reference.previewBytes,
    status: status,
    errorCode: errorCode,
  );
}

StoryEditorMediaUploadKind _mediaKindFromRecovery(String? value) {
  return StoryEditorMediaUploadKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => StoryEditorMediaUploadKind.inlineImage,
  );
}

StoryEditorMediaStatus _mediaStatusFromRecovery(String? value) {
  return StoryEditorMediaStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => StoryEditorMediaStatus.failed,
  );
}

StoryDocument _documentWithMediaState(
  StoryDocument document,
  StoryEditorMediaQueueItem item,
) {
  final blockId = item.blockId;
  if (blockId == null) return document;
  return document.updateBlock(blockId, (block) {
    final uploadState = switch (item.status) {
      StoryEditorMediaStatus.uploaded => StoryUploadState.complete,
      StoryEditorMediaStatus.failed => StoryUploadState.failed,
      StoryEditorMediaStatus.queued ||
      StoryEditorMediaStatus.uploading ||
      StoryEditorMediaStatus.removed => StoryUploadState.uploading,
    };
    final fileId = item.status == StoryEditorMediaStatus.uploaded
        ? item.fileId ?? ''
        : '';
    if (block.type == StoryBlockType.image) {
      return block.copyWith(
        image: (block.image ?? const StoryImagePayload(fileId: '')).copyWith(
          fileId: fileId,
          uploadState: uploadState,
        ),
      );
    }
    if (block.type == StoryBlockType.gallery) {
      final images = block.gallery?.images ?? const <StoryImagePayload>[];
      final galleryImageIndex = item.galleryImageIndex;
      if (galleryImageIndex != null &&
          galleryImageIndex >= 0 &&
          galleryImageIndex < images.length) {
        return block.copyWith(
          gallery: StoryGalleryPayload(
            images: [
              for (var index = 0; index < images.length; index++)
                index == galleryImageIndex
                    ? images[index].copyWith(
                        fileId: fileId,
                        uploadState: uploadState,
                      )
                    : images[index],
            ],
          ),
        );
      }
      return block.copyWith(
        gallery: StoryGalleryPayload(
          images: images
              .map(
                (image) =>
                    image.copyWith(fileId: fileId, uploadState: uploadState),
              )
              .toList(growable: false),
        ),
      );
    }
    return block;
  });
}

bool _hasUploadSource({String? localPath, Uint8List? bytes}) {
  return bytes != null || _normalizeNullable(localPath) != null;
}

List<String> _normalizeFileIds(Iterable<String?> fileIds) {
  final seen = <String>{};
  final normalized = <String>[];
  for (final fileId in fileIds) {
    final value = _normalizeNullable(fileId);
    if (value == null || !seen.add(value)) {
      continue;
    }
    normalized.add(value);
  }
  return normalized;
}

StoryEditorMediaErrorCode _mediaUploadErrorCode(Object _) {
  return StoryEditorMediaErrorCode.uploadFailed;
}

String _defaultLocalDraftId() {
  return 'local-${DateTime.now().microsecondsSinceEpoch}';
}

String _requiredTrim(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'value', 'Value is required.');
  }
  return normalized;
}

String? _normalizeNullable(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}

const Object _sentinel = Object();
