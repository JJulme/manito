import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:manito/controllers/chat_controller.dart';
import 'package:manito/controllers/friends_controller.dart';
import 'package:manito/custom_icons.dart';
import 'package:manito/models/message.dart';
import 'package:manito/models/user_profile.dart';
import 'package:manito/widgets/profile/profile_image_view.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatController _controller = Get.put(ChatController());
  final FriendsController _friendsController = Get.find<FriendsController>();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => Get.focusScope?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${_controller.post.deadlineType} / ${_controller.post.content!}',
            style: Get.textTheme.headlineSmall,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  } else if (_controller.messages.isEmpty) {
                    return Center(child: Text('새로운 채팅을 시작해보세요.'));
                  } else {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ListView.separated(
                        separatorBuilder:
                            (context, index) => SizedBox(height: 0.02 * width),
                        reverse: true,
                        shrinkWrap: true,
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          final Message message = _controller.messages[index];
                          final isMine =
                              message.senderId ==
                              _friendsController.userProfile.value!.id;
                          final UserProfile? userProfile = _friendsController
                              .searchFriendProfile(message.senderId);
                          return _ChatBubble(
                            message: message,
                            isMine: isMine,
                            userProfile: userProfile,
                          );
                        },
                      ),
                    );
                  }
                }),
              ),
              _MessageBar(
                messageTextController: _controller.messageTextController,
                onSendPressed: _controller.sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 말풍선
class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final UserProfile? userProfile;
  const _ChatBubble({
    required this.message,
    required this.isMine,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    /// Row 에 들어갈 채팅 버블 내용
    List<Widget> chatContents = [
      if (!isMine)
        profileImageOrDefault(userProfile!.profileImageUrl, 0.1 * width),
      SizedBox(width: 0.02 * width),
      Flexible(
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 0.02 * width,
            horizontal: 0.03 * width,
          ),
          decoration: BoxDecoration(
            color: isMine ? Colors.yellowAccent[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(0.025 * width),
          ),
          child: Text(message.content, style: Get.textTheme.bodySmall),
        ),
      ),
      SizedBox(width: 0.01 * width),
      Text(
        timeago.format(message.createdAt, locale: 'ko'),
        style: Get.textTheme.labelSmall,
      ),
    ];

    /// 내가 보낸거면 보낸시간, 채팅 순
    if (isMine) {
      chatContents = chatContents.reversed.toList();
    }

    /// 니꺼 내꺼 배치 변경
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.03 * width),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chatContents,
      ),
    );
  }
}

/// 채팅 입력창
class _MessageBar extends StatelessWidget {
  final TextEditingController messageTextController;
  final VoidCallback onSendPressed;
  const _MessageBar({
    required this.messageTextController,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.all(0.02 * width),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageTextController,
              minLines: 1,
              maxLines: 3,
              maxLength: 99,
              autofocus: true,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: '메시지 입력',
                hintStyle: Get.textTheme.labelLarge,
                counterText: '',
                contentPadding: EdgeInsets.all(0.02 * width),
              ),
            ),
          ),
          SizedBox(width: 0.02 * width),
          ElevatedButton.icon(
            label: Icon(CustomIcons.send, size: 0.05 * width),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.zero,
              minimumSize: Size(0.1 * width, 0.1 * width),
            ),
            onPressed: onSendPressed,
          ),
        ],
      ),
    );
  }
}
