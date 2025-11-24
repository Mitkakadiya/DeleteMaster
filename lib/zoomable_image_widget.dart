import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ZoomableImageWidget extends StatefulWidget {
  final AssetEntity image;

  const ZoomableImageWidget({super.key, required this.image});

  @override
  State<ZoomableImageWidget> createState() => _ZoomableImageWidgetState();
}

class _ZoomableImageWidgetState extends State<ZoomableImageWidget> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  final double _minScale = 1.0;
  final double _maxScale = 3.0;
  bool _isZoomedIn = false;
  Offset _tapPosition = Offset.zero;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animation = Matrix4Tween(begin: _transformationController.value, end: Matrix4.identity()).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward(from: 0);
    _isZoomedIn = false;
  }

  void _zoomIn(Offset position) {
    final double scale = 2.5;

    final zoomedMatrix = Matrix4.identity()
      ..translateByDouble(-position.dx * (scale - 1), -position.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    _animation = Matrix4Tween(begin: _transformationController.value, end: zoomedMatrix).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward(from: 0);
    _isZoomedIn = true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (TapDownDetails details) {
        _tapPosition = details.localPosition;
      },
      onDoubleTap: () {
        if (_isZoomedIn) {
          _resetZoom();
        } else {
          _zoomIn(_tapPosition);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: _minScale,
        maxScale: _maxScale,
        onInteractionEnd: (ScaleEndDetails details) {
          _isZoomedIn = _transformationController.value.getMaxScaleOnAxis() > 1.0;
        },
        child: Center(
          child: AssetEntityImage(
            widget.image,
            isOriginal: true,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              final expected = loadingProgress.expectedTotalBytes;
              final loaded = loadingProgress.cumulativeBytesLoaded;

              return Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white, value: expected != null ? loaded / expected : null),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image', style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
