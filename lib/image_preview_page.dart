import 'package:delete/zoomable_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'colors.dart';

class ImagePreviewPage extends StatefulWidget {
  final List<AssetEntity> images;
  final int index;

  const ImagePreviewPage({super.key, required this.images, required this.index});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: GestureDetector(onTap: () {
          Navigator.pop(context);
        }, child: Icon(Icons.keyboard_arrow_left)),
        backgroundColor: color00C853,
        foregroundColor: Colors.black,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete,color: colorFF0E00,),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return ZoomableImageWidget(
            image: widget.images[index],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to permanently delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCurrentPhoto();
    }
  }

  Future<void> _deleteCurrentPhoto() async {
    try {
      final photoToDelete = widget.images[_currentIndex];
      final result = await PhotoManager.editor.deleteWithIds([photoToDelete.id]);

      if (result.isNotEmpty) {
        widget.images.removeAt(_currentIndex);

        if (widget.images.isEmpty) {
          // No more images, go back
          if (mounted) Navigator.pop(context);
        } else {
          // Adjust current index if needed
          if (_currentIndex >= widget.images.length) {
            _currentIndex = widget.images.length - 1;
          }

          setState(() {});

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo deleted successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting photo: $e')),
        );
      }
    }
  }
}
