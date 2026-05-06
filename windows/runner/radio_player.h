#pragma once
#include <mfapi.h>
#include <mfidl.h>
#include <string>


namespace flutter_radio {

class RadioPlayer {
 public:
  RadioPlayer();
  ~RadioPlayer();

  void SetUrl(const std::string& url);
  void Play();
  void Stop();
  void SetVolume(float level);

 private:
  IMFMediaSession* m_pSession;
  IMFMediaSource* m_pSource;
};

}  // namespace flutter_radio
