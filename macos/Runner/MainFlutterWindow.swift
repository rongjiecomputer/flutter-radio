import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    var frame = self.frame
    frame.size = NSSize(width: 800, height: 800)
    self.setFrame(frame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    RadioPlayerChannel.register(
      with: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
