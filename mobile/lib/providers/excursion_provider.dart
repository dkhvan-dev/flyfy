import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/excursion_api.dart';
import '../features/excursions/models/create_excursion_booking_request.dart';
import '../features/excursions/models/create_excursion_request.dart';
import '../features/excursions/models/excursion_vm.dart';

enum ExcursionActionState { idle, loading, success, error }

enum ExcursionListState { initial, loading, success, error }

enum ExcursionDetailState { initial, loading, success, error }

class ExcursionProvider extends ChangeNotifier {
  ExcursionProvider({ExcursionApi? excursionApi})
      : _excursionApi = excursionApi ?? ExcursionApi();

  static const _marketplaceRefreshAttempts = 3;
  static const _marketplaceRefreshRetryDelay = Duration(milliseconds: 150);

  final ExcursionApi _excursionApi;

  ExcursionListState _listState = ExcursionListState.initial;
  List<ExcursionVm> _excursions = const [];
  String? _listErrorMessage;
  bool _isRefreshing = false;

  ExcursionDetailState _detailState = ExcursionDetailState.initial;
  String? _detailExcursionId;
  ExcursionVm? _selectedExcursion;
  String? _detailErrorMessage;

  ExcursionActionState _actionState = ExcursionActionState.idle;
  String? _actionErrorMessage;
  ExcursionVm? _lastCreatedExcursion;

  ExcursionListState get listState => _listState;
  List<ExcursionVm> get excursions => _excursions;
  String? get listErrorMessage => _listErrorMessage;
  bool get isRefreshing => _isRefreshing;

  ExcursionDetailState get detailState => _detailState;
  ExcursionVm? get selectedExcursion => _selectedExcursion;
  String? get detailErrorMessage => _detailErrorMessage;

  ExcursionActionState get actionState => _actionState;
  String? get actionErrorMessage => _actionErrorMessage;
  ExcursionVm? get lastCreatedExcursion => _lastCreatedExcursion;

  Future<void> loadExcursions({
    String? query,
    String? categorySlug,
    String? cityName,
  }) async {
    if (_listState == ExcursionListState.loading || _isRefreshing) {
      return;
    }

    final hasCachedExcursions = _excursions.isNotEmpty;
    if (hasCachedExcursions) {
      _isRefreshing = true;
    } else {
      _listState = ExcursionListState.loading;
    }
    _listErrorMessage = null;
    notifyListeners();

    try {
      _excursions = await _excursionApi.getExcursions(
        query: query,
        categorySlug: categorySlug,
        cityName: cityName,
      );
      _listState = ExcursionListState.success;
    } on DioException catch (e) {
      _listErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedExcursions) {
        _listState = ExcursionListState.error;
      }
    } catch (_) {
      _listErrorMessage = 'Failed to load excursions';
      if (!hasCachedExcursions) {
        _listState = ExcursionListState.error;
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshExcursions({
    String? query,
    String? categorySlug,
    String? cityName,
  }) {
    return loadExcursions(
      query: query,
      categorySlug: categorySlug,
      cityName: cityName,
    );
  }

  Future<void> loadExcursionDetails(String excursionId,
      {ExcursionVm? initialExcursion}) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _detailState = ExcursionDetailState.error;
      _detailErrorMessage = 'Invalid excursion id';
      notifyListeners();
      return;
    }

    final cachedExcursion =
        initialExcursion ?? _findCachedExcursion(trimmedExcursionId);
    final hasCachedExcursion = cachedExcursion != null;

    _detailExcursionId = trimmedExcursionId;
    _detailErrorMessage = null;
    if (hasCachedExcursion) {
      _selectedExcursion = cachedExcursion;
      _detailState = ExcursionDetailState.success;
    } else {
      _selectedExcursion = null;
      _detailState = ExcursionDetailState.loading;
    }
    notifyListeners();

    try {
      final excursion =
          await _excursionApi.getExcursionById(trimmedExcursionId);
      if (_detailExcursionId != trimmedExcursionId) return;

      _selectedExcursion = excursion;
      _detailState = ExcursionDetailState.success;
    } on DioException catch (e) {
      if (_detailExcursionId != trimmedExcursionId) return;

      _detailErrorMessage = DioErrorMapper.toMessage(e);
      if (!hasCachedExcursion) {
        _detailState = ExcursionDetailState.error;
      }
    } catch (_) {
      if (_detailExcursionId != trimmedExcursionId) return;

      _detailErrorMessage = 'Failed to load excursion';
      if (!hasCachedExcursion) {
        _detailState = ExcursionDetailState.error;
      }
    } finally {
      if (_detailExcursionId == trimmedExcursionId) {
        notifyListeners();
      }
    }
  }

  void resetActionState() {
    _actionState = ExcursionActionState.idle;
    _actionErrorMessage = null;
    notifyListeners();
  }

