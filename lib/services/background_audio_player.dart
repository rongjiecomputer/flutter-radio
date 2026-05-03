import 'package:flutter/widgets.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundAudioPlayer {
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();

  Stream<PlayerState> get playerStateStream => _stateController.stream;

  int _messageIdCounter = 0;
  final Map<int, Completer<dynamic>> _completers = {};

  Future<void> init() async {
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.spawn(_audioIsolateMain, [
      _receivePort.sendPort,
      rootIsolateToken,
    ]);

    final completer = Completer<void>();

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        completer.complete();
      } else if (message is Map<String, dynamic>) {
        if (message['type'] == 'state') {
          final playing = message['playing'] as bool;
          final processingStateIndex = message['processingState'] as int;
          _stateController.add(
            PlayerState(playing, ProcessingState.values[processingStateIndex]),
          );
        } else if (message['type'] == 'response') {
          final id = message['id'] as int;
          final comp = _completers.remove(id);
          if (comp != null) {
            if (message['error'] != null) {
              comp.completeError(Exception(message['error']));
            } else {
              comp.complete(message['result']);
            }
          }
        } else if (message['type'] == 'error') {
          print('BackgroundAudioPlayer error: ${message['payload']}');
        }
      }
    });

    return completer.future;
  }

  Future<dynamic> _sendCommand(String type, [dynamic payload]) async {
    if (_sendPort == null) {
      throw Exception('BackgroundAudioPlayer is not initialized');
    }
    final id = _messageIdCounter++;
    final completer = Completer<dynamic>();
    _completers[id] = completer;
    _sendPort!.send({'id': id, 'type': type, 'payload': payload});
    return completer.future;
  }

  Future<void> play() => _sendCommand('play');
  Future<void> stop() => _sendCommand('stop');
  Future<void> setVolume(double volume) => _sendCommand('setVolume', volume);
  Future<void> setUrl(String url) => _sendCommand('setUrl', url);

  void dispose() {
    if (_sendPort != null) {
      _sendCommand('dispose').catchError((_) {});
    }
    _receivePort.close();
    _stateController.close();
  }
}

void _audioIsolateMain(List<dynamic> args) async {
  SendPort sendPort = args[0];
  RootIsolateToken token = args[1];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final player = AudioPlayer();
  final receivePort = ReceivePort();

  sendPort.send(receivePort.sendPort);

  player.playerStateStream.listen((state) {
    sendPort.send({
      'type': 'state',
      'playing': state.playing,
      'processingState': state.processingState.index,
    });
  });

  receivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final id = message['id'] as int?;
      try {
        dynamic result;
        switch (message['type']) {
          case 'play':
            await player.play();
            break;
          case 'stop':
            await player.stop();
            break;
          case 'setVolume':
            await player.setVolume(message['payload'] as double);
            break;
          case 'setUrl':
            await player.setUrl(message['payload'] as String);
            break;
          case 'dispose':
            await player.dispose();
            receivePort.close();
            break;
        }
        if (id != null) {
          sendPort.send({'type': 'response', 'id': id, 'result': result});
        }
      } catch (e) {
        if (id != null) {
          sendPort.send({'type': 'response', 'id': id, 'error': e.toString()});
        } else {
          sendPort.send({'type': 'error', 'payload': e.toString()});
        }
      }
    }
  });
}
