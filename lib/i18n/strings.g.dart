/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 262 (131 per locale)
///
/// Built on 2026-09-02 at 14:05 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.ko;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.ko) // set locale
/// - Locale locale = AppLocale.ko.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.ko) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	ko(languageCode: 'ko', build: Translations.build),
	en(languageCode: 'en', build: _StringsEn.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ko>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final _StringsCommonKo common = _StringsCommonKo._(_root);
	late final _StringsAuthKo auth = _StringsAuthKo._(_root);
	late final _StringsHomeKo home = _StringsHomeKo._(_root);
	late final _StringsChatKo chat = _StringsChatKo._(_root);
	late final _StringsLobbyKo lobby = _StringsLobbyKo._(_root);
	late final _StringsMissionSetupKo missionSetup = _StringsMissionSetupKo._(_root);
	late final _StringsGameKo game = _StringsGameKo._(_root);
	late final _StringsFeedKo feed = _StringsFeedKo._(_root);
	late final _StringsFriendsKo friends = _StringsFriendsKo._(_root);
	late final _StringsProfileKo profile = _StringsProfileKo._(_root);
	late final _StringsSettingsKo settings = _StringsSettingsKo._(_root);
}

// Path: common
class _StringsCommonKo {
	_StringsCommonKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get appName => '마니또';
	String get confirm => '확인';
	String get cancel => '취소';
	String get save => '저장';
	String get delete => '삭제';
	String get edit => '수정';
	String get close => '닫기';
	String get retry => '다시 시도';
	String get error => '오류';
	String get success => '성공';
	String get loading => '불러오는 중...';
	String get copySuccess => '복사되었습니다.';
	String get networkErrorTitle => '네트워크 연결을 확인해 주세요';
	String get networkErrorRetry => '다시 시도';
}

// Path: auth
class _StringsAuthKo {
	_StringsAuthKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get loginTitle => '비밀 마니또 작전';
	String get loginSubtitle => '친구들과 함께하는 비밀 친구 마니또';
	String get kakaoLogin => '카카오로 계속하기';
	String get appleLogin => 'Apple로 계속하기';
	String get googleLogin => 'Google로 계속하기';
	String get loginFailed => '로그인에 실패했습니다. 다시 시도해 주세요.';
	String get logoutConfirmTitle => '로그아웃';
	String get logoutConfirmMessage => '로그아웃 하시겠습니까?';
}

// Path: home
class _StringsHomeKo {
	_StringsHomeKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '마니또';
	String get tabHome => '홈';
	String get tabChat => '채팅';
	String get tabArchive => '기록';
	String get tabFriends => '친구';
	String get tabProfile => '프로필';
	String get ongoingTitle => '진행 중인 마니또';
	String get invitationTitle => '받은 초대장';
	String get createRoom => '새로운 방 만들기';
	String get noOngoing => '현재 진행 중인 마니또가 없어요';
	String get noInvitations => '받은 초대장이 없습니다';
	String get accept => '수락';
	String get decline => '거절';
}

// Path: chat
class _StringsChatKo {
	_StringsChatKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '채팅';
	String get newChat => '새로운 채팅';
	String get searchHint => '친구 이름 또는 고유 코드 검색';
	String get groupTitleHint => '그룹 대화방 제목 (선택 입력)';
	String get startDirect => '1:1 대화 시작';
	String get startGroup => '그룹 대화 시작 ({count}명)';
	String get emptyChats => '진행 중인 채팅이 없습니다.';
	String get emptyChatsDesc => '친구를 선택해 1:1 또는 그룹 대화를 시작해보세요!';
	String get firstMessageDesc => '첫 메시지를 보내 대화를 시작해보세요!';
	String get leaveRoom => '채팅방 나가기';
	String get leaveConfirmTitle => '채팅방 나가기';
	String get leaveConfirmMessage => '채팅방을 나가면 대화 내용이 모두 삭제되고 채팅 목록에서도 삭제됩니다.\n\n정말 나가시겠습니까?';
	String get drawerTitle => '채팅방 서랍';
	String get members => '대화상대';
	String get me => '나';
	String get yesterday => '어제';
}

