import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/missions/mission.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/main.dart';
import 'package:manito/share/constants.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/share/sub_appbar.dart';
import 'package:manito/widgets/friend_grid_list.dart';

class MissionGuessScreen extends ConsumerStatefulWidget {
  final MyMission mission;
  const MissionGuessScreen({super.key, required this.mission});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionGuessScreenState();
}

class _MissionGuessScreenState extends ConsumerState<MissionGuessScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController guessController = TextEditingController();

  String? _validateGuess(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.trim().isEmpty || value.length < 5) {
      return '5글자 이상 입력하세요';
    }
    return null;
  }

  // 추측 업데이트 동작
  Future<void> _handelUpdateMissionGuess() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(missionGuessProvider.notifier)
          .updateMissionGuess(widget.mission.id, guessController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionGuessAsync = ref.watch(missionGuessProvider);

    // 업데이트 성공시
    ref.listen(missionGuessProvider, (prev, next) {
      if (next.hasValue && (prev!.isLoading == true)) {
        context.pop(true);
        customToast(msg: '마니또를 확인해보세요!');
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(title: Text("mission_guess_screen.title").tr()),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeadlineSection(context),
                      SizedBox(height: width * 0.03),
                      FriendGridList(friends: widget.mission.friendProfiles),
                      SizedBox(height: width * 0.03),
                      _buildGuessInput(context),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(missionGuessAsync),
            ],
          ),
        ),
      ),
    );
  }

  // 미션 기한
  Widget _buildDeadlineSection(BuildContext context) {
    final String createdAt = DateFormat(
      'yy.MM.dd HH:mm',
    ).format(widget.mission.createdAt);
    final String deadline = DateFormat(
      'yy.MM.dd HH:mm',
    ).format(widget.mission.deadline);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconMap[widget.mission.contentType],
            size: width * 0.06,
            color: Colors.grey.shade800,
          ),
          SizedBox(width: width * 0.02),
          Text(
            '$createdAt ~ $deadline',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(width: width * 0.08),
        ],
      ),
    );
  }

  // 추측 글 작성 텍스트 필드
  Widget _buildGuessInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: guessController,
          validator: _validateGuess,
          minLines: 2,
          maxLines: null,
          maxLength: 999,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: context.tr("mission_guess_screen.hint_text"),
          ),
        ),
      ),
    );
  }

  // 바텀 버튼
  Widget _buildBottomButton(AsyncValue<void> state) {
    return Container(
      width: double.infinity,
      height: width * 0.13,
      margin: EdgeInsets.symmetric(
        vertical: width * 0.04,
        horizontal: width * 0.04,
      ),
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _handelUpdateMissionGuess(),
        child:
            state.isLoading
                ? CircularProgressIndicator()
                : Text(
                  "mission_guess_screen.bottom_btn",
                  // style: Theme.of(context).textTheme.titleMedium,
                  style: TextStyle(
                    color: kOffBlack,
                    fontSize: TextTheme.of(context).titleMedium!.fontSize,
                  ),
                ).tr(),
      ),
    );
  }
}
