import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareSvga(
  BuildContext context, {
  required String svgaFilePath,
  required int backgroundColorValue,
  required String? backgroundImagePath,
}) async {
  try {
    // 1. Get temporary directory for saving files
    final tempDir = await getTemporaryDirectory();
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final appDir = Directory('${tempDir.path}/svga_player_app_$uniqueId');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    // 2. Get SVGA file data from assets
    final svgaData = await rootBundle.load(svgaFilePath);
    final svgaFileBytes = svgaData.buffer.asUint8List();
    final svgaFileName = svgaFilePath.split('/').last;

    // 3. Create metadata.json file
    final metadata = {
      'backgroundColor': backgroundColorValue,
      'backgroundImagePath': backgroundImagePath,
      'svgaFileName': svgaFileName,
    };
    final metadataJson = jsonEncode(metadata);
    final metadataFile = File('${appDir.path}/metadata.json');
    await metadataFile.writeAsString(metadataJson);

    // 4. Create the ZIP archive
    final archive = Archive();
    archive.addFile(ArchiveFile(svgaFileName, svgaFileBytes.length, svgaFileBytes));
    archive.addFile(ArchiveFile('metadata.json', metadataFile.lengthSync(), await metadataFile.readAsBytes()));

    // 5. If there's a background image, add it to the archive
    if (backgroundImagePath != null) {
      final bgData = await rootBundle.load(backgroundImagePath);
      final bgFileBytes = bgData.buffer.asUint8List();
      final bgFileName = backgroundImagePath.split('/').last;
      archive.addFile(ArchiveFile(bgFileName, bgFileBytes.length, bgFileBytes));
    }

    // 6. Encode the archive to a zip file
    final zipFileBytes = ZipEncoder().encode(archive);
    final zipFilePath = '${tempDir.path}/$svgaFileName.zip';
    final zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(zipFileBytes!);

    // 7. Share the zip file
    await Share.shareXFiles([XFile(zipFile.path)]);

  } catch (e) {
    print('Error saving and sharing SVGA: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to share file: $e')),
    );
  }
}