// Path: lobby
class _StringsLobbyKo {
	_StringsLobbyKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '대기실';
	String get hostBadge => '방장';
	String get roomTitleLabel => '제목';
	String get editTitle => '제목 수정';
	String get categoryLabel => '미션 카테고리';
	String get categoryDaily => '일상';
	String get categorySchool => '학교';
	String get categoryWork => '직장';
	String get deadlineLabel => '마감 시간';
	String get setDeadline => '마감 시간 설정';
	String get membersTitle => '참가 요원';
	String get inviteFriends => '친구 초대하기';
	String get startGame => '마니또 시작하기';
	String get minMembersRequired => '최소 2명 이상의 참가자가 필요합니다';
	String get leaveRoom => '대기실 나가기';
	String get deleteRoom => '방 삭제 및 나가기';
	String get leaveConfirm => '정말 대기실을 나가시겠습니까?';
	String get deleteConfirm => '방을 삭제하면 모든 초대가 취소됩니다.';
}

// Path: missionSetup
class _StringsMissionSetupKo {
	_StringsMissionSetupKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '마니또 미션 선택';
	String get timerLabel => '미션 선택 제한시간';
	String get friendsSelecting => '다른 친구들 미션 선택 중...';
	String get targetConfidential => '당신은 {name}의 마니또 입니다';
	String get selectMission => '미션 선택';
	String get confirmSelection => '미션 확정하기';
	String get selectionComplete => '미션 선택 완료';
}

// Path: game
class _StringsGameKo {
	_StringsGameKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tabMissionPerform => '미션 기록';
	String get tabSuspectGuess => '마니또 추측';
	String get save => '저장';
	String get saveSuccess => '미션 기록 및 마니또 지목이 모두 저장되었습니다!';
	String get saveFailed => '저장에 실패했습니다. 다시 시도해 주세요.';
	String get selectSuspect => '마니또로 의심되는 친구를 선택하세요';
	String get addPhotoPrompt => '사진을 첨부해 주세요';
	String get addTextPrompt => '내용을 입력해 주세요';
	String get validationPhotoPerform => '💡 [미션 기록] 탭에 인증 사진을 1장 이상 첨부해 주세요!';
	String get validationSuspect => '💡 [마니또 추측] 탭에서 마니또로 의심되는 친구를 선택해 주세요!';
	String get validationPhotoGuess => '💡 [마니또 추측] 탭에 사진 단서를 1장 이상 첨부해 주세요!';
	String get deadlineBanner => '마감 시간';
}

// Path: feed
class _StringsFeedKo {
	_StringsFeedKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '기록 상세';
	String get tabFeed => '피드';
	String get tabComments => '댓글';
	String get commentPlaceholder => '댓글을 입력하세요...';
	String get noComments => '첫 댓글을 남겨보세요!';
	String get send => '전송';
	String get authorManito => '내 마니또';
	String get targetAgent => '대상 요원';
	String get guessSuccess => '추측 성공! 🎉';
	String get guessFailed => '추측 실패! 🕵️';
}

// Path: friends
class _StringsFriendsKo {
	_StringsFriendsKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '친구';
	String get search => '친구 찾기';
	String get searchHint => '친구의 고유 코드를 입력하세요';
	String get sendRequest => '친구 요청';
	String get requestSent => '친구 요청을 보냈습니다!';
	String get receivedRequests => '받은 친구 요청';
	String get acceptedFriends => '친구 목록';
	String get noFriends => '등록된 친구가 없습니다';
	String get noRequests => '받은 요청이 없습니다';
	String get deleteFriend => '친구 삭제';
	String get deleteConfirm => '정말 친구를 삭제하시겠습니까?';
}

// Path: profile
class _StringsProfileKo {
	_StringsProfileKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '프로필';
	String get edit => '프로필 수정';
	String get name => '이름';
	String get statusMessage => '상태 메시지';
	String get uniqueCode => '내 고유 코드';
	String get copyCode => '코드 복사';
}

// Path: settings
class _StringsSettingsKo {
	_StringsSettingsKo._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => '설정';
	String get theme => '테마 설정';
	String get themeSystem => '시스템 설정 따름';
	String get themeLight => '라이트 모드';
	String get themeDark => '다크 모드';
	String get language => '언어 설정 (Language)';
	String get langKo => '한국어';
	String get langEn => 'English';
	String get contact => '문의하기';
	String get terms => '이용약관';
	String get privacy => '개인정보 처리방침';
	String get logout => '로그아웃';
	String get deleteAccount => '회원 탈퇴';
	String get deleteAccountConfirmTitle => '회원 탈퇴';
	String get deleteAccountConfirmMessage => '회원 탈퇴 시 모든 친구 관계, 마니또 기록, 프로필 정보가 영구 삭제되며 복구할 수 없습니다.\n\n정말 탈퇴하시겠습니까?';
	String get version => '앱 버전';
}

