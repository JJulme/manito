import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageSlider extends StatefulWidget {
  final List<dynamic> images;
  final double width;
  final BoxFit? boxFit;

  const ImageSlider({
    super.key,
    required this.images,
    required this.width,
    this.boxFit = BoxFit.cover,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            final image = widget.images[index];
            return Container(
              width: widget.width,
              height: widget.width,
              color: Colors.grey[100],
              margin: EdgeInsets.all(0.01 * widget.width),
              child: _buildImageItem(image, widget.boxFit),
            );
          },
          options: CarouselOptions(
            enableInfiniteScroll: false,
            viewportFraction: 1,
            height: widget.width,
            onPageChanged: (index, reason) {
              _activeIndex = index;
            },
          ),
        ),
        Positioned(
          bottom: 0.02 * widget.width,
          child: Container(
            width: widget.width,
            alignment: Alignment.bottomCenter,
            child: AnimatedSmoothIndicator(
              activeIndex: _activeIndex,
              count: widget.images.length,
              effect: JumpingDotEffect(
                dotWidth: 0.02 * widget.width,
                dotHeight: 0.02 * widget.width,
                activeDotColor: Colors.grey[700]!,
                dotColor: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(dynamic image, BoxFit? boxFit) {
    final fit = boxFit ?? BoxFit.cover;
    if (image is AssetEntity) {
      return AssetEntityImage(image, fit: fit);
    } else if (image is ImageProvider) {
      return Image(image: image, fit: fit);
    } else if (image is String) {
      return Image(image: CachedNetworkImageProvider(image));
    } else {
      // 예상치 못한 타입 처리 (필요에 따라 수정)
      return const SizedBox.shrink();
    }
  }
}
