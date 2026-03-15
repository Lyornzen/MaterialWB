import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 微博视频播放器组件（基于 media_kit / FFmpeg）
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
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _showControls = true;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final player = Player();
    _player = player;
    _videoController = VideoController(player);

    // 监听播放状态
    player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });

    player.stream.position.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    player.stream.duration.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    player.stream.error.listen((error) {
      if (!mounted) return;
      if (error.toString().isNotEmpty) {
        setState(() => _hasError = true);
      }
    });

    try {
      await player.open(
        Media(
          widget.videoUrl,
          httpHeaders: {
            'Referer': 'https://weibo.com/',
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 '
                    '(KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
          },
        ),
      );
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      // 某些源不接受自定义请求头，回退为无 header 直连
      try {
        await player.open(Media(widget.videoUrl));
        if (!mounted) return;
        setState(() => _isInitialized = true);
      } catch (_) {
        if (!mounted) return;
        setState(() => _hasError = true);
      }
    }
  }

  void _togglePlayPause() {
    final player = _player;
    if (player == null || !_isInitialized) return;

    setState(() => _showControls = true);
    player.playOrPause();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isInitialized && _videoController != null
            ? _buildPlayer(Theme.of(context).colorScheme)
            : _buildThumbnail(Theme.of(context).colorScheme),
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
              placeholder: (_, __) =>
                  Container(color: colorScheme.surfaceContainerHighest),
              errorWidget: (_, __, ___) => Container(
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
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Video(controller: _videoController!, controls: NoVideoControls),

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
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: colorScheme.primary,
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds /
                                        _duration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (value * _duration.inMilliseconds)
                                  .round(),
                            );
                            _player?.seek(newPosition);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final player = _player;
                        if (player == null) return;
                        // Toggle volume
                        if (player.state.volume > 0) {
                          player.setVolume(0);
                        } else {
                          player.setVolume(100);
                        }
                        setState(() {});
                      },
                      child: Icon(
                        (_player?.state.volume ?? 0) > 0
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
