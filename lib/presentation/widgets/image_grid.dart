import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// 九宫格图片组件
class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int maxCount;

  /// 当图片被查看时的回调（用于记录浏览历史）
  final VoidCallback? onImageViewed;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.maxCount = 9,
    this.onImageViewed,
  });

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.take(maxCount).toList();
    final count = urls.length;

    if (count == 0) return const SizedBox.shrink();

    // 单张图片
    if (count == 1) {
      return _buildSingleImage(context, urls[0], 0);
    }

    // 多张图片网格
    final crossAxisCount = count <= 4 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) =>
          _buildGridImage(context, urls[index], index),
    );
  }

  Widget _buildSingleImage(BuildContext context, String url, int index) {
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, _, _) => Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridImage(BuildContext context, String url, int index) {
    return GestureDetector(
      onTap: () => _openGallery(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          errorWidget: (_, _, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    onImageViewed?.call();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _ImageGalleryPage(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }
}

/// 全屏图片画廊
class _ImageGalleryPage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageGalleryPage({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: PhotoViewGallery.builder(
        pageController: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          );
        },
        loadingBuilder: (context, event) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
