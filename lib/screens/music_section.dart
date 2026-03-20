import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_meadia_app/models/music.dart';
import 'package:flutter_meadia_app/services/database_service.dart';

const uuid = Uuid();

class MusicSection extends StatefulWidget {
  const MusicSection({super.key});

  @override
  State<MusicSection> createState() => _MusicSectionState();
}

class _MusicSectionState extends State<MusicSection> {
  late List<Music> musicList = [];
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Music? _currentlyPlaying;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadMusic();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      // Duration is tracked internally by audioPlayer
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = position;
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
      final XFile? audio = await _picker.pickVideo(source: ImageSource.gallery);
      if (audio != null) {
        final music = Music(
          id: uuid.v4(),
          title: audio.name.replaceAll('.mp4', '').replaceAll('.mov', ''),
          filePath: audio.path,
          isUrl: false,
          createdAt: DateTime.now(),
        );
        await DatabaseService.addMusic(music);
        _loadMusic();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file added')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking audio: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading audio: $e')),
      );
    }
  }

  Future<void> _playMusic(Music music) async {
    try {
      if (_currentlyPlaying?.id == music.id && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_currentlyPlaying?.id != music.id) {
          await _audioPlayer.play(DeviceFileSource(music.filePath));
          setState(() => _currentlyPlaying = music);
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Music deleted')),
      );
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
                _addAudioFromUrl(
                  urlController.text,
                  titleController.text,
                );
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
                  Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.grey[400],
                  ),
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
                if (_currentlyPlaying != null)
                  _buildMiniPlayer(),
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
                  _isPlaying ? Icons.pause : Icons.play_arrow,
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
    return StreamBuilder<Duration>(
      stream: _audioPlayer.onPositionChanged,
      builder: (context, snapshot) {
        Duration position = snapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _audioPlayer.onDurationChanged,
          builder: (context, snapshot) {
            Duration total = snapshot.data ?? Duration.zero;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: position.inMilliseconds.toDouble(),
                  max: total.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
            );
          },
        );
      },
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
                isPlaying && _isPlaying ? Icons.pause : Icons.play_arrow,
                color: isPlaying
                    ? Theme.of(context).colorScheme.primary
                    : null,
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
    _audioPlayer.dispose();
    super.dispose();
  }
}
