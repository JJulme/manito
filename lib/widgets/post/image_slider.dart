import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:manito/constants.dart';

/// 이미지 슬라이더
class ImageSlider extends StatefulWidget {
  final List<dynamic> images;
  final double width;
  final BoxFit fit;

  const ImageSlider({
    super.key,
    required this.images,
    required this.width,
    required this.fit,
  });

  @override
  _ImageSliderState createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            final image = widget.images[index];
            return Container(
              width: widget.width,
              height: widget.width,
              color: Colors.grey[100],
              margin: EdgeInsets.all(0.005 * widget.width),
              child: Image(
                image: CachedNetworkImageProvider(image),
                fit: widget.fit,
              ),
            );
          },
          options: CarouselOptions(
            enableInfiniteScroll: false,
            viewportFraction: 1,
            height: widget.width,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        SizedBox(height: 8), // 인디케이터와 슬라이더 간의 간격
        if (widget.images.length > 1)
          _buildIndicator(), // 이미지가 1개 이상일 때만 인디케이터 표시
      ],
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.images.length, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          width: _currentIndex == index ? 12.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index ? kOffBlack : kGrey,
          ),
        );
      }),
    );
  }
}