  Future<ExcursionVm?> createAndPublishExcursion(
      CreateExcursionRequest request) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await _excursionApi.createExcursion(request);
      final published = await _excursionApi.publishExcursion(created.id);
      final refreshedProduct = await _refreshProductAfterMutation(
        published,
        preferredLandmarkId: request.landmarkId,
      );
      _lastCreatedExcursion = refreshedProduct ?? published;
      _actionState = ExcursionActionState.success;
      return _lastCreatedExcursion;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to create excursion';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ExcursionVm?> loadMyExcursionForEdit(String excursionId) async {
    final trimmedExcursionId = excursionId.trim();
    if (trimmedExcursionId.isEmpty) {
      _actionErrorMessage = 'Invalid excursion id';
      return null;
    }
    try {
      return await _excursionApi.getMyExcursion(trimmedExcursionId);
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to load excursion';
      return null;
    }
  }

  Future<ExcursionVm?> updateExcursionOffer(
    String legacyExcursionId,
    CreateExcursionRequest request,
  ) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated =
          await _excursionApi.updateExcursionOffer(legacyExcursionId, request);
      final refreshedProduct = await _refreshProductAfterMutation(
        updated,
        preferredProductId: _detailExcursionId,
        preferredLandmarkId: request.landmarkId,
      );
      _actionState = ExcursionActionState.success;
      return refreshedProduct ?? updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to update excursion offer';
      _actionState = ExcursionActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> createExcursionBooking(
      CreateExcursionBookingRequest request) async {
    _actionState = ExcursionActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await _excursionApi.createExcursionBooking(request);
      _actionState = ExcursionActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ExcursionActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to book excursion';
      _actionState = ExcursionActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _reloadExcursionsAfterMutation(
      {ExcursionVm? fallbackExcursion}) async {
    try {
      _excursions = await _excursionApi.getExcursions();
      _listState = ExcursionListState.success;
      _listErrorMessage = null;
    } catch (_) {
      if (fallbackExcursion != null) {
        _upsertPublishedExcursion(fallbackExcursion);
      }
    }
  }

  Future<ExcursionVm?> _refreshProductAfterMutation(
    ExcursionVm changedExcursion, {
    String? preferredProductId,
    String? preferredLandmarkId,
  }) async {
    for (var attempt = 0; attempt < _marketplaceRefreshAttempts; attempt++) {
      await _reloadExcursionsAfterMutation(
        fallbackExcursion: attempt == 0 ? changedExcursion : null,
      );

      final productId = _resolveChangedProductId(
        changedExcursion,
        preferredProductId: preferredProductId,
        preferredLandmarkId: preferredLandmarkId,
      );
      if (productId == null) {
        if (attempt < _marketplaceRefreshAttempts - 1) {
          await Future<void>.delayed(
            Duration(
              milliseconds:
                  _marketplaceRefreshRetryDelay.inMilliseconds * (attempt + 1),
            ),
          );
        }
        continue;
      }

      try {
        final details = await _excursionApi.getExcursionById(productId);
        _upsertPublishedExcursion(details);
        if (_detailExcursionId == productId) {
          _selectedExcursion = details;
          _detailState = ExcursionDetailState.success;
          _detailErrorMessage = null;
        }
        return details;
      } catch (_) {
        final cachedProduct = _findCachedExcursion(productId);
        if (cachedProduct != null) {
          return cachedProduct;
        }
      }
      if (attempt < _marketplaceRefreshAttempts - 1) {
        await Future<void>.delayed(
          Duration(
            milliseconds:
                _marketplaceRefreshRetryDelay.inMilliseconds * (attempt + 1),
          ),
        );
      }
    }

    return changedExcursion;
  }

  String? _resolveChangedProductId(
    ExcursionVm changedExcursion, {
    String? preferredProductId,
    String? preferredLandmarkId,
  }) {
    final preferred = preferredProductId?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final changedId = changedExcursion.id.trim();
    for (final excursion in _excursions) {
      if (excursion.id == changedId) return excursion.id;
    }

    final landmarkId =
        (preferredLandmarkId ?? changedExcursion.landmarkId ?? '').trim();
    if (landmarkId.isNotEmpty) {
      for (final excursion in _excursions) {
        if ((excursion.landmarkId ?? '').trim() == landmarkId) {
          return excursion.id;
        }
      }
    }

    for (final excursion in _excursions) {
      for (final offer in excursion.offers) {
        if ((offer.legacyExcursionId ?? '').trim() == changedId) {
          return excursion.id;
        }
      }
    }

    return null;
  }

  ExcursionVm? _findCachedExcursion(String excursionId) {
    for (final excursion in _excursions) {
      if (excursion.id == excursionId) return excursion;
    }
    return null;
  }

  void _upsertPublishedExcursion(ExcursionVm excursion) {
    final excursionId = excursion.id.trim();
    if (excursionId.isEmpty) return;

    final status = excursion.status.trim().toUpperCase();
    final visibility = excursion.visibility.trim().toUpperCase();
    if (status != 'PUBLISHED' || visibility != 'PUBLIC') {
      return;
    }
    if (excursion.publishedOffersCount <= 0 && excursion.offers.isEmpty) {
      return;
    }

    final nextExcursions = [..._excursions];
    final existingIndex =
        nextExcursions.indexWhere((item) => item.id == excursionId);
    if (existingIndex >= 0) {
      nextExcursions
        ..removeAt(existingIndex)
        ..insert(0, excursion);
    } else {
      nextExcursions.insert(0, excursion);
    }
    _excursions = List.unmodifiable(nextExcursions);
    _listState = ExcursionListState.success;
  }
}
