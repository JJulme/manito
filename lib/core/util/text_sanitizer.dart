class TextSanitizer {
  TextSanitizer._();

  /// 단일 줄 텍스트 정제 (닉네임, 방 제목, 상태 메시지 등)
  /// - 앞뒤 공백 완전 제거 (trim)
  /// - 줄바꿈 문자 제거 (공백으로 치환)
  /// - 2개 이상의 연속된 공백/탭을 1개의 공백(' ')으로 치환
  ///
  /// 예: "     철수     " -> "철수"
  /// 예: "마니또     게임     방" -> "마니또 게임 방"
  static String sanitizeSingleLine(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  /// 다중 줄 텍스트 정제 (댓글, 자동응답 메시지, 미션/추측 기록 본문 등)
  /// - 전체 텍스트 앞뒤 공백 제거 (trim)
  /// - 각 줄의 앞뒤 불필요한 공백 제거 및 연속 공백을 1칸으로 치환
  /// - 3개 이상의 연속 줄바꿈(\n\n\n...)을 최대 2개(\n\n, 빈 줄 1줄)로 압축
  ///
  /// 예: "     안녕하세요     \n\n\n\n\n     반갑습니다     " -> "안녕하세요\n\n반갑습니다"
  static String sanitizeMultiLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    return trimmed
        .split('\n')
        .map((line) => line.trim().replaceAll(RegExp(r'[ \t]{2,}'), ' '))
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// 텍스트가 의미 있는 내용을 담고 있는지 검증 (공백/줄바꿈만 있는 경우 false)
  static bool isMeaningful(String? text) {
    if (text == null) return false;
    return text.trim().isNotEmpty;
  }
}
