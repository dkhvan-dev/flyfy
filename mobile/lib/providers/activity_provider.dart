import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/activity_api.dart';
import '../core/network/dio_error_mapper.dart';
import '../features/activities/models/activity_list_item_vm.dart';

enum ActivitiesState {
  initial,
  loading,
  success,
  error,
}

enum ActivityActionState {
  idle,
  loading,
  success,
  error,
}

class ActivityProvider extends ChangeNotifier {
  ActivityProvider({ActivityApi? activityApi})
      : _activityApi = activityApi ?? ActivityApi();

  final ActivityApi _activityApi;

  ActivitiesState _state = ActivitiesState.initial;
  ActivityActionState _actionState = ActivityActionState.idle;

  bool _isRefreshing = false;
  String? _errorMessage;
  String? _actionErrorMessage;

  List<ActivityListItemVm> _items = const [];
  ActivityListItemVm? _selectedActivity;

  ActivitiesState get state => _state;
  ActivityActionState get actionState => _actionState;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  List<ActivityListItemVm> get items => _items;
  ActivityListItemVm? get selectedActivity => _selectedActivity;

  Future<void> loadActivities() async {
    _state = ActivitiesState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _activityApi.getActivities();
      _state = ActivitiesState.success;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = ActivitiesState.error;
    } catch (_) {
      _errorMessage = 'Failed to load activities';
      _state = ActivitiesState.error;
    }

    notifyListeners();
  }

  Future<void> refreshActivities() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _activityApi.getActivities();
      _state = ActivitiesState.success;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = ActivitiesState.error;
    } catch (_) {
      _errorMessage = 'Failed to load activities';
      _state = ActivitiesState.error;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadActivityDetails(String activityId) async {
    _state = ActivitiesState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedActivity = await _activityApi.getActivityById(activityId);
      _state = ActivitiesState.success;
    } on DioException catch (e) {
      _errorMessage = DioErrorMapper.toMessage(e);
      _state = ActivitiesState.error;
    } catch (_) {
      _errorMessage = 'Failed to load activity details';
      _state = ActivitiesState.error;
    }

    notifyListeners();
  }

  Future<bool> joinActivity(String activityId) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await _activityApi.joinActivity(activityId);
      _actionState = ActivityActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to join activity';
      _actionState = ActivityActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearSelectedActivity() {
    _selectedActivity = null;
    notifyListeners();
  }

  void resetActionState() {
    _actionState = ActivityActionState.idle;
    _actionErrorMessage = null;
    notifyListeners();
  }
}