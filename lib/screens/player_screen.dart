import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';
import 'package:svga_player_app/utils/save_and_share.dart';

class PlayerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PlayerScreen({super.key, required this.filePath, required this.fileName});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  SVGAAnimationController? _controller;
  Color _backgroundColor = Colors.white;
  String? _backgroundImagePath;
  bool _isLooping = true;
  bool _isPlaying = true;

  final List<String> _backgroundImages = [
    'assets/backgrounds/bg_1.jpg',
    'assets/backgrounds/bg_2.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedBackground();
  }

  Future<void> _loadSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColorValue = prefs.getInt('bg_color_${widget.fileName}');
    final savedImagePath = prefs.getString('bg_image_${widget.fileName}');

    setState(() {
      if (savedColorValue != null) {
        _backgroundColor = Color(savedColorValue);
        _backgroundImagePath = null;
      } else if (savedImagePath != null) {
        _backgroundImagePath = savedImagePath;
      }
    });
  }

  Future<void> _saveBackground() async {
    final prefs = await SharedPreferences.getInstance();
    if (_backgroundImagePath != null) {
      await prefs.setString('bg_image_${widget.fileName}', _backgroundImagePath!);
      await prefs.remove('bg_color_${widget.fileName}');
    } else {
      await prefs.setInt('bg_color_${widget.fileName}', _backgroundColor.value);
      await prefs.remove('bg_image_${widget.fileName}');
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _backgroundColor,
              onColorChanged: (color) {
                setState(() {
                  _backgroundColor = color;
                  _backgroundImagePath = null;
                });
                _saveBackground();
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName.replaceAll('.svga', '')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => saveAndShareSvga(
              context,
              svgaFilePath: widget.filePath,
              backgroundColorValue: _backgroundColor.value,
              backgroundImagePath: _backgroundImagePath,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          if (_backgroundImagePath != null)
            Positioned.fill(
              child: Image.asset(
                _backgroundImagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
              ),
            )
          else
            Positioned.fill(child: Container(color: _backgroundColor)),

          // SVGA Player
          Center(
            child: SVGAPlayer(
              fileUrl: widget.filePath,
              onPlayerReady: (controller) {
                _controller = controller;
                _controller!.loops = _isLooping ? 0 : 1;
                if (_isPlaying) {
                  _controller!.startAnimation();
                }
              },
            ),
          ),

          // Controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            if (_isPlaying) {
                              _controller?.startAnimation();
                            } else {
                              _controller?.pauseAnimation();
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay),
                        onPressed: () {
                          _controller?.stopAnimation(true);
                          _controller?.startAnimation();
                        },
                      ),
                      IconButton(
                        icon: Icon(_isLooping ? Icons.repeat : Icons.repeat_one),
                        onPressed: () {
                          setState(() {
                            _isLooping = !_isLooping;
                            _controller?.loops = _isLooping ? 0 : 1;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      // Background options
                      GestureDetector(
                        onTap: _showColorPicker,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            shape: BoxShape.circle,
                            border: _backgroundImagePath == null
                                ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Background Image selector
                      ..._backgroundImages.map((imagePath) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _backgroundImagePath = imagePath;
                            });
                            _saveBackground();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: _backgroundImagePath == imagePath
                                  ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                                  : null,
                              image: DecorationImage(
                                image: AssetImage(imagePath),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
