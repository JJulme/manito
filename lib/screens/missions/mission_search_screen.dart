import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/main.dart';
import 'package:manito/share/sub_appbar.dart';

class MissionSearchScreen extends ConsumerStatefulWidget {
  const MissionSearchScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MissionSearchScreenState();
}

class _MissionSearchScreenState extends ConsumerState<MissionSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  // 입력값 지우기
  void _clearText() {
    codeController.clear();
    // ref.read(friendSearchProvider.notifier).clear();
  }

  Future<void> _searchCode() async {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SubAppbar(title: Text('그룹 미션 찾기')),
        body: SafeArea(child: Column(children: [_buildSearchForm()])),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: codeController,
          onFieldSubmitted: (_) => _searchCode(),
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            labelStyle: Theme.of(context).textTheme.bodyLarge,
            hintText: '그룹 코드',
            hintStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: Icon(Icons.search_rounded, size: width * 0.06),
            suffixIcon: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _clearText,
              icon: Icon(Icons.cancel_rounded, size: width * 0.06),
            ),
          ),
        ),
      ),
    );
  }
}
