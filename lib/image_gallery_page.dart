import 'dart:io';

import 'package:delete/image_preview_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'colors.dart';

class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({super.key});

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  List<AssetEntity> images = [];

  @override
  void initState() {
    super.initState();
    requestPermissionAndLoad();
  }

  Future<void> requestPermissionAndLoad() async {
    PermissionStatus permission;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+
        permission = await Permission.photos.request();
      } else {
        // Android 12 and below
        permission = await Permission.storage.request();
      }
    } else {
      // iOS
      permission = await Permission.photos.request();
    }

    if (permission.isGranted || permission.isLimited) {
      await loadImages();
    } else {
      openAppSettings(); // user denied
    }
  }

  Future<void> loadImages() async {
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (albums.isNotEmpty) {
      final recent = albums.first;
      final media = await recent.getAssetListPaged(page: 0, size: 500);
      setState(() {
        images = media;
      });
    }
  }

  bool selectionMode = false;
  Set<int> selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Delete Master",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: color00C853,
        actions: [
          if (selectionMode)
            IconButton(
              onPressed: deleteSelectedImages,
              icon: const Icon(Icons.delete, color: Colors.white),
            ),
        ],
      ),
      backgroundColor: colorF4F7F6,
      body: images.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                bool isSelected = selectedIndexes.contains(index);
                return FutureBuilder(
                  future: img.thumbnailDataWithSize(
                    const ThumbnailSize(200, 200),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 1),
                      );
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (selectionMode) {
                          setState(() {
                            if (isSelected) {
                              selectedIndexes.remove(index);
                              if (selectedIndexes.isEmpty) {
                                selectionMode = false;
                              }
                            } else {
                              selectedIndexes.add(index);
                            }
                          });
                          return;
                        }
                        else {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ImagePreviewPage(images: images, index: index),
                            ),
                          );
                          setState(() {});
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          selectionMode = true;
                          selectedIndexes.add(index);
                        });
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> deleteSelectedImages() async {
    try {
      List<int> sorted = selectedIndexes.toList()
        ..sort((a, b) => b.compareTo(a)); // delete from end

      for (int index in sorted) {
        final photoToDelete = images[index];
        final result = await PhotoManager.editor.deleteWithIds([
          photoToDelete.id,
        ]);
        if (result.isNotEmpty) {
          images.removeAt(index);
        }
      }
      selectedIndexes.clear();
      selectionMode = false;

      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting photo: $e')));
      }
    }
  }
}
