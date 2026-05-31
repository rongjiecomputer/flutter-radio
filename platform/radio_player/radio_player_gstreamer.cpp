#include "radio_player.h"

#include <gst/gst.h>

namespace flutter_radio {

RadioPlayer::RadioPlayer()
    : pipeline_(gst_element_factory_make("playbin", "radio_playbin")),
      pending_volume_(1.0),
      volume_is_pending_(false) {}

RadioPlayer::~RadioPlayer() {
  if (pipeline_) {
    gst_element_set_state(pipeline_, GST_STATE_NULL);
    gst_object_unref(pipeline_);
    pipeline_ = nullptr;
  }
}

void RadioPlayer::SetUrl(const std::string& url) {
  if (!pipeline_) return;
  // playbin requires NULL state before changing uri.
  gst_element_set_state(pipeline_, GST_STATE_NULL);
  g_object_set(pipeline_, "uri", url.c_str(), nullptr);
  if (volume_is_pending_) {
    g_object_set(pipeline_, "volume", pending_volume_, nullptr);
    volume_is_pending_ = false;
  }
}

void RadioPlayer::Play() {
  if (pipeline_) gst_element_set_state(pipeline_, GST_STATE_PLAYING);
}

void RadioPlayer::Stop() {
  if (pipeline_) gst_element_set_state(pipeline_, GST_STATE_NULL);
}

void RadioPlayer::SetVolume(float level) {
  double clamped = level < 0.0f ? 0.0 : (level > 1.0f ? 1.0 : (double)level);
  if (pipeline_) {
    g_object_set(pipeline_, "volume", clamped, nullptr);
  } else {
    pending_volume_ = clamped;
    volume_is_pending_ = true;
  }
}

}  // namespace flutter_radio