// Path: <root>
class _StringsEn extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsEn.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _StringsEn _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsCommonEn common = _StringsCommonEn._(_root);
	@override late final _StringsAuthEn auth = _StringsAuthEn._(_root);
	@override late final _StringsHomeEn home = _StringsHomeEn._(_root);
	@override late final _StringsChatEn chat = _StringsChatEn._(_root);
	@override late final _StringsLobbyEn lobby = _StringsLobbyEn._(_root);
	@override late final _StringsMissionSetupEn missionSetup = _StringsMissionSetupEn._(_root);
	@override late final _StringsGameEn game = _StringsGameEn._(_root);
	@override late final _StringsFeedEn feed = _StringsFeedEn._(_root);
	@override late final _StringsFriendsEn friends = _StringsFriendsEn._(_root);
	@override late final _StringsProfileEn profile = _StringsProfileEn._(_root);
	@override late final _StringsSettingsEn settings = _StringsSettingsEn._(_root);
}

// Path: common
class _StringsCommonEn extends _StringsCommonKo {
	_StringsCommonEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get appName => 'Manito';
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get save => 'Save';
	@override String get delete => 'Delete';
	@override String get edit => 'Edit';
	@override String get close => 'Close';
	@override String get retry => 'Retry';
	@override String get error => 'Error';
	@override String get success => 'Success';
	@override String get loading => 'Loading...';
	@override String get copySuccess => 'Copied to clipboard.';
	@override String get networkErrorTitle => 'Please check your network connection';
	@override String get networkErrorRetry => 'Retry';
}

// Path: auth
class _StringsAuthEn extends _StringsAuthKo {
	_StringsAuthEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get loginTitle => 'Secret Manito Operation';
	@override String get loginSubtitle => 'Play Secret Santa & Manito with your friends';
	@override String get kakaoLogin => 'Continue with Kakao';
	@override String get appleLogin => 'Continue with Apple';
	@override String get googleLogin => 'Continue with Google';
	@override String get loginFailed => 'Login failed. Please try again.';
	@override String get logoutConfirmTitle => 'Log Out';
	@override String get logoutConfirmMessage => 'Are you sure you want to log out?';
}

// Path: home
class _StringsHomeEn extends _StringsHomeKo {
	_StringsHomeEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Manito';
	@override String get tabHome => 'Home';
	@override String get tabChat => 'Chat';
	@override String get tabArchive => 'Archive';
	@override String get tabFriends => 'Friends';
	@override String get tabProfile => 'Profile';
	@override String get ongoingTitle => 'Ongoing Games';
	@override String get invitationTitle => 'Invitations Received';
	@override String get createRoom => 'Create New Room';
	@override String get noOngoing => 'No active Manito games right now';
	@override String get noInvitations => 'No invitations received';
	@override String get accept => 'Accept';
	@override String get decline => 'Decline';
}

// Path: chat
class _StringsChatEn extends _StringsChatKo {
	_StringsChatEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Chat';
	@override String get newChat => 'New Chat';
	@override String get searchHint => 'Search by friend name or code';
	@override String get groupTitleHint => 'Group chat title (optional)';
	@override String get startDirect => 'Start 1:1 Chat';
	@override String get startGroup => 'Start Group Chat ({count})';
	@override String get emptyChats => 'No active chats right now.';
	@override String get emptyChatsDesc => 'Select a friend to start a 1:1 or group chat!';
	@override String get firstMessageDesc => 'Send the first message to start the conversation!';
	@override String get leaveRoom => 'Leave Chat Room';
	@override String get leaveConfirmTitle => 'Leave Chat Room';
	@override String get leaveConfirmMessage => 'Leaving the room will delete all messages and remove it from your chat list.\n\nAre you sure you want to leave?';
	@override String get drawerTitle => 'Chat Drawer';
	@override String get members => 'Participants';
	@override String get me => 'Me';
	@override String get yesterday => 'Yesterday';
}

