import 'package:flutter/material.dart';

enum ManitoMascotType {
  /// 기본 강아지 마스코트
  standard('assets/images/manito_dog.png', '기본 마스코트'),

  /// 폰 들고 연락하는 강아지 (초대, 알림, 대기)
  phone('assets/images/manito_dog_phone.png', '연락 및 초대'),

  /// 고민하고 생각하는 강아지 (미션 선택, 타이머, 대기)
  thinking('assets/images/manito_dog_thinking.png', '고민 및 미션 선택'),

  /// 선글라스 낀 비밀 요원 강아지 (미션 수행, 비밀 미션)
  sunglass('assets/images/manito_dog_sunglass.png', '비밀 요원 미션'),

  /// 셀카/사진 찍는 강아지 (물증 사진, 증거 기록)
  selfie('assets/images/manito_dog_selfie.png', '사진 및 물증 기록'),

  /// 원형 프레임 마스코트 (스플래시, 프로필)
  circle('assets/images/manito_dog_circle.png', '원형 마스코트');

  final String assetPath;
  final String description;

  const ManitoMascotType(this.assetPath, this.description);
}

class ManitoMascot extends StatelessWidget {
  final ManitoMascotType type;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ManitoMascot({
    super.key,
    this.type = ManitoMascotType.standard,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  /// Factory constructors for convenient semantic usage
  const ManitoMascot.standard({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.standard;

  const ManitoMascot.phone({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.phone;

  const ManitoMascot.thinking({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.thinking;

  const ManitoMascot.sunglass({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.sunglass;

  const ManitoMascot.selfie({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.selfie;

  const ManitoMascot.circle({super.key, this.width, this.height, this.fit = BoxFit.contain})
      : type = ManitoMascotType.circle;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      type.assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width ?? 80,
          height: height ?? 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets_rounded, color: Colors.grey),
        );
      },
    );
  }
}
