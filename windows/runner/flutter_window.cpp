#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Initialize RadioPlayer
  radio_player_ = std::make_unique<RadioPlayer>();

  // Set up MethodChannel
  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), "com.example.radio/player",
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler(
      [this](const flutter::MethodCall<>& call,
             std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "play") {
          radio_player_->Play();
          result->Success();
        } else if (call.method_name() == "stop") {
          radio_player_->Stop();
          result->Success();
        } else if (call.method_name() == "setVolume") {
          if (auto* volume = std::get_if<double>(call.arguments())) {
            radio_player_->SetVolume(static_cast<float>(*volume));
            result->Success();
          } else {
            result->Error("INVALID_ARGUMENT", "Volume must be a double");
          }
        } else if (call.method_name() == "setUrl") {
          if (auto* url = std::get_if<std::string>(call.arguments())) {
            int size_needed = MultiByteToWideChar(CP_UTF8, 0, url->c_str(), (int)url->size(), NULL, 0);
            std::wstring wurl(size_needed, 0);
            MultiByteToWideChar(CP_UTF8, 0, url->c_str(), (int)url->size(), &wurl[0], size_needed);
            radio_player_->SetUrl(wurl);
            result->Success();
          } else {
            result->Error("INVALID_ARGUMENT", "URL must be a string");
          }
        } else {
          result->NotImplemented();
        }
      });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
