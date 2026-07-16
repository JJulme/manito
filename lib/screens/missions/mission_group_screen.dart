import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/share/sub_appbar.dart';

class MissionGroupScreen extends ConsumerStatefulWidget {
  final String roomId;
  const MissionGroupScreen({super.key, required this.roomId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionGroupScreenState();
}

class _MissionGroupScreenState extends ConsumerState<MissionGroupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubAppbar(title: Text('방장이 만든 제목이 앱바 타이틀')),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.lock_outline), Text('DA1234')],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.sunny), Text('Daily')],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.access_time), Text('1 Hour')],
                  ),
                ),
              ],
            ),
            Text('맨 위줄 방장, 아래줄 참여한 인원 프로필'),
            Text('룸 아이디로 룸 정보 가져오기'),
            Text('룸 아이디로 실시간 접속 유저 정보 가져오기'),
            Text('방장 예외처리 해주기, 시작권한, 삭제권한'),
          ],
        ),
      ),
    );
  }
}
