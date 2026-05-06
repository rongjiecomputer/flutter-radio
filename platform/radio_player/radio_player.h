#pragma once
#include <string>

// ---------------------------------------------------------------------------
// Backend selection
// The CMake build system sets USE_BASS_BACKEND when configured with
//   -DUSE_BASS_BACKEND=ON
// Otherwise the default Windows Media Foundation backend is used.
// ---------------------------------------------------------------------------

#if defined(USE_BASS_BACKEND) || !defined(_WIN32)
// Forward-declare the BASS channel handle type so we can store it without
// pulling the full bass.h into every translation unit that includes this header.
using HSTREAM = unsigned long;
#ifndef USE_BASS_BACKEND
#define USE_BASS_BACKEND
#endif
#else
#include <mfapi.h>
#include <mfidl.h>
#endif

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
#ifdef USE_BASS_BACKEND
  HSTREAM m_channel;
#else
  IMFMediaSession* m_pSession;
  IMFMediaSource* m_pSource;
#endif
};

}  // namespace flutter_radio
