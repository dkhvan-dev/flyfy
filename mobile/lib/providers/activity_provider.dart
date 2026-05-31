import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/activity_api.dart';
import '../core/network/chat_api.dart';
import '../core/network/dio_error_mapper.dart';
import '../features/activities/models/activity_category_vm.dart';
import '../features/activities/models/activity_list_item_vm.dart';
import '../features/activities/models/create_activity_request.dart';
import '../features/activities/models/update_activity_request.dart';

enum ActivitiesState { initial, loading, success, error }

enum ActivityActionState { idle, loading, success, error }

class ActivityProvider extends ChangeNotifier {
  ActivityProvider({ActivityApi? activityApi, ChatApi? chatApi})
    : _activityApi = activityApi ?? ActivityApi(),
      _chatApi = chatApi ?? ChatApi();

  static const int _listFetchLimit = 100;

  final ActivityApi _activityApi;
  final ChatApi _chatApi;

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

  ActivitiesState _joinedState = ActivitiesState.initial;
  List<ActivityListItemVm> _joinedItems = const [];
  String? _joinedErrorMessage;
  bool _joinedIsRefreshing = false;

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

  ActivitiesState get joinedState => _joinedState;
  List<ActivityListItemVm> get joinedItems => _joinedItems;
  String? get joinedErrorMessage => _joinedErrorMessage;
  bool get joinedIsRefreshing => _joinedIsRefreshing;

  void _replaceActivityInCaches(ActivityListItemVm activity) {
    ActivityListItemVm replace(ActivityListItemVm current) =>
        current.id == activity.id ? activity : current;

    if (_selectedActivity?.id == activity.id) {
      _selectedActivity = activity;
    }

    _items = _items.map(replace).toList(growable: false);
    _myItems = _myItems.map(replace).toList(growable: false);
    _joinedItems = _joinedItems.map(replace).toList(growable: false);
  }

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
      _items = await _activityApi.getActivities(limit: _listFetchLimit);
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
      _items = await _activityApi.getActivities(limit: _listFetchLimit);
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
      _myItems = await _activityApi.getMyHostedActivities(
        limit: _listFetchLimit,
      );
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
      _myItems = await _activityApi.getMyHostedActivities(
        limit: _listFetchLimit,
      );
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

  Future<void> loadJoinedActivities() async {
    _joinedState = ActivitiesState.loading;
    _joinedErrorMessage = null;
    notifyListeners();

    try {
      _joinedItems = await _activityApi.getMyJoinedActivities(
        limit: _listFetchLimit,
      );
      _joinedState = ActivitiesState.success;
    } on DioException catch (e) {
      _joinedErrorMessage = DioErrorMapper.toMessage(e);
      _joinedState = ActivitiesState.error;
    } catch (_) {
      _joinedErrorMessage = 'Failed to load joined activities';
      _joinedState = ActivitiesState.error;
    }

    notifyListeners();
  }

  Future<void> refreshJoinedActivities() async {
    _joinedIsRefreshing = true;
    _joinedErrorMessage = null;
    notifyListeners();

    try {
      _joinedItems = await _activityApi.getMyJoinedActivities(
        limit: _listFetchLimit,
      );
      _joinedState = ActivitiesState.success;
    } on DioException catch (e) {
      _joinedErrorMessage = DioErrorMapper.toMessage(e);
      _joinedState = ActivitiesState.error;
    } catch (_) {
      _joinedErrorMessage = 'Failed to load joined activities';
      _joinedState = ActivitiesState.error;
    } finally {
      _joinedIsRefreshing = false;
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

  Future<bool> joinActivity(
    String activityId, {
    String? visibilityPassword,
  }) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      await _activityApi.joinActivity(
        activityId,
        visibilityPassword: visibilityPassword,
      );
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

      // Create group chat for the activity (fire-and-forget)
      try {
        await _chatApi.createActivityConversation(
          activityId: created.id,
          title: request.title,
        );
      } catch (e) {
        debugPrint('Failed to create activity chat: $e');
      }

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
      _replaceActivityInCaches(updated);
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
      final updated = await _activityApi.publishActivity(activityId);
      _replaceActivityInCaches(updated);
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

  Future<ActivityListItemVm?> cancelActivity(
    String activityId, {
    String? reason,
  }) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _activityApi.cancelActivity(
        activityId,
        reason: reason,
      );
      _replaceActivityInCaches(updated);
      _actionState = ActivityActionState.success;
      return updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to cancel activity';
      _actionState = ActivityActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ActivityListItemVm?> completeActivity(
    String activityId, {
    String? reason,
  }) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _activityApi.completeActivity(
        activityId,
        reason: reason,
      );
      _replaceActivityInCaches(updated);
      _actionState = ActivityActionState.success;
      return updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to complete activity';
      _actionState = ActivityActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<ActivityListItemVm?> extendActivity(
    String activityId, {
    required int minutes,
  }) async {
    _actionState = ActivityActionState.loading;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final updated = await _activityApi.extendActivity(
        activityId,
        minutes: minutes,
      );
      _replaceActivityInCaches(updated);
      _actionState = ActivityActionState.success;
      return updated;
    } on DioException catch (e) {
      _actionErrorMessage = DioErrorMapper.toMessage(e);
      _actionState = ActivityActionState.error;
      return null;
    } catch (_) {
      _actionErrorMessage = 'Failed to extend activity';
      _actionState = ActivityActionState.error;
      return null;
    } finally {
      notifyListeners();
    }
  }
}
