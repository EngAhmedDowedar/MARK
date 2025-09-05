import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:svga_player_app/screens/player_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final List<String> _svgaFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSvgaFiles();
  }

  Future<void> _loadSvgaFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final List<String> svgaPaths = manifestMap.keys
          .where((String key) => key.contains('assets/animations/') && key.endsWith('.svga'))
          .toList();
      setState(() {
        _svgaFiles.addAll(svgaPaths);
      });
    } catch (e) {
      print('Error loading assets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVGA Animations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _svgaFiles.isEmpty
          ? const Center(child: Text('No SVGA files found in assets/animations/'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _svgaFiles.length,
              itemBuilder: (context, index) {
                final filePath = _svgaFiles[index];
                final fileName = filePath.split('/').last;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: SVGAPlayer(
                        fileUrl: filePath,
                        onPlayerReady: (player) async {
                          player.loops = 0;
                          player.frame = 1;
                          player.startAnimation();
                        },
                      ),
                    ),
                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(filePath: filePath, fileName: fileName),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
