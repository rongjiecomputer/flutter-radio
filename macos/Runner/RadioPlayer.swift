import AVFoundation
import FlutterMacOS
import Foundation

final class RadioPlayer {
  private let player = AVPlayer()

  func setURL(_ url: URL) {
    player.replaceCurrentItem(with: AVPlayerItem(url: url))
  }

  func play() {
    player.play()
  }

  func stop() {
    player.pause()
    // Drop the current item to release sockets and decoders.
    player.replaceCurrentItem(with: nil)
  }

  func setVolume(_ level: Float) {
    player.volume = max(0.0, min(1.0, level))
  }
}

enum RadioPlayerChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.example.radio/player",
      binaryMessenger: messenger)
    let player = RadioPlayer()

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "play":
        player.play()
        result(nil)
      case "stop":
        player.stop()
        result(nil)
      case "setUrl":
        guard let urlString = call.arguments as? String,
              let url = URL(string: urlString) else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                              message: "URL must be a string", details: nil))
          return
        }
        player.setURL(url)
        result(nil)
      case "setVolume":
        guard let volume = call.arguments as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                              message: "Volume must be a double", details: nil))
          return
        }
        player.setVolume(Float(volume))
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
