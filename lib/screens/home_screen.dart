import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../services/api_service.dart';
import '../models/now_playing_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();

  List<NowPlayingInfo> _nowPlayingList = [];
  bool _isLoadingStream = false;
  bool _isPlaying = false;
  double _volume = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _fetchNowPlaying();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchNowPlaying();
    });
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
          }
        });
      }
    });
    _audioPlayer.setVolume(_volume);
  }

  Future<void> _fetchNowPlaying() async {
    final list = await _apiService.fetchNowPlaying();
    if (mounted) {
      setState(() {
        _nowPlayingList = list;
      });
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isLoadingStream = true;
      });
      final streamUrl = await _apiService.fetchStreamUrl();
      if (streamUrl != null) {
        try {
          await _audioPlayer.setUrl(streamUrl);
          await _audioPlayer.play();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to play stream: $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get stream URL')),
          );
        }
      }
      setState(() {
        _isLoadingStream = false;
      });
    }
  }

  void _onVolumeChanged(double value) {
    setState(() {
      _volume = value;
    });
    _audioPlayer.setVolume(_volume);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symphony 92.4'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildPlayerCard(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Recently Played',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildNowPlayingList()),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            const Icon(Icons.radio, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Live Stream',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoadingStream
                    ? const CircularProgressIndicator()
                    : IconButton(
                        iconSize: 64,
                        color: Colors.blueAccent,
                        icon: Icon(
                          _isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle_fill,
                        ),
                        onPressed: _togglePlay,
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(value: _volume, onChanged: _onVolumeChanged),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlayingList() {
    if (_nowPlayingList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _nowPlayingList.length,
      itemBuilder: (context, index) {
        final info = _nowPlayingList[index];
        final timeStr = _formatTime(info.startTime);

        return ListTile(
          leading: Text(
            timeStr,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          title: Text(info.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            info.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final textToCopy = '${info.title} by ${info.artist} ($timeStr)';
              await Clipboard.setData(ClipboardData(text: textToCopy));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        );
      },
    );
  }
}