// Path: lobby
class _StringsLobbyEn extends _StringsLobbyKo {
	_StringsLobbyEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Waiting Room';
	@override String get hostBadge => 'Host';
	@override String get roomTitleLabel => 'Title';
	@override String get editTitle => 'Edit Title';
	@override String get categoryLabel => 'Mission Category';
	@override String get categoryDaily => 'Daily';
	@override String get categorySchool => 'School';
	@override String get categoryWork => 'Work';
	@override String get deadlineLabel => 'Deadline';
	@override String get setDeadline => 'Set Deadline';
	@override String get membersTitle => 'Agents Joined';
	@override String get inviteFriends => 'Invite Friends';
	@override String get startGame => 'Start Manito Game';
	@override String get minMembersRequired => 'At least 2 participating members required';
	@override String get leaveRoom => 'Leave Room';
	@override String get deleteRoom => 'Delete & Leave Room';
	@override String get leaveConfirm => 'Are you sure you want to leave the waiting room?';
	@override String get deleteConfirm => 'Deleting the room will cancel all invitations.';
}

// Path: missionSetup
class _StringsMissionSetupEn extends _StringsMissionSetupKo {
	_StringsMissionSetupEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Select Manito Mission';
	@override String get timerLabel => 'Selection Time Limit';
	@override String get friendsSelecting => 'Other friends are choosing missions...';
	@override String get targetConfidential => 'You are {name}\'s Manito';
	@override String get selectMission => 'Choose Mission';
	@override String get confirmSelection => 'Confirm Selection';
	@override String get selectionComplete => 'Mission Confirmed';
}

// Path: game
class _StringsGameEn extends _StringsGameKo {
	_StringsGameEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get tabMissionPerform => 'Mission Log';
	@override String get tabSuspectGuess => 'Guess Manito';
	@override String get save => 'Save';
	@override String get saveSuccess => 'Mission proof and guess saved successfully!';
	@override String get saveFailed => 'Failed to save. Please try again.';
	@override String get selectSuspect => 'Select who you suspect is your Manito';
	@override String get addPhotoPrompt => 'Attach a photo';
	@override String get addTextPrompt => 'Enter description';
	@override String get validationPhotoPerform => '💡 Please attach at least 1 photo in [Mission Log] tab!';
	@override String get validationSuspect => '💡 Please select your suspected Manito in [Guess Manito] tab!';
	@override String get validationPhotoGuess => '💡 Please attach at least 1 photo clue in [Guess Manito] tab!';
	@override String get deadlineBanner => 'Deadline';
}

// Path: feed
class _StringsFeedEn extends _StringsFeedKo {
	_StringsFeedEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Game Results';
	@override String get tabFeed => 'Feed';
	@override String get tabComments => 'Comments';
	@override String get commentPlaceholder => 'Write a comment...';
	@override String get noComments => 'Be the first to comment!';
	@override String get send => 'Send';
	@override String get authorManito => 'My Manito';
	@override String get targetAgent => 'Target Agent';
	@override String get guessSuccess => 'Guess Correct! 🎉';
	@override String get guessFailed => 'Guess Failed! 🕵️';
}

// Path: friends
class _StringsFriendsEn extends _StringsFriendsKo {
	_StringsFriendsEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Friends';
	@override String get search => 'Find Friends';
	@override String get searchHint => 'Enter friend\'s unique code';
	@override String get sendRequest => 'Send Request';
	@override String get requestSent => 'Friend request sent!';
	@override String get receivedRequests => 'Received Requests';
	@override String get acceptedFriends => 'Friend List';
	@override String get noFriends => 'No friends added yet';
	@override String get noRequests => 'No friend requests';
	@override String get deleteFriend => 'Remove Friend';
	@override String get deleteConfirm => 'Are you sure you want to remove this friend?';
}

// Path: profile
class _StringsProfileEn extends _StringsProfileKo {
	_StringsProfileEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Profile';
	@override String get edit => 'Edit Profile';
	@override String get name => 'Name';
	@override String get statusMessage => 'Status Message';
	@override String get uniqueCode => 'My Unique Code';
	@override String get copyCode => 'Copy Code';
}

