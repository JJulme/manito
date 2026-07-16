import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manito/features/missions/mission_provider.dart';
import 'package:manito/features/theme/theme.dart';
import 'package:manito/main.dart';
import 'package:manito/core/widget/common_dialog.dart';
import 'package:manito/share/sub_appbar.dart';

class MissionGroupCreateScreen extends ConsumerStatefulWidget {
  const MissionGroupCreateScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionGroupCreateScreenState();
}

class _MissionGroupCreateScreenState
    extends ConsumerState<MissionGroupCreateScreen> {
  final _titleFormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  // 토글 버튼
  int _selectedType = 0;
  int _selectedPeriod = 0;

  String? _validateTitle(String? value) {
    // 값이 비어있는지 확인
    if (value == null || value.isEmpty) {
      return '제목을 입력해 주세요.';
    }
    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '제목을 입력해 주세요.';
    }
    return null;
  }

  void _handleBottomButton() async {
    if (_titleFormKey.currentState?.validate() ?? false) {
      final result = await DialogHelper.showConfirmDialog(
        context,
        title: '그룹 미션 생성',
        message: '그룹 미션을 생성하시겠습니까?',
      );
      if (result == true) {
        await ref
            .read(missionGroupRoomCreationActionProvider.notifier)
            .createGroupRoom(
              _titleController.text,
              _selectedType,
              _selectedPeriod,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createAsync = ref.watch(missionGroupRoomCreationActionProvider);
    ref.listen(missionGroupRoomCreationActionProvider, (prev, next) {
      if ((prev?.isLoading == true) &&
          (next.hasError == false) &&
          (next.hasValue)) {
        context.pop();
        context.pushNamed(
          'missionGroupRoom',
          pathParameters: {'roomId': next.value!},
        );
      }
    });
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(title: Text('그룹 미션 생성')),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  Divider(),
                  _buildSectionTitle('타입'),
                  _buildTypeToggle(),
                  Divider(),
                  _buildSectionTitle('기간'),
                  _buildPeriodToggle(),
                ],
              ),
              if (createAsync.isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomButton(createAsync),
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Form(
        key: _titleFormKey,
        child: TextFormField(
          maxLength: 20,
          controller: _titleController,
          validator: (value) => _validateTitle(value),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\n]'))],
          decoration: InputDecoration(labelText: '제목'),
        ),
      ),
    );
  }

  // 타이틀 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Text(title, style: TextTheme.of(context).titleLarge),
    );
  }

  // 타입 토글 버튼
  Widget _buildTypeToggle() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(width * 0.01),
        constraints: BoxConstraints(
          minHeight: width * 0.25,
          minWidth: (width - width * 0.1) / 3,
        ),
        isSelected: [
          _selectedType == 0,
          _selectedType == 1,
          _selectedType == 2,
        ],
        onPressed: (index) => setState(() => _selectedType = index),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sunny),
              Text("일상", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded),
              Text("학교", textAlign: TextAlign.center),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work),
              Text("직장", textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  // 기간 토글 버튼
  Widget _buildPeriodToggle() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(width * 0.01),
        constraints: BoxConstraints(
          minHeight: width * 0.25,
          minWidth: (width - width * 0.1) / 2,
        ),
        isSelected: [_selectedPeriod == 0, _selectedPeriod == 1],
        onPressed: (index) => setState(() => _selectedPeriod = index),
        children: [
          Text(
            "1시간",
            textAlign: TextAlign.center,
            style: TextTheme.of(context).bodyLarge,
          ),
          Text(
            "3시간",
            textAlign: TextAlign.center,
            style: TextTheme.of(context).bodyLarge,
          ),
        ],
      ),
    );
  }

  // 바텀 버튼
  Widget _buildBottomButton(AsyncValue<void> createAsync) {
    return BottomAppBar(
      child: Container(
        margin: EdgeInsets.zero,
        child:
            createAsync.isLoading
                ? ElevatedButton(
                  onPressed: null,
                  child: CircularProgressIndicator(),
                )
                : ElevatedButton(
                  onPressed: () => _handleBottomButton(),
                  child: Text(
                    '생성하기',
                    style: TextStyle(
                      color: kOffBlack,
                      fontSize: TextTheme.of(context).titleLarge!.fontSize,
                    ),
                  ),
                ),
      ),
    );
  }

  // 로딩중 입력 방지
  Widget _buildLoadingOverlay() {
    return ModalBarrier(
      dismissible: false,
      color: Colors.black.withAlpha((0.5 * 255).round()),
    );
  }
}
