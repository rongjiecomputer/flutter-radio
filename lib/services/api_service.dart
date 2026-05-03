import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/now_playing_info.dart';

class ApiService {
  static const String streamConfigUrl =
      'https://ap-playerservices.streamtheworld.com/api/livestream?station=SYMPHONY924&mount=SYMPHONY924_PREM&transports=http%2Chls&version=1.10';

  static const String nowPlayingUrl =
      'https://np.tritondigital.com/public/nowplaying?mountName=SYMPHONY924AAC&numberToFetch=50&eventType=track';

  Future<String?> fetchStreamUrl() async {
    try {
      final response = await http.get(
        Uri.parse('$streamConfigUrl&request.preventCache=${DateTime.now().millisecondsSinceEpoch}'),
      );
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        
        final mountNode = document.findAllElements('mount').firstOrNull;
        final mountName = mountNode?.innerText ?? 'SYMPHONY924_PREM';

        final serverNodes = document.findAllElements('server');
        for (var server in serverNodes) {
          final ipNode = server.findElements('ip').firstOrNull;
          final portsNode = server.findElements('ports').firstOrNull;
          
          if (ipNode != null && portsNode != null) {
            final hasHttps = portsNode.findElements('port').any(
              (p) => p.getAttribute('type') == 'https' && p.innerText == '443'
            );
            
            if (hasHttps) {
              return 'https://${ipNode.innerText}/$mountName.aac';
            }
          }
        }
        
        // Fallback to first server if no https found
        if (serverNodes.isNotEmpty) {
           final firstServer = serverNodes.first;
           final ipNode = firstServer.findElements('ip').firstOrNull;
           if (ipNode != null) {
             return 'https://${ipNode.innerText}/$mountName.aac';
           }
        }
      }
    } catch (e) {
      print('Error fetching stream URL: $e');
    }
    return null;
  }

  Future<List<NowPlayingInfo>> fetchNowPlaying() async {
    try {
      final response = await http.get(Uri.parse(nowPlayingUrl));
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('nowplaying-info');
        final List<NowPlayingInfo> results = [];

        for (var item in items) {
          final timestampStr = item.getAttribute('timestamp') ?? '0';
          int timestamp = int.tryParse(timestampStr) ?? 0;

          final properties = item.findElements('property');
          final Map<String, String> propMap = {};

          for (var prop in properties) {
            final name = prop.getAttribute('name');
            if (name != null) {
              propMap[name] = prop.innerText.trim();
            }
          }

          if (propMap.containsKey('cue_time_start')) {
            timestamp = int.tryParse(propMap['cue_time_start']!) ?? (timestamp * 1000);
          } else {
            timestamp = timestamp * 1000;
          }

          results.add(NowPlayingInfo.fromXml(propMap, timestamp));
        }

        // The requirement says "descending chronological order"
        // Let's sort them just to be sure.
        results.sort((a, b) => b.startTime.compareTo(a.startTime));
        return results;
      }
    } catch (e) {
      print('Error fetching now playing info: $e');
    }
    return [];
  }
}
