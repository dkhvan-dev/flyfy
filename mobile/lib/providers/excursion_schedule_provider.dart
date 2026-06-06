import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/dio_error_mapper.dart';
import '../core/network/excursion_schedule_api.dart';
import '../core/time/app_time.dart';
import '../features/excursions/models/excursion_schedule_vm.dart';

enum ExcursionScheduleState { initial, loading, success, error }

enum ExcursionScheduleActionState { idle, loading, success, error }

class ExcursionScheduleProvider extends ChangeNotifier {
  ExcursionScheduleProvider({ExcursionScheduleApi? scheduleApi})
    : _scheduleApi = scheduleApi ?? ExcursionScheduleApi();

  final ExcursionScheduleApi _scheduleApi;

  ExcursionScheduleState _state = ExcursionScheduleState.initial;
  ExcursionScheduleActionState _actionState = ExcursionScheduleActionState.idle;
  DateTime? _selectedDate;
  List<ExcursionScheduleSlotVm> _slots = const [];
  String? _errorMessage;
  String? _actionErrorMessage;
  bool _isActionConflict = false;
  DateTime? _loadedWeekStart;
  DateTime? _loadedWeekEnd;
  String? _loadedGuideUserId;

  ExcursionScheduleState get state => _state;
  ExcursionScheduleActionState get actionState => _actionState;
  DateTime? get selectedDate => _selectedDate;
  List<ExcursionScheduleSlotVm> get slots => _slots;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get isActionConflict => _isActionConflict;

  Future<void> loadWeek(DateTime anchor, {String? guideUserId}) async {
    final weekStart = _mondayStart(anchor);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final normalizedGuideUserId = guideUserId?.trim();
    final publicGuideUserId =
        normalizedGuideUserId == null || normalizedGuideUserId.isEmpty
        ? null
        : normalizedGuideUserId;

    _selectedDate = anchor;
    _state = ExcursionScheduleState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final slots = publicGuideUserId == null
          ? await _scheduleApi.getGuideSchedule(
              from: weekStart.toUtc(),
              to: weekEnd.toUtc(),
            )
          : await _scheduleApi.getPublicGuideSchedule(
              guideUserId: publicGuideUserId,
              from: weekStart.toUtc(),
              to: weekEnd.toUtc(),
            );
      _slots = _sortSlots(slots);
      _loadedWeekStart = weekStart;
      _loadedWeekEnd = weekEnd;
      _loadedGuideUserId = publicGuideUserId;
      _state = ExcursionScheduleState.success;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = ExcursionScheduleState.error;
    } catch (_) {
      _errorMessage = 'Failed to load excursion schedule';
      _state = ExcursionScheduleState.error;
    }