// Path: settings
class _StringsSettingsEn extends _StringsSettingsKo {
	_StringsSettingsEn._(_StringsEn root) : this._root = root, super._(root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get theme => 'Theme Mode';
	@override String get themeSystem => 'System Default';
	@override String get themeLight => 'Light Mode';
	@override String get themeDark => 'Dark Mode';
	@override String get language => 'Language';
	@override String get langKo => '한국어 (Korean)';
	@override String get langEn => 'English';
	@override String get contact => 'Contact Support';
	@override String get terms => 'Terms of Service';
	@override String get privacy => 'Privacy Policy';
	@override String get logout => 'Log Out';
	@override String get deleteAccount => 'Delete Account';
	@override String get deleteAccountConfirmTitle => 'Delete Account';
	@override String get deleteAccountConfirmMessage => 'Deleting your account will permanently remove all friend relations, game records, and profile data.\n\nAre you sure you want to delete your account?';
	@override String get version => 'App Version';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.appName': return '마니또';
			case 'common.confirm': return '확인';
			case 'common.cancel': return '취소';
			case 'common.save': return '저장';
			case 'common.delete': return '삭제';
			case 'common.edit': return '수정';
			case 'common.close': return '닫기';
			case 'common.retry': return '다시 시도';
			case 'common.error': return '오류';
			case 'common.success': return '성공';
			case 'common.loading': return '불러오는 중...';
			case 'common.copySuccess': return '복사되었습니다.';
			case 'common.networkErrorTitle': return '네트워크 연결을 확인해 주세요';
			case 'common.networkErrorRetry': return '다시 시도';
			case 'auth.loginTitle': return '비밀 마니또 작전';
			case 'auth.loginSubtitle': return '친구들과 함께하는 비밀 친구 마니또';
			case 'auth.kakaoLogin': return '카카오로 계속하기';
			case 'auth.appleLogin': return 'Apple로 계속하기';
			case 'auth.googleLogin': return 'Google로 계속하기';
			case 'auth.loginFailed': return '로그인에 실패했습니다. 다시 시도해 주세요.';
			case 'auth.logoutConfirmTitle': return '로그아웃';
			case 'auth.logoutConfirmMessage': return '로그아웃 하시겠습니까?';
			case 'home.title': return '마니또';
			case 'home.tabHome': return '홈';
			case 'home.tabChat': return '채팅';
			case 'home.tabArchive': return '기록';
			case 'home.tabFriends': return '친구';
			case 'home.tabProfile': return '프로필';
			case 'home.ongoingTitle': return '진행 중인 마니또';
			case 'home.invitationTitle': return '받은 초대장';
			case 'home.createRoom': return '새로운 방 만들기';
			case 'home.noOngoing': return '현재 진행 중인 마니또가 없어요';
			case 'home.noInvitations': return '받은 초대장이 없습니다';
			case 'home.accept': return '수락';
			case 'home.decline': return '거절';
			case 'chat.title': return '채팅';
			case 'chat.newChat': return '새로운 채팅';
			case 'chat.searchHint': return '친구 이름 또는 고유 코드 검색';
			case 'chat.groupTitleHint': return '그룹 대화방 제목 (선택 입력)';
			case 'chat.startDirect': return '1:1 대화 시작';
			case 'chat.startGroup': return '그룹 대화 시작 ({count}명)';
			case 'chat.emptyChats': return '진행 중인 채팅이 없습니다.';
			case 'chat.emptyChatsDesc': return '친구를 선택해 1:1 또는 그룹 대화를 시작해보세요!';
			case 'chat.firstMessageDesc': return '첫 메시지를 보내 대화를 시작해보세요!';
			case 'chat.leaveRoom': return '채팅방 나가기';
			case 'chat.leaveConfirmTitle': return '채팅방 나가기';
			case 'chat.leaveConfirmMessage': return '채팅방을 나가면 대화 내용이 모두 삭제되고 채팅 목록에서도 삭제됩니다.\n\n정말 나가시겠습니까?';
			case 'chat.drawerTitle': return '채팅방 서랍';
			case 'chat.members': return '대화상대';
			case 'chat.me': return '나';
			case 'chat.yesterday': return '어제';
			case 'lobby.title': return '대기실';
			case 'lobby.hostBadge': return '방장';
			case 'lobby.roomTitleLabel': return '제목';
			case 'lobby.editTitle': return '제목 수정';
			case 'lobby.categoryLabel': return '미션 카테고리';
			case 'lobby.categoryDaily': return '일상';
			case 'lobby.categorySchool': return '학교';
			case 'lobby.categoryWork': return '직장';
			case 'lobby.deadlineLabel': return '마감 시간';
			case 'lobby.setDeadline': return '마감 시간 설정';
			case 'lobby.membersTitle': return '참가 요원';
			case 'lobby.inviteFriends': return '친구 초대하기';
			case 'lobby.startGame': return '마니또 시작하기';
			case 'lobby.minMembersRequired': return '최소 2명 이상의 참가자가 필요합니다';
			case 'lobby.leaveRoom': return '대기실 나가기';
			case 'lobby.deleteRoom': return '방 삭제 및 나가기';
			case 'lobby.leaveConfirm': return '정말 대기실을 나가시겠습니까?';
			case 'lobby.deleteConfirm': return '방을 삭제하면 모든 초대가 취소됩니다.';
			case 'missionSetup.title': return '마니또 미션 선택';
			case 'missionSetup.timerLabel': return '미션 선택 제한시간';
			case 'missionSetup.friendsSelecting': return '다른 친구들 미션 선택 중...';
			case 'missionSetup.targetConfidential': return '당신은 {name}의 마니또 입니다';
			case 'missionSetup.selectMission': return '미션 선택';
			case 'missionSetup.confirmSelection': return '미션 확정하기';
			case 'missionSetup.selectionComplete': return '미션 선택 완료';
			case 'game.tabMissionPerform': return '미션 기록';
			case 'game.tabSuspectGuess': return '마니또 추측';
			case 'game.save': return '저장';
			case 'game.saveSuccess': return '미션 기록 및 마니또 지목이 모두 저장되었습니다!';
			case 'game.saveFailed': return '저장에 실패했습니다. 다시 시도해 주세요.';
			case 'game.selectSuspect': return '마니또로 의심되는 친구를 선택하세요';
			case 'game.addPhotoPrompt': return '사진을 첨부해 주세요';
			case 'game.addTextPrompt': return '내용을 입력해 주세요';
			case 'game.validationPhotoPerform': return '💡 [미션 기록] 탭에 인증 사진을 1장 이상 첨부해 주세요!';
			case 'game.validationSuspect': return '💡 [마니또 추측] 탭에서 마니또로 의심되는 친구를 선택해 주세요!';
			case 'game.validationPhotoGuess': return '💡 [마니또 추측] 탭에 사진 단서를 1장 이상 첨부해 주세요!';
			case 'game.deadlineBanner': return '마감 시간';
			case 'feed.title': return '기록 상세';
			case 'feed.tabFeed': return '피드';
			case 'feed.tabComments': return '댓글';
			case 'feed.commentPlaceholder': return '댓글을 입력하세요...';
			case 'feed.noComments': return '첫 댓글을 남겨보세요!';
			case 'feed.send': return '전송';
			case 'feed.authorManito': return '내 마니또';
			case 'feed.targetAgent': return '대상 요원';
			case 'feed.guessSuccess': return '추측 성공! 🎉';
			case 'feed.guessFailed': return '추측 실패! 🕵️';
			case 'friends.title': return '친구';
			case 'friends.search': return '친구 찾기';
			case 'friends.searchHint': return '친구의 고유 코드를 입력하세요';
			case 'friends.sendRequest': return '친구 요청';
			case 'friends.requestSent': return '친구 요청을 보냈습니다!';
			case 'friends.receivedRequests': return '받은 친구 요청';
			case 'friends.acceptedFriends': return '친구 목록';
			case 'friends.noFriends': return '등록된 친구가 없습니다';
			case 'friends.noRequests': return '받은 요청이 없습니다';
			case 'friends.deleteFriend': return '친구 삭제';
			case 'friends.deleteConfirm': return '정말 친구를 삭제하시겠습니까?';
			case 'profile.title': return '프로필';
			case 'profile.edit': return '프로필 수정';
			case 'profile.name': return '이름';
			case 'profile.statusMessage': return '상태 메시지';
			case 'profile.uniqueCode': return '내 고유 코드';
			case 'profile.copyCode': return '코드 복사';
			case 'settings.title': return '설정';
			case 'settings.theme': return '테마 설정';
			case 'settings.themeSystem': return '시스템 설정 따름';
			case 'settings.themeLight': return '라이트 모드';
			case 'settings.themeDark': return '다크 모드';
			case 'settings.language': return '언어 설정 (Language)';
			case 'settings.langKo': return '한국어';
			case 'settings.langEn': return 'English';
			case 'settings.contact': return '문의하기';
			case 'settings.terms': return '이용약관';
			case 'settings.privacy': return '개인정보 처리방침';
			case 'settings.logout': return '로그아웃';
			case 'settings.deleteAccount': return '회원 탈퇴';
			case 'settings.deleteAccountConfirmTitle': return '회원 탈퇴';
			case 'settings.deleteAccountConfirmMessage': return '회원 탈퇴 시 모든 친구 관계, 마니또 기록, 프로필 정보가 영구 삭제되며 복구할 수 없습니다.\n\n정말 탈퇴하시겠습니까?';
			case 'settings.version': return '앱 버전';
			default: return null;
		}
	}
}

