#include "radio_player.h"
#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <shlwapi.h>

#pragma comment(lib, "mf.lib")
#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "shlwapi.lib")

template <class T> void SafeRelease(T **ppT) {
    if (*ppT) { (*ppT)->Release(); *ppT = nullptr; }
}

RadioPlayer::RadioPlayer() : m_pSession(nullptr), m_pSource(nullptr) {
    MFStartup(MF_VERSION);
}

RadioPlayer::~RadioPlayer() {
    Stop();
    SafeRelease(&m_pSource);
    SafeRelease(&m_pSession);
    MFShutdown();
}

void RadioPlayer::SetUrl(const std::wstring& url) {
    SafeRelease(&m_pSource);
    SafeRelease(&m_pSession);

    MFCreateMediaSession(nullptr, &m_pSession);

    IMFSourceResolver* pSourceResolver = nullptr;
    MFCreateSourceResolver(&pSourceResolver);

    MF_OBJECT_TYPE ObjectType = MF_OBJECT_INVALID;
    IUnknown* pSource = nullptr;

    pSourceResolver->CreateObjectFromURL(
        url.c_str(), 
        MF_RESOLUTION_MEDIASOURCE, 
        nullptr, 
        &ObjectType, 
        &pSource
    );

    if (pSource) {
        pSource->QueryInterface(IID_PPV_ARGS(&m_pSource));
        pSource->Release();
    }
    
    SafeRelease(&pSourceResolver);

    if (m_pSource && m_pSession) {
        // Create Topology
        IMFTopology* pTopology = nullptr;
        MFCreateTopology(&pTopology);

        IMFPresentationDescriptor* pPD = nullptr;
        m_pSource->CreatePresentationDescriptor(&pPD);

        DWORD cStreams = 0;
        pPD->GetStreamDescriptorCount(&cStreams);

        for (DWORD i = 0; i < cStreams; i++) {
            BOOL fSelected = FALSE;
            IMFStreamDescriptor* pSD = nullptr;
            pPD->GetStreamDescriptorByIndex(i, &fSelected, &pSD);

            if (fSelected) {
                IMFTopologyNode* pSourceNode = nullptr;
                MFCreateTopologyNode(MF_TOPOLOGY_SOURCESTREAM_NODE, &pSourceNode);
                pSourceNode->SetUnknown(MF_TOPONODE_SOURCE, m_pSource);
                pSourceNode->SetUnknown(MF_TOPONODE_PRESENTATION_DESCRIPTOR, pPD);
                pSourceNode->SetUnknown(MF_TOPONODE_STREAM_DESCRIPTOR, pSD);

                IMFTopologyNode* pOutputNode = nullptr;
                MFCreateTopologyNode(MF_TOPOLOGY_OUTPUT_NODE, &pOutputNode);
                
                IMFActivate* pRendererActivate = nullptr;
                MFCreateAudioRendererActivate(&pRendererActivate);
                pOutputNode->SetObject(pRendererActivate);
                
                pTopology->AddNode(pSourceNode);
                pTopology->AddNode(pOutputNode);
                pSourceNode->ConnectOutput(0, pOutputNode, 0);

                SafeRelease(&pRendererActivate);
                SafeRelease(&pOutputNode);
                SafeRelease(&pSourceNode);
            }
            SafeRelease(&pSD);
        }

        m_pSession->SetTopology(0, pTopology);
        
        SafeRelease(&pPD);
        SafeRelease(&pTopology);
    }
}

void RadioPlayer::Play() {
    if (m_pSession) {
        PROPVARIANT varStart;
        PropVariantInit(&varStart);
        m_pSession->Start(&GUID_NULL, &varStart);
        PropVariantClear(&varStart);
    }
}

void RadioPlayer::Stop() {
    if (m_pSession) {
        m_pSession->Stop();
        m_pSession->Close();
    }
}

void RadioPlayer::SetVolume(float level) {
    if (m_pSession) {
        IMFSimpleAudioVolume* pVolume = nullptr;
        MFGetService(m_pSession, MR_POLICY_VOLUME_SERVICE, IID_PPV_ARGS(&pVolume));
        if (pVolume) {
            pVolume->SetMasterVolume(level);
            pVolume->Release();
        }
    }
}
