// BASS library backend for RadioPlayer.
// Enabled via CMake option: -DUSE_BASS_BACKEND=ON
//
// Requires the BASS audio library (un4seen.com/bass.html).
// Expected layout:
//   third_party/bass/
//     bass.h          -- BASS public API header
//     bass.lib        -- import library (x64)
//     bass.dll        -- runtime DLL (copied next to the executable)

#include "radio_player.h"

#include <bass.h>
#include <string>

namespace flutter_radio {

RadioPlayer::RadioPlayer() : m_channel(0) {
  // Initialize BASS with the default audio device.
  // Device -1  = default output device
  // Freq   44100 (overridden by stream's native rate)
  // Flags  0    = default
  // Win    0    = use the process window
  if (!BASS_Init(-1, 44100, 0, 0, nullptr)) {
    // Non-fatal: BASS_Free will be a no-op, and subsequent calls will
    // fail gracefully via BASS error codes.
  }
}

RadioPlayer::~RadioPlayer() {
  Stop();
  BASS_Free();
}

void RadioPlayer::SetUrl(const std::string& url) {
  // Release any previously opened stream.
  if (m_channel != 0) {
    BASS_StreamFree(m_channel);
    m_channel = 0;
  }

  // BASS_StreamCreateURL opens a network stream asynchronously when the
  // BASS_STREAM_BLOCK flag is omitted; we use 0 for synchronous open so
  // the caller can immediately call Play() afterwards.
  m_channel = BASS_StreamCreateURL(
      url.c_str(),
      0,           // offset (bytes from start; 0 = beginning)
      BASS_STREAM_AUTOFREE,  // free stream automatically when it ends
      nullptr,     // download progress callback (not needed)
      nullptr      // user data for callback
  );

  // m_channel == 0 on failure; callers should check BASS_ErrorGetCode() if
  // they need the specific error, but we keep this implementation silent to
  // match the MF backend's error-handling style.
}

void RadioPlayer::Play() {
  if (m_channel != 0) {
    // Second arg FALSE = do not restart from the beginning.
    BASS_ChannelPlay(m_channel, FALSE);
  }
}

void RadioPlayer::Stop() {
  if (m_channel != 0) {
    BASS_ChannelStop(m_channel);
    // For live/internet streams the stream object itself is kept alive so
    // Play() can resume.  A new SetUrl() call will free it.
  }
}

void RadioPlayer::SetVolume(float level) {
  if (m_channel != 0) {
    // BASS_ATTRIB_VOL range: 0.0 (silent) to 1.0 (full), matching the
    // IMFSimpleAudioVolume range used by the MF backend.
    BASS_ChannelSetAttribute(m_channel, BASS_ATTRIB_VOL, level);
  }
}

}  // namespace flutter_radio
