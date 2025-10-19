import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manito/features/manito/manito.dart';
import 'package:manito/features/manito/manito_provider.dart';
import 'package:manito/share/custom_toast.dart';
import 'package:manito/core/constants.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final ManitoAccept manitoAccept;
  const AlbumScreen({super.key, required this.manitoAccept});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  // 모든 사진의 정보를 저장
  final List<AssetEntity> _photos = [];
  // 모든 사진의 썸네일 저장
  final Map<String, Uint8List?> _thumbnailCache = {};
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  // 선택 순서를 저장 (AssetId -> 순서)
  final Map<String, int> _selectedOrder = {};

  final int _pageSize = 60;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
    _scrollController.addListener(_onScroll);

    // 초기 선택 이미지의 순서 저장
    final initialAssets =
        ref.read(manitoPostProvider(widget.manitoAccept)).selectedImages;
    for (int i = 0; i < initialAssets.length; i++) {
      _selectedOrder[initialAssets[i].id] = i + 1;
    }
  }

  Future<void> _requestPermissionAndLoad() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      await _loadPhotos();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _loadPhotos() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // 앨범 가져오기
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    // 사진이 하나도 없는 경우
    if (albums.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    final recentAlbum = albums.first;
    final newPhotos = await recentAlbum.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );
    // 썸네일 저장
    for (final photo in newPhotos) {
      final data = await photo.thumbnailDataWithSize(
        const ThumbnailSize(200, 200),
      );
      if (data != null) {
        _thumbnailCache[photo.id] = data;
      }
    }

    if (mounted) {
      setState(() {
        _photos.addAll(newPhotos);
        _hasMore = newPhotos.length == _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadPhotos();
    }
  }

  // 선택 토글 순서 계산 동작 함수
  void _toggleSelect(double width, String assetId) {
    // 이미 선택된 경우: 제거하고 이후 번호들을 당김
    if (_selectedOrder.containsKey(assetId)) {
      final removedOrder = _selectedOrder[assetId]!;
      _selectedOrder.remove(assetId);

      // 제거된 번호보다 큰 번호들을 1씩 감소
      final updatedOrder = <String, int>{};
      _selectedOrder.forEach((key, value) {
        if (value > removedOrder) {
          updatedOrder[key] = value - 1;
        } else {
          updatedOrder[key] = value;
        }
      });
      _selectedOrder.clear();
      _selectedOrder.addAll(updatedOrder);
    } else if (_selectedOrder.length >= 6) {
      customToast(width: width, msg: '최대 6개까지 선택');
    }
    // 새로 선택하는 경우: 다음 번호 부여
    else {
      final nextOrder =
          _selectedOrder.isEmpty
              ? 1
              : _selectedOrder.values.reduce((a, b) => a > b ? a : b) + 1;
      _selectedOrder[assetId] = nextOrder;
    }
  }

  void _onComplete() {
    // 순서대로 정렬하여 반환
    final sortedEntries =
        _selectedOrder.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    final selectedAssets =
        sortedEntries
            .map(
              (entry) => _photos.firstWhere((photo) => photo.id == entry.key),
            )
            .toList();
    // 프로바이더에서 넘겨주는 코드 실행
    ref
        .read(manitoPostProvider(widget.manitoAccept).notifier)
        .addImages(selectedAssets);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(appBar: _buildAppBar(), body: _buildBody(width));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      actions: [
        TextButton(
          onPressed: _selectedOrder.isEmpty ? null : _onComplete,
          child:
              _selectedOrder.isEmpty
                  ? Text('선택', style: Theme.of(context).textTheme.labelLarge)
                  : Text(
                    '${_selectedOrder.length} 선택',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
        ),
      ],
    );
  }

  Widget _buildBody(double width) {
    if (_isLoading && _photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (_photos.isEmpty) {
      return const Center(child: Text('이미지가 없습니다.'));
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 0.008 * width,
        crossAxisSpacing: 0.008 * width,
      ),
      itemCount: _photos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 추가로 사진 로딩
        if (index == _photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final photo = _photos[index];

        return _PhotoGridItem(
          key: ValueKey(photo.id),
          photo: photo,
          thumnailData: _thumbnailCache[photo.id],
          selectedOrder: _selectedOrder[photo.id],
          onToggle: () {
            setState(() {
              _toggleSelect(width, photo.id);
            });
          },
        );
      },
    );
  }
}

// 개별 그리드 아이템
class _PhotoGridItem extends StatelessWidget {
  final AssetEntity photo;
  final Uint8List? thumnailData;
  final int? selectedOrder; // null이면 선택 안됨
  final VoidCallback onToggle;

  const _PhotoGridItem({
    required super.key,
    required this.photo,
    required this.thumnailData,
    required this.selectedOrder,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final isSelected = selectedOrder != null;

    return GestureDetector(
      onTap: onToggle,
      child:
          thumnailData == null
              ? const ColoredBox(color: Colors.black12)
              : Stack(
                fit: StackFit.expand,
                children: [
                  // 이미지
                  Image.memory(thumnailData!, fit: BoxFit.cover),

                  // 선택 오버레이 테두리
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(color: kYellow, width: 3),
                      ),
                    ),

                  // 순서 번호
                  Positioned(
                    top: width * 0.015,
                    right: width * 0.015,
                    child: Container(
                      width: width * 0.065,
                      height: width * 0.065,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? kYellow
                                : Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? kYellow : Colors.white60,
                          width: width * 0.008,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            isSelected
                                ? Text(
                                  '$selectedOrder',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