    notifyListeners();
  }

  void selectDate(DateTime day) {
    _selectedDate = day;
    notifyListeners();
  }

  List<ExcursionScheduleSlotVm> slotsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final filtered = _slots
        .where((slot) {
          return eventDateOnly(slot.startAt, slot.timezone) == target;
        })
        .toList(growable: false);

    return _sortSlots(filtered);
  }

  Future<bool> createSlot(CreateExcursionScheduleSlotRequest request) async {
    _setActionLoading();

    try {
      final slot = await _scheduleApi.createSlot(request);
      _upsertSlot(slot);
      _selectedDate = eventDateOnly(slot.startAt, slot.timezone);
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(
        DioErrorMapper.toMessage(e),
        isConflict: _isScheduleConflict(e),
      );
      return false;
    } catch (_) {
      _setActionError('Failed to create excursion schedule slot');
      return false;
    }
  }

  Future<bool> createSeries(
    CreateExcursionScheduleSeriesRequest request,
  ) async {
    _setActionLoading();

    try {
      final slots = await _scheduleApi.createSeries(request);
      final nextSlots = List<ExcursionScheduleSlotVm>.of(_slots);
      for (final slot in slots) {
        final index = nextSlots.indexWhere((item) => item.id == slot.id);
        if (index == -1) {
          nextSlots.add(slot);
        } else {
          nextSlots[index] = slot;
        }
      }
      _slots = _sortSlots(nextSlots);
      if (slots.isNotEmpty) {
        _selectedDate = eventDateOnly(
          slots.first.startAt,
          slots.first.timezone,
        );
      }
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(
        DioErrorMapper.toMessage(e),
        isConflict: _isScheduleConflict(e),
      );
      return false;
    } catch (_) {
      _setActionError('Failed to create excursion schedule series');
      return false;
    }
  }

  Future<bool> updateSlot(
    String id,
    UpdateExcursionScheduleSlotRequest request,
  ) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      _setActionError('Invalid schedule slot id');
      return false;
    }

    _setActionLoading();

    try {
      final slot = await _scheduleApi.updateSlot(trimmedId, request);
      _upsertSlot(slot);
      _selectedDate = eventDateOnly(slot.startAt, slot.timezone);
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(
        DioErrorMapper.toMessage(e),
        isConflict: _isScheduleConflict(e),
      );
      return false;
    } catch (_) {
      _setActionError('Failed to update excursion schedule slot');
      return false;
    }
  }

  Future<bool> closeSlot(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      _setActionError('Invalid schedule slot id');
      return false;
    }

    _setActionLoading();

    try {
      final slot = await _scheduleApi.closeSlot(trimmedId);
      _upsertSlot(slot);
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(DioErrorMapper.toMessage(e));
      return false;
    } catch (_) {
      _setActionError('Failed to close excursion schedule slot');
      return false;
    }
  }

  Future<bool> cancelSlot(String id, String reason) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      _setActionError('Invalid schedule slot id');
      return false;
    }

    _setActionLoading();

    try {
      final slot = await _scheduleApi.cancelSlot(trimmedId, reason);
      _upsertSlot(slot);
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(DioErrorMapper.toMessage(e));
      return false;
    } catch (_) {
      _setActionError('Failed to cancel excursion schedule slot');
      return false;
    }
  }

  Future<bool> deleteSlot(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      _setActionError('Invalid schedule slot id');
      return false;
    }

    _setActionLoading();

    try {
      await _scheduleApi.deleteSlot(trimmedId);
      _slots = _slots
          .where((slot) => slot.id != trimmedId)
          .toList(growable: false);
      _setActionSuccess();
      return true;
    } on DioException catch (e) {
      _setActionError(DioErrorMapper.toMessage(e));
      return false;
    } catch (_) {
      _setActionError('Failed to delete excursion schedule slot');
      return false;
    }
  }

  bool get hasLoadedSelectedWeek {
    final selected = _selectedDate;
    if (selected == null) return false;
    return isDateInLoadedWeek(selected);
  }

  bool isDateInLoadedWeek(DateTime day, {String? guideUserId}) {
    final start = _loadedWeekStart;
    final end = _loadedWeekEnd;
    if (start == null || end == null) return false;
    final normalizedGuideUserId = guideUserId?.trim();
    final expectedGuideUserId =
        normalizedGuideUserId == null || normalizedGuideUserId.isEmpty
        ? null
        : normalizedGuideUserId;
    if (_loadedGuideUserId != expectedGuideUserId) return false;
    return !day.isBefore(start) && day.isBefore(end);
  }

  DateTime _mondayStart(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return dateOnly.subtract(Duration(days: dateOnly.weekday - 1));
  }

  List<ExcursionScheduleSlotVm> _sortSlots(
    List<ExcursionScheduleSlotVm> source,
  ) {
    final sorted = List<ExcursionScheduleSlotVm>.of(source)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return List<ExcursionScheduleSlotVm>.unmodifiable(sorted);
  }

  void _upsertSlot(ExcursionScheduleSlotVm slot) {
    final nextSlots = List<ExcursionScheduleSlotVm>.of(_slots);
    final index = nextSlots.indexWhere((item) => item.id == slot.id);
    if (index == -1) {
      nextSlots.add(slot);
    } else {
      nextSlots[index] = slot;
    }
    _slots = _sortSlots(nextSlots);
  }

  void _setActionLoading() {
    _actionState = ExcursionScheduleActionState.loading;
    _actionErrorMessage = null;
    _isActionConflict = false;
    notifyListeners();
  }

  void _setActionSuccess() {
    _actionState = ExcursionScheduleActionState.success;
    _actionErrorMessage = null;
    _isActionConflict = false;
    notifyListeners();
  }

  void _setActionError(String message, {bool isConflict = false}) {
    _actionState = ExcursionScheduleActionState.error;
    _actionErrorMessage = message;
    _isActionConflict = isConflict;
    notifyListeners();
  }

  bool _isScheduleConflict(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      return _containsScheduleConflict(data['error']) ||
          _containsScheduleConflict(data['message']) ||
          _containsScheduleConflict(data['detail']);
    }
    return _containsScheduleConflict(data);
  }

  bool _containsScheduleConflict(Object? value) {
    if (value is! String) return false;
    return value.toLowerCase().contains('excursion schedule conflict');
  }
}
