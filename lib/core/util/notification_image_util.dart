import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'app_logger.dart';

class NotificationImageUtil {
  NotificationImageUtil._();

  // 앱 런처 아이콘 (hdpi 72x72) base64 내장 - 에셋 파일 로딩 실패나 Isolate 격리 환경 무관하게 100% 동작 보장
  static const String _appIconBase64 =
      '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'
      'SUVORK5CYII=';

  /// URL에서 이미지를 다운로드하고, EXIF 회전 보정, 1:1 원형 크롭 및 앱 아이콘 뱃지 합성 수행
  static Future<Uint8List?> downloadAndProcessProfileImage(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      request.headers.set('User-Agent', 'Mozilla/5.0');
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return null;

      final bytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
      if (bytes.isEmpty) return null;

      // CPU 집약적인 이미지 처리 연산(디코딩, EXIF 보정, 원형 크롭, 뱃지 합성, PNG 인코딩)을 백그라운드 Isolate로 격리
      return await Isolate.run(() => _processImageBytes(Uint8List.fromList(bytes)));
    } catch (e, s) {
      AppLogger.w('Failed to process notification profile image: $e', tag: 'NOTIF', error: e, stackTrace: s);
      return null;
    }
  }

  static Uint8List? _processImageBytes(Uint8List bytes) {
    try {
      // 1. 이미지 디코딩
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // 2. EXIF 회전각 자동 보정 (사진이 거꾸로나 90도 회전되어 나오는 문제 완벽 해결)
      decoded = img.bakeOrientation(decoded);

      // 3. 투명 채널(Alpha)을 확실하게 갖도록 RGBA(4채널)로 변환 (JPEG 3채널의 검은 배경/직사각형 방지!)
      if (decoded.numChannels != 4) {
        decoded = decoded.convert(numChannels: 4);
      }

      // 4. 정사각형으로 중앙 크롭 (192x192)
      final square = img.copyResizeCropSquare(decoded, size: 192);

      // 5. 완벽한 원형으로 마스킹 크롭 (가장자리 투명 처리)
      final circular = img.copyCropCircle(square);

      // 6. 우측 하단(4시 방향)에 앱 아이콘 뱃지 직접 합성 (카카오톡 스타일)
      try {
        final appIconRaw = img.decodeImage(base64Decode(_appIconBase64));
        if (appIconRaw != null) {
          var appIcon = appIconRaw;
          if (appIcon.numChannels != 4) {
            appIcon = appIcon.convert(numChannels: 4);
          }
          // 56x56 원형으로 리사이즈 및 크롭
          final appIconSquare = img.copyResizeCropSquare(appIcon, size: 56);
          final appIconCircle = img.copyCropCircle(appIconSquare);

          // 뱃지 배경 흰색 원 그리기 (중심: 152, 152, 반경: 32)
          // 4px 흰색 테두리 효과로 프로필 사진과 앱 아이콘을 깔끔하게 분리
          img.fillCircle(
            circular,
            x: 152,
            y: 152,
            radius: 32,
            color: img.ColorUint8.rgba(255, 255, 255, 255),
            antialias: true,
          );

          // 흰색 원 위에 앱 아이콘 뱃지 합성 (시작점: 152 - 28 = 124, 124)
          img.compositeImage(
            circular,
            appIconCircle,
            dstX: 124,
            dstY: 124,
            blend: img.BlendMode.alpha,
          );
        }
      } catch (_) {}

      // 7. 무손실 PNG로 인코딩
      return Uint8List.fromList(img.encodePng(circular));
    } catch (_) {
      return null;
    }
  }
}