extension on _StringsEn {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.appName': return 'Manito';
			case 'common.confirm': return 'Confirm';
			case 'common.cancel': return 'Cancel';
			case 'common.save': return 'Save';
			case 'common.delete': return 'Delete';
			case 'common.edit': return 'Edit';
			case 'common.close': return 'Close';
			case 'common.retry': return 'Retry';
			case 'common.error': return 'Error';
			case 'common.success': return 'Success';
			case 'common.loading': return 'Loading...';
			case 'common.copySuccess': return 'Copied to clipboard.';
			case 'common.networkErrorTitle': return 'Please check your network connection';
			case 'common.networkErrorRetry': return 'Retry';
			case 'auth.loginTitle': return 'Secret Manito Operation';
			case 'auth.loginSubtitle': return 'Play Secret Santa & Manito with your friends';
			case 'auth.kakaoLogin': return 'Continue with Kakao';
			case 'auth.appleLogin': return 'Continue with Apple';
			case 'auth.googleLogin': return 'Continue with Google';
			case 'auth.loginFailed': return 'Login failed. Please try again.';
			case 'auth.logoutConfirmTitle': return 'Log Out';
			case 'auth.logoutConfirmMessage': return 'Are you sure you want to log out?';
			case 'home.title': return 'Manito';
			case 'home.tabHome': return 'Home';
			case 'home.tabChat': return 'Chat';
			case 'home.tabArchive': return 'Archive';
			case 'home.tabFriends': return 'Friends';
			case 'home.tabProfile': return 'Profile';
			case 'home.ongoingTitle': return 'Ongoing Games';
			case 'home.invitationTitle': return 'Invitations Received';
			case 'home.createRoom': return 'Create New Room';
			case 'home.noOngoing': return 'No active Manito games right now';
			case 'home.noInvitations': return 'No invitations received';
			case 'home.accept': return 'Accept';
			case 'home.decline': return 'Decline';
			case 'chat.title': return 'Chat';
			case 'chat.newChat': return 'New Chat';
			case 'chat.searchHint': return 'Search by friend name or code';
			case 'chat.groupTitleHint': return 'Group chat title (optional)';
			case 'chat.startDirect': return 'Start 1:1 Chat';
			case 'chat.startGroup': return 'Start Group Chat ({count})';
			case 'chat.emptyChats': return 'No active chats right now.';
			case 'chat.emptyChatsDesc': return 'Select a friend to start a 1:1 or group chat!';
			case 'chat.firstMessageDesc': return 'Send the first message to start the conversation!';
			case 'chat.leaveRoom': return 'Leave Chat Room';
			case 'chat.leaveConfirmTitle': return 'Leave Chat Room';
			case 'chat.leaveConfirmMessage': return 'Leaving the room will delete all messages and remove it from your chat list.\n\nAre you sure you want to leave?';
			case 'chat.drawerTitle': return 'Chat Drawer';
			case 'chat.members': return 'Participants';
			case 'chat.me': return 'Me';
			case 'chat.yesterday': return 'Yesterday';
			case 'lobby.title': return 'Waiting Room';
			case 'lobby.hostBadge': return 'Host';
			case 'lobby.roomTitleLabel': return 'Title';
			case 'lobby.editTitle': return 'Edit Title';
			case 'lobby.categoryLabel': return 'Mission Category';
			case 'lobby.categoryDaily': return 'Daily';
			case 'lobby.categorySchool': return 'School';
			case 'lobby.categoryWork': return 'Work';
			case 'lobby.deadlineLabel': return 'Deadline';
			case 'lobby.setDeadline': return 'Set Deadline';
			case 'lobby.membersTitle': return 'Agents Joined';
			case 'lobby.inviteFriends': return 'Invite Friends';
			case 'lobby.startGame': return 'Start Manito Game';
			case 'lobby.minMembersRequired': return 'At least 2 participating members required';
			case 'lobby.leaveRoom': return 'Leave Room';
			case 'lobby.deleteRoom': return 'Delete & Leave Room';
			case 'lobby.leaveConfirm': return 'Are you sure you want to leave the waiting room?';
			case 'lobby.deleteConfirm': return 'Deleting the room will cancel all invitations.';
			case 'missionSetup.title': return 'Select Manito Mission';
			case 'missionSetup.timerLabel': return 'Selection Time Limit';
			case 'missionSetup.friendsSelecting': return 'Other friends are choosing missions...';
			case 'missionSetup.targetConfidential': return 'You are {name}\'s Manito';
			case 'missionSetup.selectMission': return 'Choose Mission';
			case 'missionSetup.confirmSelection': return 'Confirm Selection';
			case 'missionSetup.selectionComplete': return 'Mission Confirmed';
			case 'game.tabMissionPerform': return 'Mission Log';
			case 'game.tabSuspectGuess': return 'Guess Manito';
			case 'game.save': return 'Save';
			case 'game.saveSuccess': return 'Mission proof and guess saved successfully!';
			case 'game.saveFailed': return 'Failed to save. Please try again.';
			case 'game.selectSuspect': return 'Select who you suspect is your Manito';
			case 'game.addPhotoPrompt': return 'Attach a photo';
			case 'game.addTextPrompt': return 'Enter description';
			case 'game.validationPhotoPerform': return '💡 Please attach at least 1 photo in [Mission Log] tab!';
			case 'game.validationSuspect': return '💡 Please select your suspected Manito in [Guess Manito] tab!';
			case 'game.validationPhotoGuess': return '💡 Please attach at least 1 photo clue in [Guess Manito] tab!';
			case 'game.deadlineBanner': return 'Deadline';
			case 'feed.title': return 'Game Results';
			case 'feed.tabFeed': return 'Feed';
			case 'feed.tabComments': return 'Comments';
			case 'feed.commentPlaceholder': return 'Write a comment...';
			case 'feed.noComments': return 'Be the first to comment!';
			case 'feed.send': return 'Send';
			case 'feed.authorManito': return 'My Manito';
			case 'feed.targetAgent': return 'Target Agent';
			case 'feed.guessSuccess': return 'Guess Correct! 🎉';
			case 'feed.guessFailed': return 'Guess Failed! 🕵️';
			case 'friends.title': return 'Friends';
			case 'friends.search': return 'Find Friends';
			case 'friends.searchHint': return 'Enter friend\'s unique code';
			case 'friends.sendRequest': return 'Send Request';
			case 'friends.requestSent': return 'Friend request sent!';
			case 'friends.receivedRequests': return 'Received Requests';
			case 'friends.acceptedFriends': return 'Friend List';
			case 'friends.noFriends': return 'No friends added yet';
			case 'friends.noRequests': return 'No friend requests';
			case 'friends.deleteFriend': return 'Remove Friend';
			case 'friends.deleteConfirm': return 'Are you sure you want to remove this friend?';
			case 'profile.title': return 'Profile';
			case 'profile.edit': return 'Edit Profile';
			case 'profile.name': return 'Name';
			case 'profile.statusMessage': return 'Status Message';
			case 'profile.uniqueCode': return 'My Unique Code';
			case 'profile.copyCode': return 'Copy Code';
			case 'settings.title': return 'Settings';
			case 'settings.theme': return 'Theme Mode';
			case 'settings.themeSystem': return 'System Default';
			case 'settings.themeLight': return 'Light Mode';
			case 'settings.themeDark': return 'Dark Mode';
			case 'settings.language': return 'Language';
			case 'settings.langKo': return '한국어 (Korean)';
			case 'settings.langEn': return 'English';
			case 'settings.contact': return 'Contact Support';
			case 'settings.terms': return 'Terms of Service';
			case 'settings.privacy': return 'Privacy Policy';
			case 'settings.logout': return 'Log Out';
			case 'settings.deleteAccount': return 'Delete Account';
			case 'settings.deleteAccountConfirmTitle': return 'Delete Account';
			case 'settings.deleteAccountConfirmMessage': return 'Deleting your account will permanently remove all friend relations, game records, and profile data.\n\nAre you sure you want to delete your account?';
			case 'settings.version': return 'App Version';
			default: return null;
		}
	}
}
