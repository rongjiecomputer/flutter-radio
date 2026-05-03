class NowPlayingInfo {
  final String title;
  final String artist;
  final DateTime startTime;

  NowPlayingInfo({
    required this.title,
    required this.artist,
    required this.startTime,
  });

  factory NowPlayingInfo.fromXml(Map<String, String> properties, int timestamp) {
    return NowPlayingInfo(
      title: properties['cue_title'] ?? 'Unknown Title',
      artist: properties['track_artist_name'] ?? 'Unknown Artist',
      startTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}
