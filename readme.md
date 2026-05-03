# Requirement

Write a simple Flutter application that can play a radio stream.

## Feature 1: Radio Stream Player

API url: https://ap-playerservices.streamtheworld.com/api/livestream?station=SYMPHONY924&mount=SYMPHONY924_PREM&transports=http%2Chls&version=1.10&request.preventCache=1770529894247

Example response:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<live_stream_config xmlns="http://provisioning.streamtheworld.com/player/livestream-1.10" version="1.10">
<mountpoints>
<mountpoint>
<status>
<status-code>200</status-code>
<status-message>OK</status-message>
</status>
<transports>
<transport>http</transport>
</transports>
<metadata>
<shoutcast-v1 enabled="true" mountSuffix="_SC" />
<shoutcast-v2 enabled="false" mountSuffix="_SC" />
<sse-sideband enabled="true" streamSuffix="_SC" metadataSuffix="_SBM" />
</metadata>
<servers>
<server sid="22903">
<ip>22903.live.streamtheworld.com</ip>
<ports>…</ports>
</server>
<server sid="28383">
<ip>28383.live.streamtheworld.com</ip>
<ports>…</ports>
</server>
<server sid="28443">
<ip>28443.live.streamtheworld.com</ip>
<ports>
<port type="https">443</port>
</ports>
</server>
<server sid="28373">…</server>
<server sid="22893">…</server>
<server sid="28313">…</server>
<server sid="22403">…</server>
<server sid="28393">…</server>
<server sid="28333">…</server>
<server sid="28323">…</server>
<server sid="28453">…</server>
<server sid="22393">…</server>
<server sid="14033">…</server>
<server sid="19183">…</server>
<server sid="23253">
<ip>23253.live.streamtheworld.com</ip>
<ports>
<port type="https">443</port>
</ports>
</server>
</servers>
<metrics>
<listener-tracking url="" wcm-station-id="31920" />
<tag name="uuid" />
</metrics>
<mount>SYMPHONY924_PREM</mount>
<format>FLV</format>
<bitrate>64000</bitrate>
<media-format container="flv" cuepoints="stwcue" trackScheme="audio">
<audio index="0" samplerate="44100" codec="heaacv1" bitrate="64000" channels="2" />
</media-format>
<authentication>0</authentication>
<timeout>0</timeout>
<send-page-url>1</send-page-url>
</mountpoint>
</mountpoints>
</live_stream_config>
```

Take one of the servers and use it to get the stream url.
Example: https://28453.live.streamtheworld.com/SYMPHONY924_PREM.aac

## Feature 2: Audio Controls

- Play/Stop button
- Volume slider

## Feature 3: Music Information List

- Add a scrollable list of music information (in descending chronological order)
- Each item has a button to copy the information to clipboard

API: 
https://np.tritondigital.com/public/nowplaying?mountName=SYMPHONY924AAC&numberToFetch=50&eventType=track
Example response:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<nowplaying-info-list>
<nowplaying-info mountName="SYMPHONY924AAC" timestamp="1770529658" type="track">
<property name="cue_time_duration">
<![CDATA[328807]]>
</property>
<property name="cue_time_start">
<![CDATA[1770529658191]]>
</property>
<property name="cue_title">
<![CDATA[Rusalka - Song to the Moon]]>
</property>
<property name="track_album_publisher">
<![CDATA[DVORAK, ANTONIN]]>
</property>
<property name="track_artist_name">
<![CDATA[Joshua Bell, Orchestra of St. Luke's, Michael Stern]]>
</property>
</nowplaying-info>
</nowplaying-info-list>
```

## Coding Requirement
- Separate the logic and UI code cleanly.
- Use Material Design for UI.
