#pragma once
#include <string>
#include <mfapi.h>
#include <mfidl.h>

class RadioPlayer {
public:
    RadioPlayer();
    ~RadioPlayer();
    
    void SetUrl(const std::wstring& url);
    void Play();
    void Stop();
    void SetVolume(float level);
    
private:
    IMFMediaSession* m_pSession;
    IMFMediaSource* m_pSource;
};
