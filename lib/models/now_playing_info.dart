class NowPlayingInfo {
  final String title;
  final String artist;
  final String trackAlbumPublisher;
  final DateTime startTime;

  NowPlayingInfo({
    required this.title,
    required this.artist,
    required this.trackAlbumPublisher,
    required this.startTime,
  });

  factory NowPlayingInfo.fromXml(Map<String, String> properties, int timestamp) {
    return NowPlayingInfo(
      title: properties['cue_title'] ?? 'Unknown Title',
      artist: properties['track_artist_name'] ?? 'Unknown Artist',
      trackAlbumPublisher: properties['track_album_publisher'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}
