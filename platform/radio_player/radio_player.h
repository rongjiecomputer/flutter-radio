#pragma once
#include <string>

#ifdef _WIN32
#include <mfapi.h>
#include <mfidl.h>
#else
// Forward-declare to avoid pulling all of <gst/gst.h> into translation units
// that only consume the RadioPlayer interface.
typedef struct _GstElement GstElement;
#endif

namespace flutter_radio {

class RadioPlayer {
 public:
  RadioPlayer();
  ~RadioPlayer();

  RadioPlayer(const RadioPlayer&) = delete;
  RadioPlayer& operator=(const RadioPlayer&) = delete;

  void SetUrl(const std::string& url);
  void Play();
  void Stop();
  void SetVolume(float level);

 private:
#ifdef _WIN32
  void ApplyPendingVolume();
  IMFMediaSession* m_pSession;
  IMFMediaSource* m_pSource;
  float m_pendingVolume;
  bool  m_volumeIsPending;
#else
  GstElement* pipeline_;
  double pending_volume_;
  bool volume_is_pending_;
#endif
};

}  // namespace flutter_radio
