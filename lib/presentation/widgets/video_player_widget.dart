import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 微博视频播放器组件
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
      });
      controller.addListener(_onPlayerStateChanged);
      await controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted) return;
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _isPlaying) {
      setState(() {
        _isPlaying = playing;
      });
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    setState(() {
      _showControls = true;
    });

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      // If video has ended, seek to beginning
      if (controller.value.position >= controller.value.duration) {
        controller.seekTo(Duration.zero);
      }
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller!.value.aspectRatio : 16 / 9,
        child: _isInitialized
            ? _buildPlayer(colorScheme)
            : _buildThumbnail(colorScheme),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _hasError ? null : _initializePlayer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 封面图
          if (widget.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, _a) =>
                  Container(color: colorScheme.surfaceContainerHighest),
              errorWidget: (_, _a, _b) => Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.videocam,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.videocam,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

          // 半透明遮罩
          Container(color: Colors.black26),

          // 播放按钮或错误提示
          if (_hasError)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 8),
                Text('视频加载失败', style: TextStyle(color: colorScheme.onError)),
              ],
            )
          else
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                size: 36,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayer(ColorScheme colorScheme) {
    final controller = _controller!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),

          // 播放/暂停覆盖
          if (_showControls || !_isPlaying)
            GestureDetector(
              onTap: _togglePlayPause,
              child: AnimatedOpacity(
                opacity: (_showControls || !_isPlaying) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // 底部进度条
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black38,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: controller,
                      builder: (_, value, _a) {
                        return Text(
                          '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: colorScheme.primary,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        controller.setVolume(
                          controller.value.volume > 0 ? 0 : 1,
                        );
                        setState(() {});
                      },
                      child: Icon(
                        controller.value.volume > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
