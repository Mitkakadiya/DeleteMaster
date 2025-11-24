import 'dart:io';

import 'package:delete/image_preview_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

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
    final albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);
    if (albums.isNotEmpty) {
      final recent = albums.first;
      final media = await recent.getAssetListPaged(page: 0, size: 500);
      setState(() {
        images = media;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delete Master")),
      body: images.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                return FutureBuilder(
                  future: img.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 1));
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImagePreviewPage(images: images, index: index),
                          ),
                        );
                        setState(() {

                        });
                      },
                      child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                    );
                  },
                );
              },
            ),
    );
  }
}
