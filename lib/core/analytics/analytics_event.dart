/// Standard Analytics Event Names for Manito
class AnalyticsEvent {
  AnalyticsEvent._();

  // 1. App & Auth & Push
  static const String appOpen = 'app_open';
  static const String loginAttempt = 'login_attempt';
  static const String loginSuccess = 'login_success';
  static const String loginFailure = 'login_failure';
  static const String notificationClick = 'notification_click';

  // 2. Friends
  static const String friendSearch = 'friend_search';
  static const String friendRequestSend = 'friend_request_send';
  static const String friendRequestResponse = 'friend_request_response';
  static const String myCodeCopy = 'my_code_copy';

  // 3. Room & Lobby
  static const String roomCreateSheetOpen = 'room_create_sheet_open';
  static const String roomCreateSubmit = 'room_create_submit';
  static const String lobbyTitleEdit = 'lobby_title_edit';
  static const String lobbyCategoryToggle = 'lobby_category_toggle';
  static const String lobbyDeadlineChange = 'lobby_deadline_change';
  static const String lobbyInviteFriend = 'lobby_invite_friend';
  static const String roomGameStart = 'room_game_start';
  static const String roomLeave = 'room_leave';
  static const String roomDelete = 'room_delete';

  // 4. Mission Setup
  static const String missionSetupView = 'mission_setup_view';
  static const String missionCandidateSelect = 'mission_candidate_select';
  static const String missionReadySubmit = 'mission_ready_submit';

  // 5. In-Game Action
  static const String postWriteStart = 'post_write_start';
  static const String postWriteComplete = 'post_write_complete';
  static const String postWriteCancel = 'post_write_cancel';
  static const String suspectSelect = 'suspect_select';

  // 6. Results & Comments
  static const String resultFeedView = 'result_feed_view';
  static const String resultMemberFilter = 'result_member_filter';
  static const String commentSheetOpen = 'comment_sheet_open';
  static const String commentCreate = 'comment_create';

  // 7. Profile & Settings
  static const String profileEditView = 'profile_edit_view';
  static const String profileEditSave = 'profile_edit_save';
  static const String themeChange = 'theme_change';
}
