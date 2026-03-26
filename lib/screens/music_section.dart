import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_meadia_app/models/music.dart';
import 'package:flutter_meadia_app/services/database_service.dart';
import 'package:file_picker/file_picker.dart';

const uuid = Uuid();

class MusicSection extends StatefulWidget {
  const MusicSection({super.key});

  @override
  State<MusicSection> createState() => _MusicSectionState();
}

class _MusicSectionState extends State<MusicSection> {
  late List<Music> musicList = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  Music? _currentlyPlaying;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSeeking = false;
  bool _isCompleted = false;

  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration> _durationSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<void> _completeSubscription;

  @override
  void initState() {
    super.initState();
    _loadMusic();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      PlayerState state,
    ) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.playing) {
          _isCompleted = false;
        }
      });
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((
      Duration duration,
    ) {
      if (!mounted) return;
      setState(() {
        _totalDuration = duration;
      });
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((
      Duration position,
    ) {
      if (!mounted) return;
      if (!_isSeeking) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _isCompleted = true;
      });
    });
  }

  void _loadMusic() {
    setState(() {
      musicList = DatabaseService.getAllMusic();
    });
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final path = file.path!;

        String title = file.name;
        int lastDotIndex = title.lastIndexOf('.');
        if (lastDotIndex != -1) {
          title = title.substring(0, lastDotIndex);
        }

        final music = Music(
          id: uuid.v4(),
          title: title,
          filePath: path,
          isUrl: false,
          createdAt: DateTime.now(),
        );

        await DatabaseService.addMusic(music);
        _loadMusic();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Audio file added')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking audio: $e')));
    }
  }

  Future<void> _addAudioFromUrl(String url, String title) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${uuid.v4()}.mp3';
      final filePath = '${dir.path}/$fileName';

      final dio = Dio();
      await dio.download(url, filePath);

      final music = Music(
        id: uuid.v4(),
        title: title.isEmpty ? fileName : title,
        filePath: filePath,
        isUrl: true,
        createdAt: DateTime.now(),
      );

      await DatabaseService.addMusic(music);
      _loadMusic();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio downloaded and added')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error downloading audio: $e')));
    }
  }

  Future<void> _playMusic(Music music) async {
    try {
      if (_currentlyPlaying?.id == music.id && _isPlaying) {
        // Currently playing, pause it
        await _audioPlayer.pause();
      } else if (_currentlyPlaying?.id != music.id) {
        // Different track, stop current and play new
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(music.filePath));
        setState(() => _currentlyPlaying = music);
      } else {
        // Same track - either paused or completed
        if (_isCompleted) {
          // Track finished, stop and restart from beginning
          await _audioPlayer.stop();
          await _audioPlayer.play(DeviceFileSource(music.filePath));
          setState(() => _isCompleted = false);
        } else {
          // Track is paused, resume
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  Future<void> _deleteMusic(String id) async {
    await DatabaseService.deleteMusic(id);
    if (_currentlyPlaying?.id == id) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlaying = null;
        _isPlaying = false;
      });
    }
    _loadMusic();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Music deleted')));
    }
  }

  void _showAddUrlDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Audio from URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Audio title',
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/audio.mp3',
                labelText: 'Audio URL',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                _addAudioFromUrl(urlController.text, titleController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: musicList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'No music yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_currentlyPlaying != null) _buildMiniPlayer(),
                Expanded(
                  child: ListView.builder(
                    itemCount: musicList.length,
                    itemBuilder: (context, index) {
                      final music = musicList[index];
                      final isPlaying = _currentlyPlaying?.id == music.id;
                      return _buildMusicCard(music, isPlaying);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddUrlDialog,
            label: const Text('Add URL'),
            icon: const Icon(Icons.link),
            heroTag: 'url',
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: _pickAudioFile,
            label: const Text('Add File'),
            icon: const Icon(Icons.audio_file),
            heroTag: 'file',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentlyPlaying!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDuration(_currentPosition),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause
                      : (_isCompleted ? Icons.replay : Icons.play_arrow),
                  size: 28,
                ),
                onPressed: () => _playMusic(_currentlyPlaying!),
              ),
            ],
          ),
          _buildAudioProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildAudioProgressIndicator() {
    double positionValue = _currentPosition.inMilliseconds.toDouble();
    double totalValue = _totalDuration.inMilliseconds.toDouble();

    if (totalValue <= 0) {
      totalValue = 1;
    }
    
    positionValue = positionValue.clamp(0.0, totalValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(
          value: positionValue,
          max: totalValue,
          onChangeStart: (value) {
            _isSeeking = true;
          },
          onChanged: (value) {
            setState(() {
              _currentPosition = Duration(milliseconds: value.toInt());
            });
          },
          onChangeEnd: (value) {
            _isSeeking = false;
            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );
  }

  Widget _buildMusicCard(Music music, bool isPlaying) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isPlaying ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 56,
            height: 56,
            color: Colors.grey[300],
            child: Icon(
              Icons.music_note,
              color: isPlaying ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ),
        title: Text(
          music.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          music.isUrl ? 'From URL' : 'Local file',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying && _isPlaying
                    ? Icons.pause
                    : (isPlaying &&
                              _isCompleted &&
                              _currentlyPlaying?.id == music.id
                          ? Icons.replay
                          : Icons.play_arrow),
                color: isPlaying ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () => _playMusic(music),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteMusic(music.id),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _completeSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
