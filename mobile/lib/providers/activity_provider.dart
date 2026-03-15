import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/activity_api.dart';
import '../core/network/dio_error_mapper.dart';
import '../features/activities/models/activity_category_vm.dart';
import '../features/activities/models/activity_list_item_vm.dart';
import '../features/activities/models/create_activity_request.dart';
import '../features/activities/models/update_activity_request.dart';

enum ActivitiesState { initial, loading, success, error }

enum ActivityActionState { idle, loading, success, error }

class ActivityProvider extends ChangeNotifier {
  ActivityProvider({ActivityApi? activityApi})
    : _activityApi = activityApi ?? ActivityApi();

  final ActivityApi _activityApi;

  ActivitiesState _state = ActivitiesState.initial;
  ActivityActionState _actionState = ActivityActionState.idle;
  ActivitiesState _categoryState = ActivitiesState.initial;

  bool _isRefreshing = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  String? _categoryErrorMessage;

  List<ActivityListItemVm> _items = const [];
  ActivityListItemVm? _selectedActivity;
  List<ActivityCategoryVm> _categoryItems = const [];

  ActivitiesState _myState = ActivitiesState.initial;
  List<ActivityListItemVm> _myItems = const [];
  String? _myErrorMessage;
  bool _myIsRefreshing = false;

  ActivitiesState get state => _state;
  ActivityActionState get actionState => _actionState;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  List<ActivityListItemVm> get items => _items;
  ActivityListItemVm? get selectedActivity => _selectedActivity;
  ActivitiesState get categoryState => _categoryState;
  String? get categoryErrorMessage => _categoryErrorMessage;
  List<ActivityCategoryVm> get categoryItems => _categoryItems;

  ActivitiesState get myState => _myState;
  List<ActivityListItemVm> get myItems => _myItems;
  String? get myErrorMessage => _myErrorMessage;
  bool get myIsRefreshing => _myIsRefreshing;

  Future<void> loadActivityCategories({bool force = false}) async {
    if (!force &&
        (_categoryState == ActivitiesState.loading ||
            (_categoryState == ActivitiesState.success &&
                _categoryItems.isNotEmpty))) {
      return;
    }

    _categoryState = ActivitiesState.loading;
    _categoryErrorMessage = null;
    notifyListeners();

    try {
      _categoryItems = await _activityApi.getActivityCategories();
      _categoryState = ActivitiesState.success;
    } on DioException catch (e) {
      _categoryErrorMessage = DioErrorMapper.toMessage(e);
      _categoryState = ActivitiesState.error;
    } catch (_) {
      _categoryErrorMessage = 'Failed to load categories';
      _categoryState = ActivitiesState.error;
    }

    notifyListeners();
  }

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

  Future<void> loadMyActivities() async {
    _myState = ActivitiesState.loading;
    _myErrorMessage = null;
    notifyListeners();

    try {
      _myItems = await _activityApi.getMyHostedActivities();
      _myState = ActivitiesState.success;
    } on DioException catch (e) {
      _myErrorMessage = DioErrorMapper.toMessage(e);
      _myState = ActivitiesState.error;
    } catch (_) {
      _myErrorMessage = 'Failed to load activities';
      _myState = ActivitiesState.error;
    }

    notifyListeners();
  }

  Future<void> refreshMyActivities() async {
    _myIsRefreshing = true;
    _myErrorMessage = null;
    notifyListeners();

    try {
      _myItems = await _activityApi.getMyHostedActivities();
      _myState = ActivitiesState.success;
    } on DioException catch (e) {
      _myErrorMessage = DioErrorMapper.toMessage(e);
      _myState = ActivitiesState.error;
    } catch (_) {
      _myErrorMessage = 'Failed to load activities';
      _myState = ActivitiesState.error;
    } finally {
      _myIsRefreshing = false;
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

  Future<ActivityListItemVm?> createActivity(
    CreateActivityRequest request,
  ) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final created = await _activityApi.createActivity(request);
      _actionState = ActivityActionState.success;
      notifyListeners();
      return created;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      notifyListeners();
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to create activity';
      _actionState = ActivityActionState.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> leaveActivity(String activityId, {String? reason}) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await _activityApi.leaveActivity(activityId, reason: reason);
      _actionState = ActivityActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to leave activity';
      _actionState = ActivityActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<ActivityListItemVm?> updateActivity(
    String activityId,
    UpdateActivityRequest request,
  ) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _activityApi.updateActivity(activityId, request);
      _selectedActivity = updated;
      _actionState = ActivityActionState.success;
      notifyListeners();
      return updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      notifyListeners();
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to update activity';
      _actionState = ActivityActionState.error;
      notifyListeners();
      return null;
    }
  }

  Future<bool> publishActivity(String activityId) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      _selectedActivity = await _activityApi.publishActivity(activityId);
      _actionState = ActivityActionState.success;
      return true;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return false;
    } catch (_) {
      _actionErrorMessage = 'Failed to publish activity';
      _actionState = ActivityActionState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }
}
